terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

variable "agent_id" {
  type        = string
  description = "The ID of a Coder agent."
}

variable "kubeconfig" {
  type        = string
  description = "The kubeconfig YAML content to inject into the workspace"
  default     = ""
}

data "coder_parameter" "install_k8s_tools" {
  name         = "install_k8s_tools"
  display_name = "Install Kubernetes Tools"
  description  = "Install kubectl, helm, and k9s in the workspace"
  default      = false
  type         = "bool"
  mutable      = true
  icon         = "/icon/k8s.png"
}

resource "coder_script" "kubernetes_tools" {
  agent_id     = var.agent_id
  display_name = "Install Kubernetes Tools"
  icon         = "/icon/k8s.png"
  run_on_start = true
  script       = <<EOT
    #!/bin/bash
    set -e

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
        K9S_VERSION=$(curl -sI https://github.com/derailed/k9s/releases/latest | awk -F/ '/^location:/ || /^Location:/ {print $NF}' | tr -d '\r' | sed 's/^v//')
        curl -fsSL "https://github.com/derailed/k9s/releases/download/v$${K9S_VERSION}/k9s_Linux_amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/k9s /usr/local/bin/
      fi

      # Install devspace
      if ! command -v devspace >/dev/null 2>&1; then
        curl -fsSL -o devspace "https://github.com/loft-sh/devspace/releases/latest/download/devspace-linux-amd64"
        chmod +x devspace
        sudo mv devspace /usr/local/bin/
      fi

      # Install skaffold
      if ! command -v skaffold >/dev/null 2>&1; then
        curl -fsSL -o skaffold "https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64"
        chmod +x skaffold
        sudo mv skaffold /usr/local/bin/
      fi
    fi

    if [ -n "${var.kubeconfig}" ]; then
      echo "Injecting kubeconfig..."
      mkdir -p ~/.kube
      cat > ~/.kube/config <<'KUBECONFIG_EOF'
${var.kubeconfig}
KUBECONFIG_EOF
      chmod 600 ~/.kube/config
    fi
  EOT
}
