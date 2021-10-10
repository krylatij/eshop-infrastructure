data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault"{
    name = "kv-${var.prefix}" 
    location = azurerm_resource_group.resource_group.location
    resource_group_name = azurerm_resource_group.resource_group.name
    tenant_id = data.azurerm_client_config.current.tenant_id
    sku_name = "standard"

    access_policy {
        tenant_id = data.azurerm_client_config.current.tenant_id
        object_id = data.azurerm_client_config.current.object_id

        key_permissions = [
            "create",
            "get",
        ]

        secret_permissions = [
            "set",
            "get",
            "list"       
        ]
    }

    tags = {
      env = var.env
  }
}

resource "azurerm_key_vault_access_policy" "pipeline" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_service_principal.pipeline.object_id

  key_permissions = []

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_secret" "repository" {
  name         = "${var.env}-repository"
  value        = data.azurerm_container_registry.acr.login_server
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "resource_group" {
  name         = "${var.env}-resource-group"
  value        = azurerm_resource_group.resource_group.name
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "cluster_name" {
  name         = "${var.env}-cluster-name"
  value        = azurerm_kubernetes_cluster.aks.name
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "cluster_dns" {
  name         = "${var.env}-cluster-dns"
  value        = azurerm_kubernetes_cluster.aks.addon_profile.0.http_application_routing.0.http_application_routing_zone_name
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "pipeline-principal-appid" {
  name         = "pipeline-principal-appid"
  value        = azuread_service_principal.pipeline.object_id
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_key_vault_secret" "pipeline-principal-password" {
  name         = "pipeline-principal-password"
  value        = azuread_service_principal_password.pipeline_password.value
  key_vault_id = azurerm_key_vault.vault.id
}

