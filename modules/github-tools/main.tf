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

variable "external_auth_id" {
  type        = string
  description = "The Coder external auth provider ID (e.g. 'primary-github') used to fetch fresh OAuth tokens at runtime."
}

data "coder_parameter" "install_github_cli" {
  name         = "install_github_cli"
  display_name = "Install GitHub CLI"
  description  = "Install the official GitHub CLI (gh) and auto-authenticate it with Coder's GitHub OAuth token"
  default      = true
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
      # --- Install gh CLI if not present ---
      if ! command -v gh >/dev/null 2>&1; then
        echo "Installing GitHub CLI..."
        GH_VERSION=$(curl -sI https://github.com/cli/cli/releases/latest | awk -F/ '/^location:/ || /^Location:/ {print $NF}' | tr -d '\r' | sed 's/^v//')
        curl -fsSL "https://github.com/cli/cli/releases/download/v$${GH_VERSION}/gh_$${GH_VERSION}_linux_amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/gh_$${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin/
      fi

      # --- Configure dynamic token refresh for gh CLI ---
      # Static GITHUB_TOKEN from build-time expires after ~8h.
      # Instead, we configure a shell function that fetches a fresh token
      # on every `gh` invocation using the Coder CLI.
      BASHRC="$${HOME}/.bashrc"
      MARKER="# coder-gh-dynamic-token"
      AUTH_ID="${var.external_auth_id}"

      if ! grep -qF "$${MARKER}" "$${BASHRC}" 2>/dev/null; then
        cat >> "$${BASHRC}" << GHEOF

# coder-gh-dynamic-token
# Unset any stale static GITHUB_TOKEN injected at workspace build time
unset GITHUB_TOKEN 2>/dev/null

# Wrapper: fetch a fresh OAuth token from Coder on every gh invocation
gh() {
  local token
  token=\$(command coder external-auth access-token $${AUTH_ID} 2>/dev/null)
  if [ -n "\$token" ]; then
    GITHUB_TOKEN="\$token" command gh "\$@"
  else
    echo "⚠️  Failed to fetch GitHub token. Try: coder external-auth access-token $${AUTH_ID}" >&2
    command gh "\$@"
  fi
}
GHEOF
        echo "✅ Configured dynamic GitHub token refresh for gh CLI (auth: $${AUTH_ID})."
      else
        echo "Dynamic GitHub token refresh already configured."
      fi
    fi
  EOT
}
