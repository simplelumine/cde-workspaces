terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

data "coder_parameter" "region_preference" {
  name         = "region_preference"
  display_name = "Region Preference"
  description  = "Select your preferred region for the workspace. The scheduler will attempt to place your workspace on a node in this region. If no capacity is available, it will fall back to other regions."
  default      = "lax"
  icon         = "/emojis/1f310.png"
  mutable      = true

  option {
    name  = "Los Angeles (lax)"
    value = "lax"
  }
  option {
    name  = "San Francisco (sfo)"
    value = "sfo"
  }
  option {
    name  = "Spokane (geg)"
    value = "geg"
  }
  option {
    name  = "Salt Lake City (slc)"
    value = "slc"
  }
}

output "value" {
  description = "The selected region preference value from the Coder UI"
  value       = data.coder_parameter.region_preference.value
}
