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

variable "default" {
  type        = string
  description = "Default value for the parameter"
  default     = "false"
}

data "coder_parameter" "install_flux_tools" {
  name         = "install_flux_tools"
  display_name = "Install Flux CLI"
  description  = "Install flux in the workspace"
  default      = var.default
  type         = "bool"
  mutable      = true
  icon         = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/flux.svg"
}

resource "coder_script" "flux_tools" {
  agent_id     = var.agent_id
  display_name = "Install Flux CLI"
  icon         = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/flux.svg"
  run_on_start = true
  script       = <<EOT
    #!/bin/bash
    set -e

    if [ "${data.coder_parameter.install_flux_tools.value}" = "true" ]; then
      echo "Installing Flux CLI..."
      if ! command -v flux >/dev/null 2>&1; then
        curl -s https://fluxcd.io/install.sh | sudo bash
      fi
    fi
  EOT
}
