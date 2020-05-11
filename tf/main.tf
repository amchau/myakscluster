# https://github.com/terraform-providers/terraform-provider-azurerm
provider "azurerm" {
  version = "=2.9.0"
  features {}
}

provider "external" {
  version = "=1.2.0"
}

# + Terraform State in Blog storage account access (vnet peering + vnet link in private dns)

# + Azure DevOps interaction to update variable groups (ACR sp credentials and AKS sp credentials)?
# https://github.com/microsoft/terraform-provider-azuredevops/blob/master/examples/azdo-based-cicd/main.tf#L56
# Or alternatively changing this for Azure Key Vault? Maybe better?