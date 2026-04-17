terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

variable "agent_id" {
  description = "The ID of a Coder agent."
  type        = string
}

variable "tools_list" {
  description = "List of tools to install"
  type        = list(string)
  default     = []
}

resource "coder_script" "install_golang" {
  count        = contains(var.tools_list, "golang") ? 1 : 0
  agent_id     = var.agent_id
  display_name = "🐹 Install Golang"
  icon         = "/icon/go.svg"
  run_on_start = true
  script = <<-EOF
    #!/bin/bash
    set -e
    
    # Dynamically fetch the latest stable Go version (e.g. 1.22.1)
    GO_VERSION=$(curl -sSL "https://go.dev/VERSION?m=text" | head -n 1 | sed 's/^go//')
    
    # Download and install if not exists or if version mismatches
    if ! command -v /usr/local/go/bin/go &> /dev/null || [[ "$(/usr/local/go/bin/go version)" != *"$GO_VERSION"* ]]; then
      echo "⬇️ Downloading latest Golang ($GO_VERSION)..."
      sudo rm -rf /usr/local/go
      curl -fsSL "https://go.dev/dl/go$${GO_VERSION}.linux-amd64.tar.gz" | sudo tar -C /usr/local -xz
    fi

    # Persist in user's bashrc if not present
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
      echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi
    
    echo "✅ Golang installed: $(/usr/local/go/bin/go version)"
  EOF
}

resource "coder_script" "install_python" {
  count        = contains(var.tools_list, "python") ? 1 : 0
  agent_id     = var.agent_id
  display_name = "🐍 Install Python 3 & Pip"
  icon         = "/icon/python.svg"
  run_on_start = true
  script = <<-EOF
    #!/bin/bash
    set -e
    if ! command -v python3 &> /dev/null || ! command -v pip3 &> /dev/null; then
      echo "⬇️ Installing Python 3 & pip via apt..."
      sudo apt-get update -y
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip python3-venv
    else
      echo "✅ Python inherently present: $(python3 --version)"
    fi
  EOF
}

resource "coder_script" "install_nodejs" {
  count        = contains(var.tools_list, "nodejs") ? 1 : 0
  agent_id     = var.agent_id
  display_name = "🟢 Install Node.js & Yarn"
  icon         = "/icon/node.svg"
  run_on_start = true
  script = <<-EOF
    #!/bin/bash
    set -e
    # Install Node.js latest LTS
    if ! command -v node &> /dev/null; then
      echo "⬇️ Installing Node.js (Latest LTS)..."
      curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
      sudo npm install -g yarn pnpm
    else
      echo "✅ Node.js inherently present: $(node --version)"
    fi
  EOF
}
