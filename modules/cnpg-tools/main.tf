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

data "coder_parameter" "install_cnpg_plugin" {
  name         = "install_cnpg_plugin"
  display_name = "Kubernetes CNPG Plugin"
  description  = "Install the CloudNativePG kubectl plugin in the workspace"
  default      = false
  type         = "bool"
  mutable      = true
  icon         = "/icon/k8s.png"
}

resource "coder_script" "cnpg_tools" {
  agent_id     = var.agent_id
  display_name = "Install CNPG Plugin"
  icon         = "/icon/k8s.png"
  run_on_start = true
  script       = <<EOT
    #!/bin/bash
    set -e

    if [ "${data.coder_parameter.install_cnpg_plugin.value}" != "true" ]; then
      echo "CNPG plugin installation skipped (disabled)."
      exit 0
    fi

    echo "Installing CloudNativePG kubectl plugin..."
    if ! command -v kubectl-cnpg >/dev/null 2>&1; then
      CNPG_VERSION=$(curl -sI https://github.com/cloudnative-pg/cloudnative-pg/releases/latest | awk -F/ '/^location:/ || /^Location:/ {print $NF}' | tr -d '\r' | sed 's/^v//')
      ARCH=$(uname -m)
      curl -fsSL "https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v$${CNPG_VERSION}/kubectl-cnpg_$${CNPG_VERSION}_linux_$${ARCH}.tar.gz" | tar xz -C /tmp
      sudo mv /tmp/kubectl-cnpg /usr/local/bin/
      echo "✅ kubectl-cnpg v$${CNPG_VERSION} installed."
    else
      echo "kubectl-cnpg already installed."
    fi
  EOT
}
