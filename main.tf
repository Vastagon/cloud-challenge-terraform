# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  subscription_id = "e213a1d7-ec53-43b8-8c56-637302aff6d4"
  features {}
}

resource "azurerm_resource_group" "tf-website-rg" {
  name     = "tf-website-rg"
  location = "eastus"
}

# Create storage container for static website
resource "azurerm_storage_account" "static-storage-account" {
  name                     = "tfwebsitesa"
  resource_group_name      = azurerm_resource_group.tf-website-rg.name
  location                 = azurerm_resource_group.tf-website-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"


  static_website {
    index_document = "resume.html"
  }
}




# Create CDN for static website
resource "azurerm_cdn_profile" "websitecdn" {
  name                = "resumeCDN"
  location            = azurerm_resource_group.tf-website-rg.location
  resource_group_name = azurerm_resource_group.tf-website-rg.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "cdnendpoint" {
  name                = "VastagonCDNEndpoint"
  profile_name        = azurerm_cdn_profile.websitecdn.name
  location            = azurerm_resource_group.tf-website-rg.location
  resource_group_name = azurerm_resource_group.tf-website-rg.name

  origin_host_header = "tfwebsitesa.z13.web.core.windows.net"

  origin{
    name      = "VastagonCDNEndpoint"
    host_name = "tfwebsitesa.z13.web.core.windows.net"
  }
}







# Create a virtual network
# resource "azurerm_virtual_network" "vnet" {
#  name                = "myTFVnet"
#  address_space       = ["10.0.0.0/16"]
#  location            = "westus2"
#  resource_group_name = azurerm_resource_group.tf-website-rg.name
# }

