# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.shared_rg_name
  location = "westeurope"

  tags = {
      env = "shared"
  }
}

resource "azurerm_storage_account" "storage" {
  name                     = var.shared_sa_name
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"  
  account_replication_type = "LRS"

  tags = {
      env = "shared"
  }
}

resource "azurerm_storage_container" "tfstate-dev" {
  name                  = "tfstate-dev"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_container_registry" "acr" {
  name                = var.shared_acr_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  sku                 = "Basic"
 
  tags = {
      env = "shared"
  }
}
