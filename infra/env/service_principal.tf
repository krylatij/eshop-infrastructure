data "azuread_client_config" "current" {}

resource "azuread_service_principal" "pipeline" {
  description                 = "${var.app} Azure DevOps pipeline"
  application_id               = azuread_application.application.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]

  alternative_names = ["${var.app} AzureDevOps pipeline"]
}

resource "time_rotating" "monthly_rotation" {
  rotation_days = 30
}

resource "azuread_service_principal_password" "pipeline_password" {
  service_principal_id = azuread_service_principal.pipeline.object_id  
  #display_name = "Pass for AzureDevOps pipeline"

  #rotate_when_changed = {
  #  rotation = time_rotating.monthly_rotation
  #}
}