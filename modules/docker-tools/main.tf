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

data "coder_parameter" "install_docker_tools" {
  name         = "install_docker_tools"
  display_name = "Install Docker Tools"
  description  = "Install Docker Engine, CLI, Compose, and Buildx using official Docker repository"
  default      = false
  type         = "bool"
  mutable      = true
  icon         = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/docker.svg"
}

resource "coder_script" "docker_tools" {
  agent_id     = var.agent_id
  display_name = "Install Docker (Official)"
  icon         = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/docker.svg"
  run_on_start = true
  script       = <<EOT
    #!/bin/bash
    set -e

    if [ "${data.coder_parameter.install_docker_tools.value}" = "true" ]; then
      if ! command -v docker >/dev/null 2>&1; then
        echo "Installing Docker using official steps..."
        
        # 1. Provide dependencies
        sudo apt-get update -qq
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl > /dev/null

        # 2. Add Docker's official GPG key
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # 3. Add the repository to Apt sources
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        sudo apt-get update -qq

        # 4. Install the Docker packages
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null
        
        # Optional: Add coder user to docker group if docker group exists
        if getent group docker > /dev/null 2>&1; then
          sudo usermod -aG docker coder || true
        fi
        
        echo "Docker official installation complete!"
      else
        echo "Docker is already installed."
      fi
    fi
  EOT
}
