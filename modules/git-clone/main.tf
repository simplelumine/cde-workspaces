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
  description  = "List of git repositories to clone (one per line)."
  default      = ""
  mutable      = true
  type         = "string"
  icon         = "/icon/git.svg"
  form_type    = "textarea"
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

    # Replace commas with newlines to support both formats
    REPOS=$(echo "$REPOS" | tr ',' '\n')

    while IFS= read -r REPO; do
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
        if git clone "$REPO"; then
          echo "Successfully cloned $REPO"
        else
          echo "⚠️  Failed to clone $REPO (likely private). Please run manually:"
          echo "git clone $REPO $BASE_DIR/$REPO_NAME"
          # Clean up partial directory
          rm -rf "$REPO_NAME"
        fi
      fi
    done <<< "$REPOS"
  EOT
}
