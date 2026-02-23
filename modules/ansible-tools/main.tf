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

    if [ -n "${data.coder_parameter.ssh_private_key.value}" ]; then
      echo "Injecting SSH Private Key..."
      mkdir -p ~/.ssh
      cat > ~/.ssh/id_ed25519 <<'SSH_EOF'
${data.coder_parameter.ssh_private_key.value}
SSH_EOF
      chmod 600 ~/.ssh/id_ed25519
    fi

    if [ -n "${data.coder_parameter.ansible_config.value}" ]; then
      echo "Injecting Ansible Config..."
      cat > ~/.ansible.cfg <<'ANSIBLE_CFG_EOF'
${data.coder_parameter.ansible_config.value}
ANSIBLE_CFG_EOF
    fi

    if [ -n "${data.coder_parameter.ansible_inventory.value}" ]; then
      echo "Injecting Ansible Inventory..."
      cat > ~/inventory.ini <<'ANSIBLE_INV_EOF'
${data.coder_parameter.ansible_inventory.value}
ANSIBLE_INV_EOF
    fi
  EOT
}
