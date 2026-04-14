terraform {
  required_version = ">= 1.0"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.12"
    }
  }
}

variable "agent_id" {
  type        = string
  description = "The ID of a Coder agent."
}

data "coder_workspace" "me" {}

data "coder_workspace_owner" "me" {}

variable "order" {
  type        = number
  description = "The order determines the position of app in the UI presentation. The lowest order is shown first and apps with equal order are sorted by name (ascending order)."
  default     = null
}

variable "group" {
  type        = string
  description = "The name of a group that this app belongs to."
  default     = null
}

variable "icon" {
  type        = string
  description = "The icon to use for the app."
  default     = "/icon/gemini.svg"
}

variable "folder" {
  type        = string
  description = "The folder to run Gemini in."
  default     = "/home/coder"
}

variable "install_gemini" {
  type        = bool
  description = "Whether to install Gemini."
  default     = true
}

variable "gemini_version" {
  type        = string
  description = "The version of Gemini to install."
  default     = ""
}

variable "gemini_settings_json" {
  type        = string
  description = "json to use in ~/.gemini/settings.json."
  default     = ""
}

data "coder_parameter" "gemini_api_key" {
  name         = "gemini_api_key"
  display_name = "Gemini API Key"
  description  = "Your Gemini API Key"
  default      = ""
  mutable      = true
  type         = "string"
  icon         = "/icon/gemini.svg"
}

data "coder_parameter" "gemini_base_url" {
  name         = "gemini_base_url"
  display_name = "Gemini Base URL"
  description  = "Custom base URL for Gemini API (e.g., a proxy endpoint). Leave empty for default."
  default      = ""
  mutable      = true
  type         = "string"
  icon         = "/icon/gemini.svg"
}

variable "use_vertexai" {
  type        = bool
  description = "Whether to use vertex ai"
  default     = false
}

variable "install_agentapi" {
  type        = bool
  description = "Whether to install AgentAPI for web UI and task automation."
  default     = true
}

variable "agentapi_version" {
  type        = string
  description = "The version of AgentAPI to install."
  default     = "v0.10.0"
}

data "coder_parameter" "gemini_model" {
  name         = "gemini_model"
  display_name = "Gemini Model"
  description  = "The model to use for Gemini (e.g., gemini-2.5-pro, gemini-2.5-flash)."
  default      = ""
  mutable      = true
  type         = "string"
  icon         = "/icon/gemini.svg"
}

variable "pre_install_script" {
  type        = string
  description = "Custom script to run before installing Gemini."
  default     = null
}

variable "post_install_script" {
  type        = string
  description = "Custom script to run after installing Gemini."
  default     = null
}

variable "task_prompt" {
  type        = string
  description = "Task prompt for automated Gemini execution"
  default     = ""
}

variable "additional_extensions" {
  type        = string
  description = "Additional extensions configuration in json format to append to the config."
  default     = null
}

variable "gemini_system_prompt" {
  type        = string
  description = "System prompt for Gemini. It will be added to GEMINI.md in the specified folder."
  default     = ""
}

data "coder_parameter" "enable_gemini" {
  name         = "enable_gemini"
  display_name = "Enable Gemini"
  description  = "Enable or disable Gemini CLI in this workspace."
  default      = "false"
  mutable      = true
  type         = "bool"
  icon         = "/icon/gemini.svg"
  order        = 1
}

data "coder_parameter" "enable_yolo_mode" {
  name         = "enable_yolo_mode"
  display_name = "Enable YOLO Mode"
  description  = "Enable YOLO mode to automatically approve all tool calls without user confirmation. Use with caution."
  default      = "false"
  mutable      = true
  type         = "bool"
  icon         = "/icon/gemini.svg"
}

resource "coder_env" "gemini_api_key" {
  agent_id = var.agent_id
  name     = "GEMINI_API_KEY"
  value    = data.coder_parameter.gemini_api_key.value
}

resource "coder_env" "google_api_key" {
  agent_id = var.agent_id
  name     = "GOOGLE_API_KEY"
  value    = data.coder_parameter.gemini_api_key.value
}

resource "coder_env" "gemini_use_vertex_ai" {
  agent_id = var.agent_id
  name     = "GOOGLE_GENAI_USE_VERTEXAI"
  value    = var.use_vertexai
}

resource "coder_env" "gemini_base_url" {
  count    = data.coder_parameter.gemini_base_url.value != "" ? 1 : 0
  agent_id = var.agent_id
  name     = "GOOGLE_GEMINI_BASE_URL"
  value    = data.coder_parameter.gemini_base_url.value
}

