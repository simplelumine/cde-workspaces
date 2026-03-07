terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

data "coder_parameter" "instance_type" {
  name         = "instance_type"
  display_name = "Instance Type"
  description  = "Select the compute tier for your workspace (CPU and Memory)"
  default      = "lite"
  icon         = "/icon/k8s.svg"
  mutable      = true

  option {
    name  = "Lite (2 Cores, 2 GB RAM)"
    value = "lite"
  }
  option {
    name  = "Flash (3 Cores, 3 GB RAM)"
    value = "flash"
  }
  option {
    name  = "Pro (4 Cores, 4 GB RAM)"
    value = "pro"
  }
  option {
    name  = "Ultra (4 Cores, 6 GB RAM)"
    value = "ultra"
  }
}

data "coder_parameter" "home_disk_size" {
  name         = "home_disk_size"
  display_name = "Home disk size"
  description  = "The size of the home disk in GB"
  default      = "10"
  type         = "number"
  icon         = "/emojis/1f310.png"
  mutable      = false
  validation {
    min = 1
    max = 99999
  }
}

locals {
  cpu_map = {
    "lite"  = "2"
    "flash" = "3"
    "pro"   = "4"
    "ultra" = "4"
  }
  memory_map = {
    "lite"  = "2"
    "flash" = "3"
    "pro"   = "4"
    "ultra" = "6"
  }
}

output "cpu" {
  description = "The resolved CPU cores based on instance type"
  value       = local.cpu_map[data.coder_parameter.instance_type.value]
}

output "memory" {
  description = "The resolved Memory size based on instance type"
  value       = local.memory_map[data.coder_parameter.instance_type.value]
}

output "home_disk_size" {
  value = data.coder_parameter.home_disk_size.value
}
