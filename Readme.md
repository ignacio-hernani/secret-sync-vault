## Demo: Vault Secret Sync on Azure

**Context:**

The customer would like to see a demo of Secret Sync. They want to use this in Azure. So Azure as a target platform would be preferred. Things they would like to see:

1. Creating a Secret Sync destination.
2. Creating a secret and syncing it, including updates on the secret.

**Prerequisites**
- Azure Account: Access to an Azure subscription with permissions to create resources and IAM.
- HashiCorp Vault Enterprise: Needed for secret sync.
- Azure CLI: Installed for interacting with Azure resources.
- Vault CLI: Installed for interacting with Vault from the command line.
- Necessary Permissions: Ability to create service principals and assign roles in Azure.

**Additional Documentation**

https://developer.hashicorp.com/vault/docs/sync
https://developer.hashicorp.com/hcp/docs/vault-secrets/integrations/azure-key-vault
https://docs.microsoft.com/en-us/azure/key-vault/general/

---
## Steps

If you don't have Vault Enterprise deployed, you can do so with the following script to get started on local, using Docker and the license file you get from HashiCorp "vault.hclic".
```
export VAULT_PORT=8200
export VAULT_ADDR="http://127.0.0.1:${VAULT_PORT}"
export VAULT_TOKEN="root"

VAULT_LICENSE=$(cat "vault.hclic")
CONTAINER_NAME=vault-enterprise

#Check Docker installation
if [[ $(docker version) ]]
then
    echo "Docker version found: $(docker version)"
    # Perform additional actions here
else
    brew install --cask docker
fi
docker pull hashicorp/vault-enterprise
docker run -d --rm --name $CONTAINER_NAME --cap-add=IPC_LOCK \
-e "VAULT_DEV_ROOT_TOKEN_ID=${VAULT_TOKEN}" \
-e "VAULT_DEV_LISTEN_ADDRESS=:${VAULT_PORT}" \
-e "VAULT_LICENSE=${VAULT_LICENSE}" \
-e "VAULT_LOG_LEVEL=trace" \
-p $VAULT_PORT:$VAULT_PORT hashicorp/vault-enterprise:latest
```
On the terminal, check that the environment variables are set correctly, if not, then set them.
```
echo $VAULT_ADDR
echo $VAULT_TOKEN
```

Check that Vault is running.
```
vault status
```

---
**Azure Setup**

1. Set the environment variables for Azure and login to the Azure CLI:  
```
export AZURE_TENANT_ID=<TENANT_ID>
export AZURE_SUBSCRIPTION_ID=<SUBSCRIPTION_ID>

az login --tenant $AZURE_TENANT_ID
```
2. Create a resource group and a Key Vault in Azure.
```
# Variables
RESOURCE_GROUP="vault-demo-rg"
LOCATION="eastus"
KEY_VAULT_NAME="vault-demo-kv"

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Key Vault
az keyvault create --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION
```

3. Create an Azure Service Principal. Vault needs credentials to access Azure resources.
```
SP_NAME="vault-demo-sp"
az ad sp create-for-rbac --name $SP_NAME --role Contributor --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID

# Output will include appId, displayName, password, and tenant
```
**Store the output securely**, as it contains sensitive information. Example:  
```
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "vault-demo-sp",
  "password": "xxxxxxxxxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxxx-xxxxx-xxxxxxxxxxxx"
}
```

4. Set the next environment variables for Azure:  
```
export AZURE_CLIENT_ID=<appId>
export AZURE_CLIENT_SECRET=<password>
```

5. Assign the Key Vault Administrator role to the Service Principal in the Azure UI or CLI.
```
az role assignment create --assignee $AZURE_CLIENT_ID --role "Key Vault Administrator" --scope /subscriptions/$AZURE_SUBSCRIPTION_ID
```

---    
**Vault Setup**

6. Configure Secret Sync in Vault
```
# If you do not already have a KVv2 secret to sync, mount a new KVv2 secrets engine.
vault secrets enable -path='secret' kv-v2
```
Enable Secrets Sync in the Vault UI and create a destination with the following:
- Azure Key Vault URI
- Azure Tenant ID
- Azure Client ID
- Azure Client Secret

7. Create a secret:  
```
vault kv put secret/my-demo-secret foo="bar"
```
8. Activate sync in the Vault UI for the secret sync destination created before.

9. Check the current value of the secret both in Vault and in the Azure UI.
```
vault kv get secret/my-demo-secret
```
10. Change the value of the secret in Vault
```
vault kv put secret/my-demo-secret zip="zap"
```
11. Check the **updated** value of the secret both in Vault and in the Azure UI.
```
vault kv get secret/my-demo-secret
```
    You will be able to see the current version, as well as the previous versions of the secret.

---
## Conclusion
We've successfully:
1. Created a secret sync destination in Azure by configuring Vault to communicate with Azure Key Vault.
2. Created a secret in Vault and synced it to Azure Key Vault using Secrets Sync.
3. Updated the secret in Vault and showcased quick sync to Azure Key Vault.
By centralizing secrets in Vault, customers can enhance security controls, streamline secret rotation, and simplify secret access across different platforms and services.
