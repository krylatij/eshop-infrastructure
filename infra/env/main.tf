# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0.0"
    }
  }

  backend "azurerm" {
    # shared variable can't be used here
      resource_group_name  = "rg-shared-paid"
      storage_account_name = "steshopsharedpaid"
      container_name       = "tfstate-dev"
      key                  = "terraform.tfstate"
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = "rg-${var.prefix}"
  location = var.location

  tags = {
      env = var.env
  }
}

provider "azuread" { 
}

resource "azuread_application" "application" {
  display_name = "Dabratsou ${var.app}"
  owners       = [data.azuread_client_config.current.object_id]
}



