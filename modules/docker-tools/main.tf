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
  display_name = "Enable Docker (DinD Sidecar)"
  description  = "Enable Docker support via a DinD sidecar container. Docker CLI is already included in the base image."
  default      = false
  type         = "bool"
  mutable      = true
  icon         = "https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/docker.svg"
}

output "enabled" {
  description = "Whether Docker tools are enabled by the user"
  value       = data.coder_parameter.install_docker_tools.value == "true"
}
