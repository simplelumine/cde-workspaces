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
  display_name = "Install CNPG Plugin"
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

    if [ "${data.coder_parameter.install_cnpg_plugin.value}" = "true" ]; then
      echo "Installing CloudNativePG kubectl plugin..."
      if ! command -v kubectl-cnpg >/dev/null 2>&1; then
        curl -sSfL "https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/main/hack/install-cnpg-plugin.sh" | sudo sh -s -- -b /usr/local/bin
      fi
    fi
  EOT
}
