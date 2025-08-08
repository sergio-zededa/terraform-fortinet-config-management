resource "zedcloud_patch_envelope" "fw_config_update" {
  
  for_each = { for i in var.patch_envelope_list : i.name => i }
  name = "${each.value.name}"
  action = "PATCH_ENVELOPE_ACTION_ACTIVATE"
  title = "${each.value.name}"
  description = "Patch envelope for ${each.value.sidecar_app_name}"
  user_defined_version = "${each.value.version}"

  artifacts {
    format = "OpaqueObjectCategoryInline"
    base64_artifact {
      base64_data      =  base64encode("${each.value.firewall_ip}")
      file_name_to_use = "firewall"
    }
  }

  artifacts {
    format = "OpaqueObjectCategoryInline"
    base64_artifact {
      base64_data      =  base64encode(file("${each.value.firewall_config}"))
      file_name_to_use = "config"
    }
  }

  artifacts {
    format = "OpaqueObjectCategoryInline"
    base64_artifact {
      base64_data      =  base64encode(file("${each.value.firewall_token}"))
      file_name_to_use = "token"
    }
  }


  project_name = var.Project_name
  project_id = var.Project_ID
}

data "zedcloud_application" "sidecar_app" {
  name = var.Sidecar_App_Template
  title = var.Sidecar_App_Template
}

data "zedcloud_application_instance" "my_instance" {
  for_each = { for i in var.patch_envelope_list : i.name => i }
  
  name        = each.value.sidecar_app_name
  app_id =  data.zedcloud_application.sidecar_app.id
  title =  each.value.sidecar_app_name
  project_id = var.Project_ID
}

resource "zedcloud_patch_reference_update" "fw_config_patch_reference" {
  
  for_each = { for i in var.patch_envelope_list : i.name => i }
  patchenvelope_id = zedcloud_patch_envelope.fw_config_update["${each.value.name}"].id
  project_id = var.Project_ID
  app_inst_id_list = [data.zedcloud_application_instance.my_instance[each.key].id]

}



