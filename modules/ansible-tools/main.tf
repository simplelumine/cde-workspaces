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

data "coder_parameter" "install_ansible_tools" {
  name         = "install_ansible_tools"
  display_name = "Install Ansible Tools"
  description  = "Install ansible in the workspace"
  default      = var.default
  type         = "bool"
  mutable      = true
  icon         = "/icon/ansible.svg"
}

variable "ansible_config" {
  type        = string
  description = "The ~/.ansible.cfg content to inject"
  default     = ""
}

variable "ansible_inventory" {
  type        = string
  description = "The ~/inventory.ini content to inject"
  default     = ""
}

variable "ssh_private_key" {
  type        = string
  description = "The SSH private key to inject for git/ansible"
  default     = ""
}

resource "coder_script" "ansible_tools" {
  agent_id     = var.agent_id
  display_name = "Install Ansible Core & Configs"
  icon         = "/icon/ansible.svg"
  run_on_start = true
  script       = <<EOT
    #!/bin/bash
    set -e

    if [ "${data.coder_parameter.install_ansible_tools.value}" = "true" ]; then
      if ! command -v ansible >/dev/null 2>&1; then
        echo "Installing Ansible Core..."
        sudo -u coder pip3 install --user ansible-core --break-system-packages
        sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y sshpass
      fi
    fi

    if [ -n "${var.ssh_private_key}" ]; then
      echo "Injecting SSH Private Key..."
      mkdir -p ~/.ssh
      cat > ~/.ssh/id_ed25519 <<'SSH_EOF'
${var.ssh_private_key}
SSH_EOF
      chmod 600 ~/.ssh/id_ed25519
    fi

    if [ -n "${var.ansible_config}" ]; then
      echo "Injecting Ansible Config..."
      cat > ~/.ansible.cfg <<'ANSIBLE_CFG_EOF'
${var.ansible_config}
ANSIBLE_CFG_EOF
    fi

    if [ -n "${var.ansible_inventory}" ]; then
      echo "Injecting Ansible Inventory..."
      cat > ~/inventory.ini <<'ANSIBLE_INV_EOF'
${var.ansible_inventory}
ANSIBLE_INV_EOF
    fi
  EOT
}
