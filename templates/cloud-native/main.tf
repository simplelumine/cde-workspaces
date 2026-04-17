terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
    }
  }
}

provider "coder" {
}

variable "use_kubeconfig" {
  type        = bool
  description = <<-EOF
  Use host kubeconfig? (true/false)

  Set this to false if the Coder host is itself running as a Pod on the same
  Kubernetes cluster as you are deploying workspaces to.

  Set this to true if the Coder host is running outside the Kubernetes cluster
  for workspaces.  A valid "~/.kube/config" must be present on the Coder host.
  EOF
  default     = false
}

module "workspace-parameters" {
  source = "./modules/workspace-parameters"
}

module "zone-parameter" {
  source = "./modules/zone-parameter"
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

provider "helm" {
  kubernetes {
    config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
  }
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
  # Provide a dedicated namespace per workspace
  # e.g., "coder-alice-dev"
  workspace_namespace = lower("coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}")
}

resource "kubernetes_namespace_v1" "workspace" {
  metadata {
    name = local.workspace_namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace_owner.me.id
      "com.coder.user.username"    = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }
}

resource "coder_agent" "main" {
  os             = "linux"
  arch           = "amd64"
  startup_script = <<-EOT
    set -e
    mkdir -p /home/coder/projects
    # Ensure .bashrc exists and expose user bin for pip installations
    touch ~/.bashrc
    if ! grep -q "export PATH=\$PATH:~/.local/bin" ~/.bashrc; then
      echo "export PATH=\$PATH:~/.local/bin" >> ~/.bashrc
    fi

    # Install the latest code-server.
    # Append "--version x.x.x" to install a specific version of code-server.
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server

    # Start code-server in the background.
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &


  EOT

  # GITHUB_TOKEN is NOT injected here as a static env var because OAuth tokens
  # expire after ~8 hours. Instead, the github-tools module configures a dynamic
  # wrapper that fetches a fresh token on every `gh` invocation via:
  #   coder external-auth access-token primary-github
  env = {}

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    # get load avg scaled by number of cores
    script   = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }
}

module "antigravity" {
  source   = "registry.coder.com/coder/antigravity/coder"
  version  = "1.0.0"
  agent_id = coder_agent.main.id  
  folder = "/home/coder/projects"
}



data "coder_parameter" "workspace_mode" {
  name         = "workspace_mode"
  display_name = "Workspace Mode"
  description  = "Controls security isolation level and which credentials are injected into the workspace."
  default      = "standard"
  type         = "string"
  mutable      = true
  
  option {
    value = "standard"
    name  = "🌐 Standard — Use credentials as provided (no vcluster, no heavy tools)"
  }
  option {
    value = "sandbox"
    name  = "🔒 Sandbox — Isolated vcluster (credentials forcefully ignored, pure testing)"
  }
  option {
    value = "privileged"
    name  = "🔥 Privileged — Full production access & heavy SRE toolchain (Flux, CNPG)"
  }
}

data "coder_parameter" "dev_toolchain" {
  name         = "dev_toolchain"
  display_name = "Dev Toolchain 🛠️"
  description  = "Select which language environments to install dynamically at startup."
  type         = "list(string)"
  form_type    = "multi-select"
  default      = jsonencode(["golang"])
  mutable      = true
  
  option {
    value = "golang"
    name  = "🐹 Go"
  }
  option {
    value = "python"
    name  = "🐍 Python 3 & pip"
  }
  option {
    value = "nodejs"
    name  = "🟢 Node.js & npm / yarn"
  }
}

