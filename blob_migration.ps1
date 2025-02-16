param (
    [string]$sourceStorageAccount = "ozstorageaccounta",
    [string]$destinationStorageAccount = "ozstorageaccountb",
    [string]$containerName = "mycontainer",
    [string]$resourceGroup = "OzResourceGroup"
)

# Define a writable directory (inside Azure DevOps agent working directory)
$tempDir = "$HOME/work/temp_blobs"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Authenticate to Azure using Managed Identity
# Write-Host "Authenticating with Azure Managed Identity..."
# az login --identity


# Delete the container if it exists, and recreate it
Write-Host "Deleting and recreating the container in both storage accounts..."
az storage container delete --name $containerName --account-name $sourceStorageAccount --auth-mode login
az storage container delete --name $containerName --account-name $destinationStorageAccount --auth-mode login

# Wait for a few seconds to ensure the container is fully deleted
Start-Sleep -Seconds 10

# Recreate the containers after deletion
Write-Host "Recreating the containers..."
az storage container create --name $containerName --account-name $sourceStorageAccount --auth-mode login
az storage container create --name $containerName --account-name $destinationStorageAccount --auth-mode login

# Create and upload 100 test blobs
Write-Host "Creating and uploading 100 blobs..."
for ($i = 1; $i -le 100; $i++) {
    $filePath = "$tempDir/file$i.txt"  # Using forward slash for Ubuntu compatibility
    "This is test file $i" | Out-File -FilePath $filePath

    az storage blob upload `
        --account-name $sourceStorageAccount `
        --container-name $containerName `
        --file $filePath `
        --name "file$i.txt" `
        --auth-mode login
}

# Set environment variables for the source and destination storage accounts
#$env:AZURE_STORAGE_ACCOUNT = $sourceStorageAccount
#$env:DESTINATION_STORAGE_ACCOUNT = $destinationStorageAccount

# Copy blobs from source storage account to destination storage account
Write-Host "Copying blobs from Storage Account A to B..."
az storage blob copy start-batch `
    --source-container $containerName `
    --destination-container $containerName `
    --account-name $destinationStorageAccount `
    --auth-mode login
Write-Host "Blob migration completed successfully."
