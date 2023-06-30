provider "azurerm" {
  features {}
}

data "azurerm_subscription" "primary" {}

resource "azurerm_resource_group" "test-rg" {
  name     = var.rgname
  location = var.location
}

module "serviceprincipal" {
  source = "./modules/serviceprincipal"
  spnname = var.spnname

  depends_on = [ azurerm_resource_group.test-rg ]
}

data "azurerm_client_config" "example" {}

resource "azurerm_role_assignment" "example" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = module.serviceprincipal.service_principal_object_id

  depends_on = [ module.serviceprincipal ]
}

module "key_vault" {
  source = "./modules/keyvault"
  keyvaultname = var.keyvaultname
  location = var.location
  rgname = var.rgname

  depends_on = [ azurerm_resource_group.test-rg ]
}

resource "azurerm_role_assignment" "example_kv" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.example.object_id

  depends_on = [ module.key_vault ]
}

resource "azurerm_key_vault_secret" "kv_secret" {
  name         = module.serviceprincipal.client_id
  value        = module.serviceprincipal.client_secret
  key_vault_id = module.key_vault.keyvault_id

  depends_on = [ azurerm_role_assignment.example_kv ]
}

module "aks" {
  source = "./modules/aks"
  aks_cluster_name = var.aks_cluster_name
  location = var.location
  resource_group_name = var.rgname
  client_id = module.serviceprincipal.client_id
  client_secret = module.serviceprincipal.client_secret
  service_principal_name = var.spnname
  
  depends_on = [ azurerm_key_vault_secret.kv_secret ]
}

resource "local_file" "kubeconfig" {
  depends_on   = [module.aks]
  filename     = "./kubeconfig"
  content      = module.aks.config
  
}