# URL Redirection Service

## Running locally

- Clone the repo
- From inside the app folder:

```
docker build -t "redirector" .
docker run -p 8080:8080 -d -e STORAGE_CONNECTION_STRING="[storage connection string]" -e STORAGE_TABLE_NAME=redirecturls redirector
```

## Building your own

### Step 1: Fork the repository

### Step 2: Set up access to an Azure subscription
Create a new resource group:
```
az group create --name myredirector --location westeurope
```
Create a service principal and assign access:
```
# Enter your subscription id in the cli command below:
az ad sp create-for-rbac --name "app-myredirector" --sdk-auth --role contributor --scopes /subscriptions/[subscription id]/resourceGroups/myredirector
```
Copy the entire json body from the output into a Github secret called AZURE_CREDENTIALS.

TODO assign permission on ACR

### Step 3: Set up Github secrets
Add the following Github secrets to your fork:
| Secret                      | Value |
| --------------------------- | ----- |
| AZURE_CREDENTIALS           | The json body from the command above |
| AZUREDEPLOY_CUSTOM_DOMAIN   | The custom domain for your service, e.g. go.yourdomain.com
| AZUREDEPLOY_NAMEPREFIX      | Unique name prefix for your Azure resources, e.g. myredirabc
| AZUREDEPLOY_RESOURCEGROUP   | The name of the resource group created earlier
| AZUREDEPLOY_SUBSCRIPTION    | ID of the subscription that holds the resource group
| AZURE_ACR_PASSWORD          | Service Principal password for ACR access (e.g. secret from the json credential body ealier)
| AZURE_ACR_REGISTRY          | Name of the ACR, e.g. myacr.azurecr.io
| AZURE_ACR_USERNAME          | Service Principal username for ACR access (e.g. clientid from the json credential body ealier)
| ' | |

### Step 4: Trigger the workflow. 