locals {
  mode        = data.coder_parameter.workspace_mode.value
  is_sandbox  = local.mode == "sandbox"
  is_priv     = local.mode == "privileged"

  # Credential interception layer:
  # - sandbox:    ALL external credentials are forcefully stripped; safe vcluster kubeconfig is used.
  # - standard:   Credentials are passed through as-is (no vcluster).
  # - privileged: Credentials are passed through + heavy SRE tools are installed.
  safe_kubeconfig = local.is_sandbox ? module.vcluster.kubeconfig : data.coder_parameter.kubeconfig.value
  safe_ssh_key    = local.is_sandbox ? "" : data.coder_parameter.ssh_private_key.value
  safe_sops_key   = local.is_sandbox ? "" : data.coder_parameter.sops_age_key.value
}

module "vcluster" {
  source                = "./modules/vcluster"
  namespace             = kubernetes_namespace_v1.workspace.metadata.0.name
  workspace_name        = data.coder_workspace.me.name
  workspace_start_count = data.coder_workspace.me.start_count
  zone                  = module.zone-parameter.value
  enabled               = local.is_sandbox
}

data "coder_parameter" "kubeconfig" {
  name         = "kubeconfig"
  display_name = "Kubeconfig"
  description  = "(Optional) Paste your kubeconfig YAML content. Used in Default and Ops modes; ignored in Dev mode."
  default      = ""
  type         = "string"
  icon         = "/icon/k8s.png"
  mutable      = true
  form_type    = "textarea"
}

module "kubernetes-tools" {
  source     = "./modules/kubernetes-tools"
  agent_id   = coder_agent.main.id
  kubeconfig = local.safe_kubeconfig
}

module "dev-tools" {
  source     = "./modules/dev-tools"
  agent_id   = coder_agent.main.id
  tools_list = jsondecode(data.coder_parameter.dev_toolchain.value)
}

module "cnpg-tools" {
  count    = local.is_priv ? 1 : 0
  source   = "./modules/cnpg-tools"
  agent_id = coder_agent.main.id
}

module "terraform-tools" {
  source   = "./modules/terraform-tools"
  agent_id = coder_agent.main.id
}

module "flux-tools" {
  count    = local.is_priv ? 1 : 0
  source   = "./modules/flux-tools"
  agent_id = coder_agent.main.id
}


data "coder_parameter" "ssh_private_key" {
  name         = "ssh_private_key"
  display_name = "SSH Private Key"
  description  = "(Optional) Paste your id_ed25519 private key content for git/ansible via SSH"
  default      = ""
  type         = "string"
  form_type    = "textarea"
  mutable      = true
  icon         = ""
}

module "ansible-tools" {
  source          = "./modules/ansible-tools"
  agent_id        = coder_agent.main.id
  ssh_private_key = local.safe_ssh_key
}

data "coder_parameter" "sops_age_key" {
  name         = "sops_age_key"
  display_name = "SOPS Age Key"
  description  = "(Optional) Paste your SOPS Age private key content"
  default      = ""
  type         = "string"
  form_type    = "textarea"
  mutable      = true
  icon         = "/icon/k8s.png"
}

module "sops-tools" {
  source       = "./modules/sops-tools"
  agent_id     = coder_agent.main.id
  sops_age_key = local.safe_sops_key
}

module "github-tools" {
  source           = "./modules/github-tools"
  agent_id         = coder_agent.main.id
  external_auth_id = data.coder_external_auth.github.id
}

data "coder_external_auth" "github" {
  id = "primary-github"
}

module "git-config" {
  source   = "registry.coder.com/coder/git-config/coder"
  version  = "1.0.33"
  agent_id = coder_agent.main.id
}

module "git-signing" {
  source   = "./modules/git-signing"
  agent_id = coder_agent.main.id
}

module "git-clone" {
  source   = "./modules/git-clone"
  agent_id = coder_agent.main.id
  base_dir = "/home/coder/projects"
}

module "github-upload-public-key" {
  source   = "registry.coder.com/coder/github-upload-public-key/coder"
  version  = "1.0.32"
  agent_id = coder_agent.main.id
  external_auth_id = data.coder_external_auth.github.id
}

