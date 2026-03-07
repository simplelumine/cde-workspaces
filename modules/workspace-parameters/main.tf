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

data "coder_parameter" "storage_tier" {
  name         = "storage_tier"
  display_name = "Storage Tier"
  description  = "Select the storage volume for /home/coder. Ephemeral mode uses no persistent volume — all data is lost when the workspace stops, but allows free region migration."
  default      = "standard"
  icon         = "/emojis/1f4be.png"
  mutable      = false

  option {
    name        = "Ephemeral (No Disk)"
    description = "⚠️ DATA LOST ON STOP. Best for quick PR reviews. Allows region migration."
    value       = "ephemeral"
    icon        = "/emojis/26a1.png" # ⚡
  }
  option {
    name        = "Standard (10 GB)"
    description = "Persistent home directory for daily development."
    value       = "standard"
    icon        = "/emojis/1f4be.png" # 💾
  }
  option {
    name        = "Expanded (30 GB)"
    description = "Large persistent storage for heavy dependencies and heavy builds."
    value       = "expanded"
    icon        = "/emojis/1f5c4.png" # 🗄️
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
  disk_size_map = {
    "ephemeral" = "0"
    "standard"  = "10"
    "expanded"  = "30"
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

output "is_ephemeral" {
  description = "Whether the workspace uses ephemeral (non-persistent) storage"
  value       = data.coder_parameter.storage_tier.value == "ephemeral"
}
