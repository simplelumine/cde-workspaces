terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

data "coder_parameter" "location" {
  name         = "location"
  display_name = "Location"
  description  = "Select the location for your workspace. Choose the node closest to you for the lowest typing latency. If no capacity is available here, the workspace will fail to start."
  default      = "lax"
  icon         = "/emojis/1f4cd.png"
  mutable      = false

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
  description = "The selected location value from the Coder UI"
  value       = data.coder_parameter.location.value
}
