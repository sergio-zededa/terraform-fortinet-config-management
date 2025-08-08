variable "Project_ID" {
  description = "This is the Project ID"
  type        = string
  default     = "7d5182fc-4ed5-43f8-ac85-fa34677903b4"
}

variable "Project_name" {
  description = "This is the Project ID"
  type        = string
  default     = "sergio-project"
}


variable "Model_ID" {
  description = "This is the Device Model ID"
  type        = string
  default     = "8c4b7295-52de-43d8-84c5-934c01ca8305"
}

variable "Sidecar_App_Template" {
  description = "This is the Sidecar App Sidecar Template Name"
  type        = string
  default     = "ss_fortinet_sidecar"
} 




variable "patch_envelope_list" {
  description = "List of Patch Envelopes to be applied"
  type        = list(object({
    name = string
    version = string
    activate = bool

    firewall_ip = string
    firewall_token = string
    firewall_config = string
    sidecar_app_name = string
  }))
  default     = [
    {
      name = "fw1_patch_envelope"
      version = "1.0"
      activate = true
      firewall_ip = "fw.local"
      firewall_token = "./fw_configs/fw1_token.txt"
      #firewall_config = "./fw_configs/fw1_after_config.txt"
      firewall_config = "./fw_configs/fw1_before_config.txt"
      sidecar_app_name = "ss_fortinet_sidecar_fw1"
    }
  ]
}



