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

variable "base_dir" {
  type        = string
  description = "The directory to clone repositories into."
  default     = "~"
}

variable "github_access_token" {
  type        = string
  description = "GitHub access token for cloning private repos."
  default     = ""
  sensitive   = true
}

data "coder_parameter" "git_repos" {
  name         = "git_repos"
  display_name = "Git Repositories"
  description  = "Comma-separated list of git repositories to clone."
  default      = ""
  mutable      = true
  type         = "string"
  icon         = "/icon/git.svg"
}

resource "coder_script" "git_clone" {
  agent_id     = var.agent_id
  display_name = "Clone Git Repositories"
  icon         = "/icon/git.svg"
  run_on_start = true
  script       = <<EOT
    #!/bin/bash

    REPOS="${data.coder_parameter.git_repos.value}"
    BASE_DIR="${var.base_dir}"
    GITHUB_TOKEN="${var.github_access_token}"

    # Expand tilde if present
    eval BASE_DIR=$BASE_DIR

    if [ -z "$REPOS" ]; then
      echo "No repositories to clone."
      exit 0
    fi

    # Configure git to use the token for GitHub authentication
    if [ -n "$GITHUB_TOKEN" ]; then
      echo "Configuring GitHub authentication..."
      git config --global url."https://oauth2:$${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
    fi

    mkdir -p "$BASE_DIR"
    cd "$BASE_DIR"

    # Split by comma
    IFS=',' read -ra REPO_LIST <<< "$REPOS"

    for REPO in "$${REPO_LIST[@]}"; do
      # Trim whitespace
      REPO=$(echo "$REPO" | xargs)

      if [ -z "$REPO" ]; then
        continue
      fi

      # Extract repo name from URL (e.g., https://github.com/coder/coder.git -> coder)
      REPO_NAME=$(basename "$REPO" .git)

      if [ -d "$REPO_NAME" ]; then
        echo "Repository $REPO_NAME already exists. Skipping..."
      else
        echo "Cloning $REPO..."
        git clone "$REPO"
      fi
    done

    # Clean up: remove the token-based URL rewrite so future git operations
    # use the normal Coder credential helper (which will be ready by then)
    if [ -n "$GITHUB_TOKEN" ]; then
      git config --global --unset-all url."https://oauth2:$${GITHUB_TOKEN}@github.com/".insteadOf || true
    fi
  EOT
}
