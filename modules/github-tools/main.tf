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

data "coder_parameter" "install_github_cli" {
  name         = "install_github_cli"
  display_name = "Install GitHub CLI"
  description  = "Install the official GitHub CLI (gh) and auto-authenticate it with Coder's GitHub OAuth token"
  default      = false
  type         = "bool"
  mutable      = true
  icon         = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/github.svg"
}

resource "coder_script" "github_tools" {
  agent_id     = var.agent_id
  display_name = "Install GitHub CLI"
  icon         = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/github.svg"
  run_on_start = true
  script       = <<EOT
    #!/bin/bash
    set -e

    if [ "${data.coder_parameter.install_github_cli.value}" = "true" ]; then
      if ! command -v gh >/dev/null 2>&1; then
        echo "Installing GitHub CLI..."
        GH_VERSION=$(curl -sI https://github.com/cli/cli/releases/latest | awk -F/ '/^location:/ || /^Location:/ {print $NF}' | tr -d '\r' | sed 's/^v//')
        curl -fsSL "https://github.com/cli/cli/releases/download/v$${GH_VERSION}/gh_$${GH_VERSION}_linux_amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/gh_$${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin/
      fi
    fi
  EOT
}
