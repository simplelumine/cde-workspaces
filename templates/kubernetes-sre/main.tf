terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
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

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to create workspaces in (must exist prior to creating workspaces). If the Coder host is itself running as a Pod on the same Kubernetes cluster as you are deploying workspaces to, set this to the same namespace."
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 Cores"
    value = "2"
  }
  option {
    name  = "4 Cores"
    value = "4"
  }
  option {
    name  = "6 Cores"
    value = "6"
  }
  option {
    name  = "8 Cores"
    value = "8"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "The amount of memory in GB"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 GB"
    value = "2"
  }
  option {
    name  = "4 GB"
    value = "4"
  }
  option {
    name  = "6 GB"
    value = "6"
  }
  option {
    name  = "8 GB"
    value = "8"
  }
}

data "coder_parameter" "home_disk_size" {
  name         = "home_disk_size"
  display_name = "Home disk size"
  description  = "The size of the home disk in GB"
  default      = "10"
  type         = "number"
  icon         = "/emojis/1f4be.png"
  mutable      = false
  validation {
    min = 1
    max = 99999
  }
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  os             = "linux"
  arch           = "amd64"
  startup_script = <<-EOT
    set -e
    # Ensure .bashrc exists
    touch ~/.bashrc

    # Install the latest code-server.
    # Append "--version x.x.x" to install a specific version of code-server.
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server

    # Start code-server in the background.
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

    # Install Kubernetes Tools (kubectl, helm, k9s)
    if [ "${data.coder_parameter.install_k8s_tools.value}" = "true" ]; then
      echo "Installing Kubernetes Tools..."

      # Install kubectl
      if ! command -v kubectl >/dev/null 2>&1; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
      fi

      # Install helm
      if ! command -v helm >/dev/null 2>&1; then
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      fi

      # Install k9s
      if ! command -v k9s >/dev/null 2>&1; then
        K9S_VERSION=$(curl -Ls -o /dev/null -w %%{url_effective} https://github.com/derailed/k9s/releases/latest | rev | cut -d/ -f1 | rev | sed 's/^v//')
        curl -fsSL "https://github.com/derailed/k9s/releases/download/v$${K9S_VERSION}/k9s_Linux_amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/k9s /usr/local/bin/
      fi
    fi

    # Install Terraform
    if [ "${data.coder_parameter.install_terraform_tools.value}" = "true" ]; then
      if ! command -v terraform >/dev/null 2>&1; then
        echo "Installing Terraform..."
        TERRAFORM_VERSION=$(curl -Ls -o /dev/null -w %%{url_effective} https://github.com/hashicorp/terraform/releases/latest | rev | cut -d/ -f1 | rev | sed 's/^v//')
        curl -fsSL -o /tmp/terraform.zip "https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip"
        sudo unzip -q /tmp/terraform.zip -d /usr/local/bin/
        rm /tmp/terraform.zip
      fi
    fi

    # Install Flux CLI
    if [ "${data.coder_parameter.install_flux_tools.value}" = "true" ]; then
      echo "Installing Flux CLI..."
      if ! command -v flux >/dev/null 2>&1; then
        curl -s https://fluxcd.io/install.sh | sudo bash
      fi
    fi

    # Install SOPS and Age
    if [ "${data.coder_parameter.install_sops_age_tools.value}" = "true" ]; then
      echo "Installing SOPS and Age..."
      if ! command -v sops >/dev/null 2>&1; then
        SOPS_VERSION=$(curl -Ls -o /dev/null -w %%{url_effective} https://github.com/getsops/sops/releases/latest | rev | cut -d/ -f1 | rev | sed 's/^v//')
        curl -fsSL -o /tmp/sops "https://github.com/getsops/sops/releases/download/v$${SOPS_VERSION}/sops-v$${SOPS_VERSION}.linux.amd64"
        chmod +x /tmp/sops
        sudo mv /tmp/sops /usr/local/bin/
      fi

      if ! command -v age >/dev/null 2>&1; then
        AGE_VERSION=$(curl -Ls -o /dev/null -w %%{url_effective} https://github.com/FiloSottile/age/releases/latest | rev | cut -d/ -f1 | rev | sed 's/^v//')
        curl -fsSL "https://github.com/FiloSottile/age/releases/download/v$${AGE_VERSION}/age-v$${AGE_VERSION}-linux-amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/age/age /usr/local/bin/
        sudo mv /tmp/age/age-keygen /usr/local/bin/
      fi
    fi

    # Install Ansible Core
    if [ "${data.coder_parameter.install_ansible_tools.value}" = "true" ]; then
      if ! command -v ansible >/dev/null 2>&1; then
        echo "Installing Ansible Core..."
        sudo -u coder pip3 install --user ansible-core
        sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y sshpass
      fi
    fi

    # Inject SSH Private Key
    if [ -n "${data.coder_parameter.ssh_private_key.value}" ]; then
      echo "Injecting SSH Private Key..."
      mkdir -p ~/.ssh
      cat > ~/.ssh/id_ed25519 <<'SSH_EOF'
${data.coder_parameter.ssh_private_key.value}
SSH_EOF
      chmod 600 ~/.ssh/id_ed25519
    fi

    # Inject Kubeconfig
    if [ -n "${data.coder_parameter.kubeconfig.value}" ]; then
      echo "Injecting Kubeconfig..."
      mkdir -p ~/.kube
      cat > ~/.kube/config <<'KUBECONFIG_EOF'
${data.coder_parameter.kubeconfig.value}
KUBECONFIG_EOF
      chmod 600 ~/.kube/config
    fi

    # Inject SOPS Age Key
    if [ -n "${data.coder_parameter.sops_age_key.value}" ]; then
      echo "Injecting SOPS Age Key..."
      mkdir -p ~/.config/sops/age
      cat > ~/.config/sops/age/keys.txt <<'SOPS_EOF'
${data.coder_parameter.sops_age_key.value}
SOPS_EOF
      chmod 600 ~/.config/sops/age/keys.txt
    fi

    # Inject Ansible Config
    if [ -n "${data.coder_parameter.ansible_config.value}" ]; then
      echo "Injecting Ansible Config..."
      cat > ~/.ansible.cfg <<'ANSIBLE_CFG_EOF'
${data.coder_parameter.ansible_config.value}
ANSIBLE_CFG_EOF
    fi

    # Inject Ansible Inventory
    if [ -n "${data.coder_parameter.ansible_inventory.value}" ]; then
      echo "Injecting Ansible Inventory..."
      cat > ~/inventory.ini <<'ANSIBLE_INV_EOF'
${data.coder_parameter.ansible_inventory.value}
ANSIBLE_INV_EOF
    fi
  EOT

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

data "coder_parameter" "install_k8s_tools" {
  name         = "install_k8s_tools"
  display_name = "Install Kubernetes Tools"
  description  = "Install kubectl, helm, and k9s in the workspace"
  default      = "true"
  type         = "bool"
  mutable      = true
  icon         = "/icon/k8s.png"
}

data "coder_parameter" "install_terraform_tools" {
  name         = "install_terraform_tools"
  display_name = "Install Terraform Tools"
  description  = "Install lightweight terraform binary in the workspace for validation"
  default      = "false"
  type         = "bool"
  mutable      = true
  icon         = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/terraform.svg"
}

data "coder_parameter" "install_flux_tools" {
  name         = "install_flux_tools"
  display_name = "Install Flux CLI"
  description  = "Install flux in the workspace"
  default      = "false"
  type         = "bool"
  mutable      = true
  icon         = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/flux.svg"
}

data "coder_parameter" "install_sops_age_tools" {
  name         = "install_sops_age_tools"
  display_name = "Install SOPS & Age"
  description  = "Install SOPS and age tools for gitops secret management"
  default      = "false"
  type         = "bool"
  mutable      = true
  icon         = "/icon/k8s.png"
}

data "coder_parameter" "install_ansible_tools" {
  name         = "install_ansible_tools"
  display_name = "Install Ansible Tools"
  description  = "Install ansible in the workspace"
  default      = "false"
  type         = "bool"
  mutable      = true
  icon         = "/icon/ansible.svg"
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

data "coder_parameter" "kubeconfig" {
  name         = "kubeconfig"
  display_name = "Kubeconfig"
  description  = "Paste your kubeconfig YAML content"
  default      = ""
  type         = "string"
  form_type    = "textarea"
  mutable      = true
  icon         = "/icon/k8s.png"
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

data "coder_parameter" "ansible_config" {
  name         = "ansible_config"
  display_name = "Ansible Config"
  description  = "(Optional) Paste your ~/.ansible.cfg content"
  default      = ""
  type         = "string"
  form_type    = "textarea"
  mutable      = true
  icon         = "/icon/ansible.svg"
}

data "coder_parameter" "ansible_inventory" {
  name         = "ansible_inventory"
  display_name = "Ansible Inventory"
  description  = "(Optional) Paste your ~/inventory.ini content"
  default      = ""
  type         = "string"
  form_type    = "textarea"
  mutable      = true
  icon         = "/icon/ansible.svg"
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
    namespace = var.namespace
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
        storage = "${data.coder_parameter.home_disk_size.value}Gi"
      }
    }
  }
}

resource "kubernetes_deployment_v1" "main" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim_v1.home
  ]
  wait_for_rollout = false
  metadata {
    name      = "coder-${data.coder_workspace.me.id}"
    namespace = var.namespace
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
        security_context {
          run_as_user     = 1000
          fs_group        = 1000
          run_as_non_root = true
        }

        container {
          name              = "dev"
          image             = "codercom/enterprise-node:ubuntu"
          image_pull_policy = "Always"
          command           = ["sh", "-c", coder_agent.main.init_script]
          security_context {
            run_as_user = "1000"
          }
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }
          resources {
            requests = {
              "cpu"    = "100m"
              "memory" = "256Mi"
            }
            limits = {
              "cpu"    = "${data.coder_parameter.cpu.value}"
              "memory" = "${data.coder_parameter.memory.value}Gi"
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
        }
      }
    }
  }
}
