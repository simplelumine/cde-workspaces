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

data "coder_parameter" "install_terraform_tools" {
  name         = "install_terraform_tools"
  display_name = "Install Terraform Tools"
  description  = "Install lightweight terraform binary in the workspace for validation"
  default      = var.default
  type         = "bool"
  mutable      = true
  icon         = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/terraform.svg"
}

resource "coder_script" "terraform_tools" {
  agent_id     = var.agent_id
  display_name = "Install Terraform Tools"
  icon         = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/terraform.svg"
  run_on_start = true
  script       = <<EOT
    #!/bin/bash
    set -e

    if [ "${data.coder_parameter.install_terraform_tools.value}" = "true" ]; then
      if ! command -v terraform >/dev/null 2>&1; then
        echo "Installing Terraform..."
        TERRAFORM_VERSION=$(curl -sI https://github.com/hashicorp/terraform/releases/latest | awk -F/ '/^location:/ || /^Location:/ {print $NF}' | tr -d '\r' | sed 's/^v//')
        curl -fsSL -o /tmp/terraform.zip "https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip"
        sudo unzip -q /tmp/terraform.zip -d /usr/local/bin/
        rm /tmp/terraform.zip
      fi
    fi
  EOT
}
