param (
    [string]$sourceStorageAccount = "ozstorageaccounta",
    [string]$destinationStorageAccount = "ozstorageaccountb",
    [string]$containerName = "mycontainer",
    [string]$resourceGroup = "OzResourceGroup"
)

# Authenticate to Azure using Managed Identity
Write-Host "Authenticating with Azure Managed Identity..."
az login --identity

# Get the access token for storage
$identityToken = az account get-access-token --resource https://storage.azure.com --query accessToken --output tsv

# Create a container if it doesn't exist
Write-Host "Ensuring container exists in both storage accounts..."
az storage container create --name $containerName --account-name $sourceStorageAccount --auth-mode login
az storage container create --name $containerName --account-name $destinationStorageAccount --auth-mode login

# Generate and upload 100 blobs
Write-Host "Creating and uploading 100 blobs..."
for ($i = 1; $i -le 100; $i++) {
    $fileName = "file$i.txt"
    $filePath = "$env:TEMP\$fileName"

    # Create dummy file
    "This is test file $i" | Out-File -FilePath $filePath

    # Upload to source storage account using Managed Identity authentication
    az storage blob upload --account-name $sourceStorageAccount --container-name $containerName --file $filePath --name $fileName --auth-mode login

    Write-Host "Uploaded $fileName to $sourceStorageAccount"
}

# Copy Blobs from Storage Account A to Storage Account B
Write-Host "Copying blobs from $sourceStorageAccount to $destinationStorageAccount..."
$blobs = az storage blob list --container-name $containerName --account-name $sourceStorageAccount --auth-mode login --query "[].name" --output tsv

foreach ($blob in $blobs) {
    $url = az storage blob url --container-name $containerName --account-name $sourceStorageAccount --name $blob --output tsv
    az storage blob copy start --destination-container $containerName --destination-blob $blob --account-name $destinationStorageAccount --auth-mode login --source-uri $url
    Write-Host "Copied $blob from $sourceStorageAccount to $destinationStorageAccount"
}

Write-Host "Blob migration completed using Managed Identity."
