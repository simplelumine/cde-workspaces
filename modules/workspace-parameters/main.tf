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
    name  = "Flash (3 Cores, 4 GB RAM)"
    value = "flash"
  }
  option {
    name  = "Pro (4 Cores, 6 GB RAM)"
    value = "pro"
  }
}

data "coder_parameter" "storage_tier" {
  name         = "storage_tier"
  display_name = "Storage Tier"
  description  = "Select the persistent storage volume size for /home/coder"
  default      = "lite"
  icon         = "/emojis/1f4be.png"
  mutable      = false

  option {
    name        = "Lite (10 GB)"
    description = "Lightweight persistent storage for everyday development."
    value       = "lite"
  }
  option {
    name        = "Flash (30 GB)"
    description = "Balanced storage for projects with heavy dependencies and builds."
    value       = "flash"
  }
  option {
    name        = "Pro (50 GB)"
    description = "Maximum storage for monorepos, large datasets, and intensive workloads."
    value       = "pro"
  }
}

locals {
  cpu_map = {
    "lite"  = "2"
    "flash" = "3"
    "pro"   = "4"
  }
  memory_map = {
    "lite"  = "2"
    "flash" = "4"
    "pro"   = "6"
  }
  disk_size_map = {
    "lite"     = "10"
    "flash"    = "30"
    "pro"      = "50"
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
  description = "The resolved disk size based on storage tier"
  value       = local.disk_size_map[data.coder_parameter.storage_tier.value]
}

