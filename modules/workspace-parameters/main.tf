terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

data "coder_parameter" "workspace_tier" {
  name         = "workspace_tier"
  display_name = "Workspace Resource Tier"
  description  = "Select the performance tier for your workspace. This determines which node pool your workspace runs on."
  default      = "pro"
  icon         = "/icon/k8s.svg"
  mutable      = true

  option {
    name        = "Lite"
    description = "Basic development tasks, documentation, and light coding."
    value       = "lite"
  }
  option {
    name        = "Flash"
    description = "General-purpose development with moderate resource needs."
    value       = "flash"
  }
  option {
    name        = "Pro"
    description = "Heavy compilation, large projects, and resource-intensive workloads."
    value       = "pro"
  }
}

data "coder_parameter" "storage_tier" {
  name         = "storage_tier"
  display_name = "Workspace Storage Tier"
  description  = "Select the persistent storage volume size for /home/coder"
  default      = "lite"
  icon         = "/emojis/1f4be.png"
  mutable      = false

  option {
    name        = "Lite (10 GB)"
    description = "Lightweight persistent storage for everyday development."
    value       = "lite"
  }
  option {
    name        = "Flash (30 GB)"
    description = "Balanced storage for projects with heavy dependencies and builds."
    value       = "flash"
  }
  option {
    name        = "Pro (50 GB)"
    description = "Maximum storage for monorepos, large datasets, and intensive workloads."
    value       = "pro"
  }
}

locals {
  request_cpu_map = {
    "lite"  = "125m"
    "flash" = "256m"
    "pro"   = "375m"
  }
  request_memory_map = {
    "lite"  = "256Mi"
    "flash" = "512Mi"
    "pro"   = "768Mi"
  }
  limit_memory_map = {
    "lite"  = "1.5Gi"
    "flash" = "3Gi"
    "pro"   = "5Gi"
  }
  disk_size_map = {
    "lite"  = "10"
    "flash" = "20"
    "pro"   = "30"
  }
}

output "tier" {
  description = "The selected workspace tier for node affinity scheduling"
  value       = data.coder_parameter.workspace_tier.value
}

output "request_cpu" {
  description = "The CPU request based on workspace tier"
  value       = local.request_cpu_map[data.coder_parameter.workspace_tier.value]
}

output "request_memory" {
  description = "The memory request based on workspace tier"
  value       = local.request_memory_map[data.coder_parameter.workspace_tier.value]
}

output "limit_memory" {
  description = "The memory limit based on workspace tier"
  value       = local.limit_memory_map[data.coder_parameter.workspace_tier.value]
}

output "home_disk_size" {
  description = "The resolved disk size based on storage tier"
  value       = local.disk_size_map[data.coder_parameter.storage_tier.value]
}
