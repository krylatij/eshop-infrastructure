resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.prefix}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = "${var.prefix}-k8s"

  default_node_pool {
    name       = "default"
    node_count = var.aks_nodes
    vm_size    = var.aks_tier
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  
    azure_active_directory {
      managed = true
      azure_rbac_enabled = true
    }
  } 

  addon_profile {
    aci_connector_linux {
      enabled = false
    }

    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = true
    }   
  }

  tags = {
      env = var.env
  } 
}

data "azurerm_container_registry" "acr" {
  resource_group_name = var.shared_rg_name
  name = var.shared_acr_name 
}

# add the role to the identity the kubernetes cluster was assigned
resource "azurerm_role_assignment" "aks_to_acr" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}