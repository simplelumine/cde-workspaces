terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to deploy vcluster into"
}

variable "workspace_name" {
  type        = string
  description = "The Coder workspace name (used for naming the vcluster)"
}

variable "workspace_start_count" {
  type        = number
  description = "The start count of the workspace (0 when stopped, 1 when running)"
}

variable "zone" {
  type        = string
  description = "The topology zone (e.g. sfo, lax) to pin vcluster components to"
}


# ============================================================================
# Parameter Toggle
# ============================================================================

data "coder_parameter" "enable_vcluster" {
  name         = "enable_vcluster"
  display_name = "Enable Virtual Cluster"
  description  = "Launch a dedicated sandboxed Kubernetes cluster alongside your workspace for testing"
  type         = "bool"
  default      = "false"
  icon         = "/icon/k8s.png"
  mutable      = true
  order        = 10
}

locals {
  enabled       = data.coder_parameter.enable_vcluster.value == "true"
  vcluster_name = "vc-${var.workspace_name}"
}

# ============================================================================
# Deploy vcluster via Helm (only when enabled and workspace is running)
# ============================================================================

resource "helm_release" "vcluster" {
  count = local.enabled ? var.workspace_start_count : 0

  name       = local.vcluster_name
  repository = "https://charts.loft.sh"
  chart      = "vcluster"
  namespace  = var.namespace

  # Explicitly set resource requests to prevent future chart default changes from inflating costs.
  set {
    name  = "controlPlane.statefulSet.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "controlPlane.statefulSet.resources.requests.memory"
    value = "128Mi"
  }

  # Add TLS SAN for in-cluster service DNS access
  set {
    name  = "controlPlane.proxy.extraSANs[0]"
    value = "${local.vcluster_name}.${var.namespace}.svc.cluster.local"
  }

  # Enable syncing of Host StorageClasses so users can create PVCs inside vcluster
  set {
    name  = "sync.fromHost.storageClasses.enabled"
    value = "true"
  }

  # Always enable persistence for vcluster control plane data
  set {
    name  = "controlPlane.statefulSet.persistence.volumeClaim.enabled"
    value = "true"
  }

  # Zone-based Node Affinity: Pin vcluster control plane to the same zone as the workspace.
  # Uses direct nodeAffinity on topology.kubernetes.io/zone instead of podAffinity,
  # which is simpler and more reliable for public-IP mesh clusters.
  set {
    name  = "controlPlane.statefulSet.scheduling.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
    value = "topology.kubernetes.io/zone"
  }
  set {
    name  = "controlPlane.statefulSet.scheduling.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
    value = "In"
  }
  set {
    name  = "controlPlane.statefulSet.scheduling.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
    value = var.zone
  }

  # Zone-based Node Affinity for CoreDNS: same logic as the control plane above.
  # CoreDNS runs as a separate Deployment; without this, it can land on a remote node,
  # causing high DNS latency over the public-IP mesh between nodes.
  set {
    name  = "controlPlane.coredns.deployment.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
    value = "topology.kubernetes.io/zone"
  }
  set {
    name  = "controlPlane.coredns.deployment.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
    value = "In"
  }
  set {
    name  = "controlPlane.coredns.deployment.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
    value = var.zone
  }

  # Data persistence strategy:
  # We do NOT set retentionPolicy=Delete and do NOT use existingClaim.
  # Instead, we rely on Kubernetes' native StatefulSet behavior:
  #   - StatefulSet PVCs are NOT deleted when the StatefulSet is removed (helm uninstall).
  #   - When the workspace restarts (helm install), the new StatefulSet automatically
  #     finds and reattaches to the existing PVC with the matching name.
  #   - When the workspace is fully DELETED, the parent Namespace is destroyed,
  #     which cascades and cleans up all PVCs — no zombie resources.

  wait    = true
  timeout = 300
}

# ============================================================================
# Read the kubeconfig secret generated by vcluster
# ============================================================================

data "kubernetes_secret_v1" "vcluster_kubeconfig" {
  count = local.enabled ? var.workspace_start_count : 0

  metadata {
    name      = "vc-${local.vcluster_name}"
    namespace = var.namespace
  }

  depends_on = [helm_release.vcluster]
}

# ============================================================================
# Outputs
# ============================================================================

locals {
  # The in-cluster DNS address that workspace pods use to reach the vcluster API server
  vcluster_service_url = "https://${local.vcluster_name}.${var.namespace}.svc.cluster.local:443"

  # Replace localhost:8443 in the raw kubeconfig with the real in-cluster service URL
  raw_kubeconfig = local.enabled && var.workspace_start_count > 0 ? data.kubernetes_secret_v1.vcluster_kubeconfig[0].data["config"] : ""
  kubeconfig     = replace(local.raw_kubeconfig, "https://localhost:8443", local.vcluster_service_url)
}

output "enabled" {
  description = "Whether vcluster is enabled"
  value       = local.enabled
}

output "kubeconfig" {
  description = "The kubeconfig YAML for the virtual cluster (empty if disabled)"
  value       = local.kubeconfig
  sensitive   = true
}

output "name" {
  description = "The name of the vcluster helm release"
  value       = local.vcluster_name
}
