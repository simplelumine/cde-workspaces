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

    # Expand tilde if present
    eval BASE_DIR=$BASE_DIR

    if [ -z "$REPOS" ]; then
      echo "No repositories to clone."
      exit 0
    fi

    mkdir -p "$BASE_DIR"
    cd "$BASE_DIR"

    # Split by comma
    IFS=',' read -ra REPO_LIST <<< "$REPOS"

    clone_repo() {
      local repo_url=$1
      local max_retries=10
      local wait_time=2 # seconds

      for ((i=1; i<=max_retries; i++)); do
        echo "Attempt $i/$max_retries: Cloning $repo_url..."
        if git clone "$repo_url"; then
          echo "Successfully cloned $repo_url"
          return 0
        else
          echo "Clone failed. Retrying in $wait_time seconds..."
          sleep $wait_time
          # Exponential backoff? Or just linear wait to let agent connect
          # wait_time=$((wait_time * 2))
        fi
      done
      
      echo "Failed to clone $repo_url after $max_retries attempts."
      return 1
    }

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
        clone_repo "$REPO"
      fi
    done
  EOT
}
