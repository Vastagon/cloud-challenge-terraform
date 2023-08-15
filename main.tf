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







# Create Resource Group for CosmosDB

resource "azurerm_resource_group" "cosmosdbrg"{
  name = "cosmosdbrg"
  location = "eastus"
}

resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "vastagoncosmosdb"
  location            = azurerm_resource_group.cosmosdbrg.location
  resource_group_name = azurerm_resource_group.cosmosdbrg.name
  offer_type          = "Standard"

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "eastus"
    failover_priority = 0
  }
  geo_location {
    location          = "westus"
    failover_priority = 1
  }

}

resource "azurerm_cosmosdb_sql_database" "cosmossqldatabase" {
  name                = "vastagonresumedb"
  resource_group_name = azurerm_cosmosdb_account.cosmosdb.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  throughput          = 400
}

resource "azurerm_cosmosdb_sql_container" "count-container" {
  name                  = "count-container"
  resource_group_name   = azurerm_cosmosdb_account.cosmosdb.resource_group_name
  account_name          = azurerm_cosmosdb_account.cosmosdb.name
  database_name         = azurerm_cosmosdb_sql_database.cosmossqldatabase.name
  partition_key_path    = "/definition/id"
  partition_key_version = 1
  throughput            = 400

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    included_path {
      path = "/included/?"
    }

    excluded_path {
      path = "/excluded/?"
    }
  }
  unique_key {
    paths = ["/definition/idlong", "/definition/idshort"]
  }
}





