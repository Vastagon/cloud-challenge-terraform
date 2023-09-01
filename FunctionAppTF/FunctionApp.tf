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
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
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





# Function App

resource "azurerm_storage_account" "functionappstorage" {
  name                     = "vastagonfunctionapp"
  resource_group_name      = azurerm_resource_group.tf-functionapp-cosmosdb-rg.name
  location                 = azurerm_resource_group.tf-functionapp-cosmosdb-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
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

resource "azurerm_linux_function_app" "linux-function-app" {
  name                = "vastagon-function-app"
  resource_group_name = azurerm_resource_group.tf-functionapp-cosmosdb-rg.name
  location            = azurerm_resource_group.tf-functionapp-cosmosdb-rg.location

  storage_account_name       = azurerm_storage_account.functionappstorage.name
  storage_account_access_key = azurerm_storage_account.functionappstorage.primary_access_key
  service_plan_id            = azurerm_service_plan.app-service-plan.id

  app_settings = {
    "CosmosDbConnectionString"                 = "AccountEndpoint=${azurerm_cosmosdb_account.cosmosdb.endpoint};AccountKey=${azurerm_cosmosdb_account.cosmosdb.primary_key};",
    "CosmosDB"                                 = "AccountEndpoint=${azurerm_cosmosdb_account.cosmosdb.endpoint};AccountKey=${azurerm_cosmosdb_account.cosmosdb.primary_key};",
    "WEBSITE_CONTENTSHARE"                     = "${azurerm_storage_account.functionappstorage.name}",
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.functionappstorage.name};AccountKey=${azurerm_storage_account.functionappstorage.primary_access_key};EndpointSuffix=core.windows.net"
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


resource "azurerm_function_app_function" "azurerm-function-app-function" {
  name            = "vastagon-function-app-function"
  function_app_id = azurerm_linux_function_app.linux-function-app.id
  language        = "Python"

  file {
    name    = "__init__.py"
    content = file("FunctionTriggers/HttpCountTrigger/__init__.py")
  }

  file {
    name    = "__init__.py"
    content = file("FunctionTriggers/HttpCountTrigger/host.json")
  }

  test_data = jsonencode({
    "name" = "Azure"
  })

  config_json = jsonencode({
    "bindings" = [
      {
        "authLevel" : "function",
        "type" : "httpTrigger",
        "direction" : "in",
        "name" : "req",
        "methods" : [
          "get",
          "post"
        ]
      },
      {
        "name" : "inputDocument",
        "type" : "cosmosDB",
        "databaseName" : "vastagonresumedb",
        "collectionName" : "count-container",
        "connectionStringSetting" : "CosmosDbConnectionString",
        "direction" : "in"
      },
      {
        "name" : "$return",
        "type" : "cosmosDB",
        "databaseName" : "vastagonresumedb",
        "collectionName" : "count-container",
        "createIfNotExists" : true,
        "connectionStringSetting" : "CosmosDbConnectionString",
        "direction" : "out"
      }
    ]
  })
}



