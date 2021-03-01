#!/bin/bash

set -euo pipefail

# Make sure these values are correct for your environment
resourceGroup="dm-dynamic-schema"
appName="dm-dynamic-schema"
location="WestUS2" 

# Change this if you are using your own github repository
gitSource="https://github.com/Azure-Samples/azure-sql-db-dynamic-schema.git"

# Azure configuration
FILE=".env"
if [[ -f $FILE ]]; then
	echo "loading from .env" 
    export $(egrep . $FILE | xargs -n1)
else
	cat << EOF > .env
ConnectionStrings__AzureSQL="Server=.database.windows.net;Database=;UID=;PWD="
EOF
	echo "Enviroment file not detected."
	echo "Please configure values for your environment in the created .env file"
	echo "and run the script again."
	echo "ConnectionStrings__AzureSQL: connection string to connect to desired Azure SQL database"
	exit 1
fi

# Make sure connection string variable is set
if [[ -z "${ConnectionStrings__AzureSQL:-}" ]]; then
    echo "ConnectionStrings__AzureSQL not found."
	exit 1;
fi

echo "Creating Resource Group...";
az group create \
    -n $resourceGroup \
    -l $location

echo "Creating Application Service Plan...";
az appservice plan create \
    -g $resourceGroup \
    -n "windows-plan" \
    --sku B1     

echo "Creating Web Application...";
az webapp create \
    -g $resourceGroup \
    -n $appName \
    --plan "windows-plan" \
    --runtime "DOTNETCORE|3.1" \
    --deployment-source-url $gitSource \
    --deployment-source-branch main

echo "Configuring Connection String...";
az webapp config connection-string set \
    -g $resourceGroup \
    -n $appName \
    --settings AzureSQL=$ConnectionStrings__AzureSQL \
    --connection-string-type=SQLAzure

echo "Done."