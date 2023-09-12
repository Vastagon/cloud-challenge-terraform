# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.43.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  subscription_id = "e213a1d7-ec53-43b8-8c56-637302aff6d4"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
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

resource "azurerm_storage_blob" "website-html" {
  name                   = "resume.html"
  storage_account_name   = azurerm_storage_account.static-storage-account.name
  storage_container_name = "$web"
  content_type           = "text/html"
  type                   = "Block"
  source                 = "./Resume Code/resume.html"
}
resource "azurerm_storage_blob" "website-css" {
  name                   = "resume.css"
  storage_account_name   = azurerm_storage_account.static-storage-account.name
  storage_container_name = "$web"
  content_type           = "text/css"
  type                   = "Block"
  source                 = "./Resume Code/resume.css"
}
resource "azurerm_storage_blob" "website-js" {
  name                   = "resume.js"
  storage_account_name   = azurerm_storage_account.static-storage-account.name
  storage_container_name = "$web"
  content_type           = "text/js"
  type                   = "Block"
  source                 = "./Resume Code/resume.js"
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

  origin {
    name      = "VastagonCDNEndpoint"
    host_name = "tfwebsitesa.z13.web.core.windows.net"
  }
}






# CosmosDB
resource "azurerm_resource_group" "tf-functionapp-cosmosdb-rg" {
  name     = "tf-functionapp-cosmosdb-rg"
  location = "eastus"
}

resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "vastagoncosmosdb"
  location            = azurerm_resource_group.tf-functionapp-cosmosdb-rg.location
  resource_group_name = azurerm_resource_group.tf-functionapp-cosmosdb-rg.name
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



variable "functionapp" {
  type    = string
  default = "./FunctionTriggers/FunctionTriggers.zip"
}

# Function App
resource "azurerm_storage_account" "functionappstorage" {
  name                     = "vastagonfunctionapp"
  resource_group_name      = azurerm_resource_group.tf-functionapp-cosmosdb-rg.name
  location                 = azurerm_resource_group.tf-functionapp-cosmosdb-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "function-app-container" {
  name                  = "function-releases"
  storage_account_name  = azurerm_storage_account.functionappstorage.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "function-app-blob" {
  name                   = "functionapp.zip"
  storage_account_name   = azurerm_storage_account.functionappstorage.name
  storage_container_name = azurerm_storage_container.function-app-container.name
  type                   = "Block"
  source                 = var.functionapp
}

resource "azurerm_service_plan" "app-service-plan" {
  name                = "linux-app-service-plan"
  resource_group_name = azurerm_resource_group.tf-functionapp-cosmosdb-rg.name
  location            = azurerm_resource_group.tf-functionapp-cosmosdb-rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_application_insights" "application-insights" {
  name                = "tf-resume-appinsights"
  location            = azurerm_resource_group.tf-functionapp-cosmosdb-rg.location
  resource_group_name = azurerm_resource_group.tf-functionapp-cosmosdb-rg.name
  application_type    = "Node.JS"
}

data "azurerm_storage_account_sas" "sas" {
  connection_string = azurerm_storage_account.functionappstorage.primary_connection_string
  https_only        = true
  start             = "2020-07-10"
  expiry            = "2024-12-31"
  resource_types {
    object    = true
    container = false
    service   = false
  }
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

data "azurerm_function_app_host_keys" "get-api-url" {
  name                = azurerm_linux_function_app.linux-function-app.name
  resource_group_name = azurerm_linux_function_app.linux-function-app.resource_group_name

  depends_on = [azurerm_linux_function_app.linux-function-app]
}

resource "azurerm_linux_function_app" "linux-function-app" {
  name                = "vastagon-function-app"
  resource_group_name = azurerm_resource_group.tf-functionapp-cosmosdb-rg.name
  location            = azurerm_resource_group.tf-functionapp-cosmosdb-rg.location

  storage_account_name       = azurerm_storage_account.functionappstorage.name
  storage_account_access_key = azurerm_storage_account.functionappstorage.primary_access_key
  service_plan_id            = azurerm_service_plan.app-service-plan.id

  app_settings = {
    "https_only"                               = true,
    "CosmosDbConnectionString"                 = "AccountEndpoint=${azurerm_cosmosdb_account.cosmosdb.endpoint};AccountKey=${azurerm_cosmosdb_account.cosmosdb.primary_key};",
    "CosmosDB"                                 = "AccountEndpoint=${azurerm_cosmosdb_account.cosmosdb.endpoint};AccountKey=${azurerm_cosmosdb_account.cosmosdb.primary_key};",
    "WEBSITE_CONTENTSHARE"                     = "${azurerm_storage_account.functionappstorage.name}",
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.functionappstorage.name};AccountKey=${azurerm_storage_account.functionappstorage.primary_access_key};EndpointSuffix=core.windows.net",
    "WEBSITE_RUN_FROM_PACKAGE"                 = "https://${azurerm_storage_account.functionappstorage.name}.blob.core.windows.net/${azurerm_storage_container.function-app-container.name}/${azurerm_storage_blob.function-app-blob.name}${data.azurerm_storage_account_sas.sas.sas}"
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
    cors {
      allowed_origins = [
        "https://VastagonCDNEndpoint.azureedge.net",
        "https://portal.azure.com"
      ]
    }
    application_insights_key               = azurerm_application_insights.application-insights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.application-insights.connection_string
  }
}
