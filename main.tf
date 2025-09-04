terraform {
  required_version = ">= 1.12"

  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# Generate random password for SQL
resource "random_password" "sql_admin" {
  length  = 16
  special = true
}

# Local values
locals {
  tags = {
    project    = var.project_name
    purpose    = "datadog-learning"
    managed_by = "terraform"
    owner      = "scott-mccracken"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_code}-rg-monitoring"
  location = var.location
  tags     = local.tags
}

# App Service Plan (Linux, Free tier)
resource "azurerm_service_plan" "main" {
  name                = "${var.project_code}-plan-web"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "F1" # Free tier
  tags                = local.tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "${var.project_code}stlogs"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.tags
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "${var.project_code}-sql-server"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sql_admin.result

  tags = local.tags
}

# SQL Database (Serverless for cost optimization)
resource "azurerm_mssql_database" "main" {
  name      = "${var.project_code}-db-users"
  server_id = azurerm_mssql_server.main.id
  collation = "SQL_Latin1_General_CP1_CI_AS"

  # Serverless configuration for cost optimization
  sku_name                    = "GP_S_Gen5_1"
  min_capacity                = 0.5
  max_size_gb                 = 2
  auto_pause_delay_in_minutes = 60 # Auto-pause after 1 hour

  tags = local.tags
}

# SQL Firewall rule to allow Azure services
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Application Insights (for comparison with Datadog)
resource "azurerm_application_insights" "main" {
  name                = "${var.project_code}-ai-monitoring"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  tags = local.tags
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = "${var.project_code}-app-api"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      python_version = "3.11"
    }
    always_on = false # defaults to true, not supported in Free tier
  }

  # Enable logging
  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    application_logs {
      file_system_level = "Information"
    }
  }

  app_settings = {
    # Database connection
    "DATABASE_URL" = "mssql+pyodbc://${azurerm_mssql_server.main.administrator_login}:${random_password.sql_admin.result}@${azurerm_mssql_server.main.fully_qualified_domain_name}:1433/${azurerm_mssql_database.main.name}?driver=ODBC+Driver+18+for+SQL+Server&encrypt=yes&trustServerCertificate=no"

    # Application Insights
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string

    # Storage Account
    "STORAGE_CONNECTION_STRING" = azurerm_storage_account.main.primary_connection_string

    # Python-specific settings
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "ENABLE_ORYX_BUILD"              = "true"
  }

  tags = local.tags
}