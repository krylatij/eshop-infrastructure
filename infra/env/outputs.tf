resource "local_file" "aksconfig" {
  depends_on   = [azurerm_kubernetes_cluster.aks]
  filename     = "aksconfig"
  content      = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "cluster_routing_zone" {
  value = azurerm_kubernetes_cluster.aks.addon_profile.0.http_application_routing.0.http_application_routing_zone_name
}

output "rg_name" {
  value = azurerm_resource_group.resource_group.name
}

output "pipeline_principal_object_id" {
  value = azuread_service_principal.pipeline.object_id
}

output "pipeline_principal_password" {
  value = azuread_service_principal_password.pipeline_password.value
  sensitive   = true
}