locals {
  base_extensions = <<-EOT
{
  "coder": {
    "args": [
      "exp",
      "mcp",
      "server"
    ],
    "command": "coder",
    "description": "Report ALL tasks and statuses (in progress, done, failed) you are working on.",
    "env": {
      "CODER_MCP_APP_STATUS_SLUG": "${local.app_slug}",
      "CODER_MCP_AI_AGENTAPI_URL": "http://localhost:3284"
    },
    "timeout": 3000,
    "type": "stdio",
    "trust": true
  }
}
EOT

  app_slug        = "gemini"
  install_script  = file("${path.module}/scripts/install.sh")
  start_script    = file("${path.module}/scripts/start.sh")
  module_dir_name = ".gemini-module"
  folder          = trimsuffix(var.folder, "/")
}

resource "coder_script" "gemini_install" {
  count        = data.coder_parameter.enable_gemini.value == "true" ? 0 : 1
  agent_id     = var.agent_id
  display_name = "Install Gemini CLI"
  icon         = var.icon
  run_on_start = true
  script       = <<-EOT
    #!/bin/bash
    set -o errexit
    set -o pipefail
    source "$HOME/.bashrc" 2>/dev/null || true

    if ! command -v node > /dev/null 2>&1 || ! command -v npm > /dev/null 2>&1; then
      echo "Node.js/npm not available, skipping Gemini CLI install"
      exit 0
    fi

    NPM_GLOBAL_PREFIX="$HOME/.npm-global"
    mkdir -p "$NPM_GLOBAL_PREFIX"
    npm config set prefix "$NPM_GLOBAL_PREFIX"
    export PATH="$NPM_GLOBAL_PREFIX/bin:$PATH"

    GEMINI_VERSION='${var.gemini_version}'
    if [ -n "$GEMINI_VERSION" ]; then
      npm install -g "@google/gemini-cli@$GEMINI_VERSION"
    else
      npm install -g "@google/gemini-cli"
    fi

    if ! grep -q 'export PATH="$HOME/.npm-global/bin:$PATH"' "$HOME/.bashrc"; then
      echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
    fi

    echo "✅ Gemini CLI installed (standalone mode - agentapi not started)"
  EOT
}

module "agentapi" {
  count   = data.coder_parameter.enable_gemini.value == "true" ? 1 : 0
  source  = "registry.coder.com/coder/agentapi/coder"
  version = "2.0.0"

  agent_id             = var.agent_id
  folder               = local.folder
  web_app_slug         = local.app_slug
  web_app_order        = var.order
  web_app_group        = var.group
  web_app_icon         = var.icon
  web_app_display_name = "Gemini"
  cli_app_slug         = "${local.app_slug}-cli"
  cli_app_display_name = "Gemini CLI"
  module_dir_name      = local.module_dir_name
  install_agentapi     = var.install_agentapi
  agentapi_version     = var.agentapi_version
  pre_install_script   = var.pre_install_script
  post_install_script  = var.post_install_script
  install_script       = <<-EOT
    #!/bin/bash
    set -o errexit
    set -o pipefail

    echo -n '${base64encode(local.install_script)}' | base64 -d > /tmp/install.sh
    chmod +x /tmp/install.sh
    ARG_INSTALL='${var.install_gemini}' \
    ARG_GEMINI_VERSION='${var.gemini_version}' \
    ARG_GEMINI_CONFIG='${base64encode(var.gemini_settings_json)}' \
    BASE_EXTENSIONS='${base64encode(replace(local.base_extensions, "'", "'\\''"))}' \
    ADDITIONAL_EXTENSIONS='${base64encode(replace(var.additional_extensions != null ? var.additional_extensions : "", "'", "'\\''"))}' \
    GEMINI_START_DIRECTORY='${var.folder}' \
    GEMINI_SYSTEM_PROMPT='${base64encode(var.gemini_system_prompt)}' \
    /tmp/install.sh
  EOT
  start_script         = <<-EOT
     #!/bin/bash
     set -o errexit
     set -o pipefail

     echo -n '${base64encode(local.start_script)}' | base64 -d > /tmp/start.sh
     chmod +x /tmp/start.sh
     GEMINI_API_KEY='${data.coder_parameter.gemini_api_key.value}' \
     GOOGLE_API_KEY='${data.coder_parameter.gemini_api_key.value}' \
     GOOGLE_GENAI_USE_VERTEXAI='${var.use_vertexai}' \
     GEMINI_YOLO_MODE='${data.coder_parameter.enable_yolo_mode.value}' \
     GEMINI_MODEL='${data.coder_parameter.gemini_model.value}' \
     GEMINI_START_DIRECTORY='${var.folder}' \
     GEMINI_TASK_PROMPT='${var.task_prompt}' \
     /tmp/start.sh
   EOT
}

output "task_app_id" {
  value = length(module.agentapi) > 0 ? module.agentapi[0].task_app_id : ""
}
