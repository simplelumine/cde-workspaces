terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

data "coder_parameter" "location" {
  name         = "location"
  display_name = "Workspace Zone"
  description  = "Select the location for your workspace. Choose the node closest to you for the lowest typing latency. If no capacity is available here, the workspace will fail to start."
  icon         = "/emojis/1f4cd.png"
  mutable      = true
  order        = 1

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
