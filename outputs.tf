output "patch_envelope_ids" {
  description = "IDs of all created patch envelopes"
  value = {
    for name, pe in zedcloud_patch_envelope.fw_config_update : name => pe.id
  }
}


output "application_instance_details" {
  description = "Details of the found application instances"
  value = {
    for name, instance in data.zedcloud_application_instance.my_instance : instance.name => instance.id
  }
  sensitive = true
}

