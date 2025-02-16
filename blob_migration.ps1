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
Write-Host "Authenticating with Azure Managed Identity..."
az login --identity

# Create a container if it doesn't exist
Write-Host "Ensuring container exists in both storage accounts..."
az storage container create --name $containerName --account-name $sourceStorageAccount --auth-mode login
az storage container create --name $containerName --account-name $destinationStorageAccount --auth-mode login

# Delete all blobs in the container before uploading
Write-Host "Deleting existing blobs in the container..."
az storage blob delete-batch --account-name $sourceStorageAccount --source $containerName --auth-mode login

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

# Copy blobs from Storage Account A to B
Write-Host "Copying blobs from Storage Account A to B..."
az storage blob copy start-batch `
    --destination-container $containerName `
    --destination-account-name $destinationStorageAccount `
    --source-container $containerName `
    --source-account-name $sourceStorageAccount `
    --auth-mode login

Write-Host "Blob migration completed successfully."
