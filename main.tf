provider "azuread" {
  # See https://registry.terraform.io/providers/hashicorp/azuread/latest/docs
}
provider "azurerm" {
  # See https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs for options on how to configure this provider.
  features {}
}
variable "key_vault_name" {
  description = "The name of the Key Vault to use."
}
variable "key_vault_location" {
  description = "The Azure region where the Key Vault is hosted."
}
variable "key_vault_resource_group_name" {
  description = "The name of the resource group where the Key Vault instance is part of."
}
data "azurerm_client_config" "current" {}
resource "azuread_application" "hcp_vault_secrets_integration" {
  display_name = "hcp-vault-secrets-sync"
}
resource "azuread_service_principal" "hcp_vault_secrets_integration" {
  client_id = azuread_application.hcp_vault_secrets_integration.client_id
}
resource "azuread_application_password" "hcp_vault_secrets_integration" {
  application_id = azuread_application.hcp_vault_secrets_integration.id
  end_date       = "2099-01-01T01:01:01Z" # Far-future expiration date, follow your organization's recommended policy
}
data "azurerm_resource_group" "hcp_vault_secrets_integration" {
  name     = var.key_vault_resource_group_name
}
data "azurerm_key_vault" "hcp_vault_secrets_integration" {
  name                = var.key_vault_name
  resource_group_name = data.azurerm_resource_group.hcp_vault_secrets_integration.name
}
resource "azurerm_key_vault_access_policy" "hcp_vault_secrets_integration" {
  key_vault_id = data.azurerm_key_vault.hcp_vault_secrets_integration.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_service_principal.hcp_vault_secrets_integration.object_id
  secret_permissions = [
    "Delete",
    "Set",
    "Purge",
  ]
}
output "key_vault_uri" {
  value = data.azurerm_key_vault.hcp_vault_secrets_integration.vault_uri
}
output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
output "client_id" {
  value = azuread_application.hcp_vault_secrets_integration.client_id
}
output "client_secret" {
  value     = azuread_application_password.hcp_vault_secrets_integration.value
  sensitive = true # use terraform output -json to see the sensitive value if running locally
}

