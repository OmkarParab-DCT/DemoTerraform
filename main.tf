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