module "gemini" {
  count    = data.coder_workspace.me.start_count
  source   = "./modules/gemini"
  agent_id = coder_agent.main.id
  folder   = "/home/coder/projects"
}

# code-server
resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  icon         = "/icon/code.svg"
  url          = "http://localhost:13337?folder=/home/coder/projects"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}

resource "kubernetes_persistent_volume_claim_v1" "home" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-home"
    namespace = kubernetes_namespace_v1.workspace.metadata.0.name
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      //Coder-specific labels.
      "com.coder.resource"       = "true"
      "com.coder.workspace.id"   = data.coder_workspace.me.id
      "com.coder.workspace.name" = data.coder_workspace.me.name
      "com.coder.user.id"        = data.coder_workspace_owner.me.id
      "com.coder.user.username"  = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = {
        storage = "${module.workspace-parameters.home_disk_size}Gi"
      }
    }
  }
}

resource "kubernetes_deployment_v1" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim_v1.home,
  ]
  wait_for_rollout = false
  metadata {
    name      = "coder-${data.coder_workspace.me.id}"
    namespace = kubernetes_namespace_v1.workspace.metadata.0.name
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace_owner.me.id
      "com.coder.user.username"    = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "coder-workspace"
        "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
        "app.kubernetes.io/part-of"  = "coder"
        "com.coder.resource"         = "true"
        "com.coder.workspace.id"     = data.coder_workspace.me.id
        "com.coder.workspace.name"   = data.coder_workspace.me.name
        "com.coder.user.id"          = data.coder_workspace_owner.me.id
        "com.coder.user.username"    = data.coder_workspace_owner.me.name
      }
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = "coder-workspace"
          "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
          "app.kubernetes.io/part-of"  = "coder"
          "com.coder.resource"         = "true"
          "com.coder.workspace.id"     = data.coder_workspace.me.id
          "com.coder.workspace.name"   = data.coder_workspace.me.name
          "com.coder.user.id"          = data.coder_workspace_owner.me.id
          "com.coder.user.username"    = data.coder_workspace_owner.me.name
        }
      }
      spec {
        hostname = "sre-${data.coder_workspace.me.name}"

        security_context {
          run_as_user     = 1000
          fs_group        = 1000
          run_as_non_root = true
        }

        container {
          name              = "dev"
          image             = "codercom/enterprise-node:ubuntu"
          image_pull_policy = "Always"
          command = ["sh", "-c", <<-EOT
            # Inject the active kubeconfig (vcluster or external depending on mode) early
            if [ -n "$SAFE_KUBECONFIG_B64" ]; then
              mkdir -p ~/.kube
              echo "$SAFE_KUBECONFIG_B64" | base64 -d > ~/.kube/config
              chmod 600 ~/.kube/config
              echo "✅ Active kubeconfig injected at ~/.kube/config"
            fi
            ${coder_agent.main.init_script}
          EOT
          ]
          security_context {
            run_as_user = "1000"
          }
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }
          # Inject the intercepted/safe kubeconfig
          env {
            name  = "SAFE_KUBECONFIG_B64"
            value = base64encode(local.safe_kubeconfig)
          }
          resources {
            requests = {
              "cpu"    = module.workspace-parameters.request_cpu
              "memory" = module.workspace-parameters.request_memory
            }
            limits = {
              "memory" = module.workspace-parameters.limit_memory
            }
          }
          volume_mount {
            mount_path = "/home/coder"
            name       = "home"
            read_only  = false
          }
        }

        volume {
          name = "home"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.home.metadata.0.name
            read_only  = false
          }
        }

        affinity {
          // This affinity attempts to spread out all workspace pods evenly across
          // nodes.
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["coder-workspace"]
                  }
                }
              }
            }
          }

          // Pin the workspace to nodes in the selected zone
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "topology.kubernetes.io/zone"
                  operator = "In"
                  values   = [module.zone-parameter.value]
                }
              }
            }
          }
        }
      }
    }
  }
}
