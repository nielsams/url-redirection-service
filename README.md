# URL Redirection Service

This is a simple proof of concept app that redirects short URLs to long URLs. As an example, [go.nielsb.net/url-redirect](https://go.nielsb.net/url-redirect) points to this page.

It works by having a lightweight app that processes incoming requests, takes the URL path and matches it against an Azure Table Storage table to get the redirect URL and sends an HTTP 302 header back to the requestor. 

The infrastructure consists of an Azure Container behind Azure Frontdoor (for managed SSL certificate and HTTP->HTTPS redirection) and is deployed through an ARM template. The build and deploy process is orchestrated by a Github workflow and is completely portable by changing the values of the Github Secrets involved. 

The setup assumes an existing Container Registry and an account to access it, as well as an Azure Subscription.


## Running locally

- Clone the repo
- From inside the app folder:

```
docker build -t "redirector" .
docker run -p 8080:8080 -d -e STORAGE_CONNECTION_STRING="[storage connection string]" -e STORAGE_TABLE_NAME=redirecturls redirector
```

There will need to be a storage account with a URL table in place for this to work. Look at step 6 below for more info on that. 

## Building your own

### Step 1: Fork the repository

### Step 2: Set up access to an Azure subscription
Create a new resource group:
```
az group create --name myredirector --location westeurope
```
Create a service principal and assign access:
```
# Update values in the cli command below to create a service principal and assign permissions on the resource group and the ACR:

az ad sp create-for-rbac --name "app-myredirector" --sdk-auth --role contributor --scopes \
/subscriptions/[SUBSCRIPTION ID]/resourceGroups/myredirector \
/subscriptions/[SUBSCRIPTION ID]/resourceGroups/[ACR RESOURCE GROUP]/providers/Microsoft.ContainerRegistry/registries/[ACR NAME]
```
Copy the entire json body from the output into a Github secret called AZURE_CREDENTIALS.


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

### Step 4: Set a CNAME record on your domain
For the custom domain you want to use, set a CNAME record pointing to the Azure Frontdoor instance. This will be [nameprefix]fd.azurefd.net

| Record | Value |
| ------ | ----- |
| go     | myredirfd.azurefd.net |

This step must be completed before the Frontdoor resource can be deplyed. 

### Step 5: Trigger the workflow. 
From the 'Actions' menu, start the <i>AzureDeploy</i> workflow.

### Step 6: Add URLs
In the <i>redirectionurls</i> table add a new record. Set partitionkey and rowkey to the short url you want and add a column <i>redirecturl</i> with the full URL value. For example, to redirect go.mydomain.com/pizza to www.myfavoritepizza.com, enter:

| PartitionKey | RowKey | redirecturl |
| ------------ | ------ | ----------- |
| pizza | pizza | https://www.myfavoritepizza.com |