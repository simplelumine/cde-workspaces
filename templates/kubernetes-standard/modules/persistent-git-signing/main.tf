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

data "coder_parameter" "git_signing_key" {
  name        = "git_signing_key"
  display_name = "Git Signing Key (Private)"
  description = "Paste your private SSH key (e.g. content of ~/.ssh/id_ed25519) to persist git signing verification."
  default     = ""
  mutable     = true
  type        = "string"
  icon        = "/icon/github.svg"
}

resource "coder_script" "configure_git_signing" {
  agent_id     = var.agent_id
  display_name = "Configure Persistent Git Signing"
  icon         = "/icon/github.svg"
  run_on_start = true
  script = <<EOT
    #!/bin/sh
    set -e
    
    KEY="${data.coder_parameter.git_signing_key.value}"
    
    if [ -n "$KEY" ]; then
      mkdir -p ~/.ssh
      echo "$KEY" > ~/.ssh/signing_key
      chmod 600 ~/.ssh/signing_key
      
      # Configure Git to use this key
      git config --global gpg.format ssh
      git config --global user.signingkey ~/.ssh/signing_key
      git config --global commit.gpgsign true
      
      echo "Configured persistent git signing key."
    else
      echo "No git signing key provided. Skipping configuration."
    fi
  EOT
}
