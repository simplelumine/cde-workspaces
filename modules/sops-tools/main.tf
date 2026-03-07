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

data "coder_parameter" "install_sops_age_tools" {
  name         = "install_sops_age_tools"
  display_name = "Install SOPS & Age"
  description  = "Install SOPS and age tools for gitops secret management"
  default      = false
  type         = "bool"
  mutable      = true
  icon         = "/icon/k8s.png"
}

variable "sops_age_key" {
  type        = string
  description = "The SOPS Age private key content to inject"
  default     = ""
}

resource "coder_script" "sops_tools" {
  agent_id     = var.agent_id
  display_name = "Install SOPS & Age"
  icon         = "/icon/k8s.png"
  run_on_start = true
  script       = <<EOT
    #!/bin/bash
    set -e

    if [ "${data.coder_parameter.install_sops_age_tools.value}" = "true" ]; then
      echo "Installing SOPS and Age..."
      if ! command -v sops >/dev/null 2>&1; then
        SOPS_VERSION=$(curl -sI https://github.com/getsops/sops/releases/latest | awk -F/ '/^location:/ || /^Location:/ {print $NF}' | tr -d '\r' | sed 's/^v//')
        curl -fsSL -o /tmp/sops "https://github.com/getsops/sops/releases/download/v$${SOPS_VERSION}/sops-v$${SOPS_VERSION}.linux.amd64"
        chmod +x /tmp/sops
        sudo mv /tmp/sops /usr/local/bin/
      fi

      if ! command -v age >/dev/null 2>&1; then
        AGE_VERSION=$(curl -sI https://github.com/FiloSottile/age/releases/latest | awk -F/ '/^location:/ || /^Location:/ {print $NF}' | tr -d '\r' | sed 's/^v//')
        curl -fsSL "https://github.com/FiloSottile/age/releases/download/v$${AGE_VERSION}/age-v$${AGE_VERSION}-linux-amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/age/age /usr/local/bin/
        sudo mv /tmp/age/age-keygen /usr/local/bin/
      fi
    fi

    if [ -n "${var.sops_age_key}" ]; then
      echo "Injecting SOPS Age Key..."
      mkdir -p ~/.config/sops/age
      cat > ~/.config/sops/age/keys.txt <<'SOPS_EOF'
${var.sops_age_key}
SOPS_EOF
      chmod 600 ~/.config/sops/age/keys.txt
    fi
  EOT
}
