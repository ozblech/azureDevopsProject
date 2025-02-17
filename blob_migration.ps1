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


# # Delete the container if it exists, and recreate it
# Write-Host "Deleting and recreating the container in both storage accounts..."
# az storage container delete --name $containerName --account-name $sourceStorageAccount --auth-mode login
# az storage container delete --name $containerName --account-name $destinationStorageAccount --auth-mode login

# # Wait for a few seconds to ensure the container is fully deleted
# Write-Host "Waiting for 100 seconds..."
# Start-Sleep -Seconds 100

# # Recreate the containers after deletion
# Write-Host "Recreating the containers..."
# az storage container create --name $containerName --account-name $sourceStorageAccount --auth-mode login
# az storage container create --name $containerName --account-name $destinationStorageAccount --auth-mode login

# Create and upload 100 test blobs
Write-Host "Creating and uploading 100 blobs..."
for ($i = 1; $i -le 5; $i++) {
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
# Copy each blob individually from Storage Account A to B
Write-Host "Copying blobs from Storage Account A to B..."

# Retrieve the storage account keys for both the source and destination storage accounts
$sourceStorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -AccountName $sourceStorageAccount)[0].Value
$destinationStorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -AccountName $destinationStorageAccount)[0].Value

# Create storage contexts for both the source and destination storage accounts
$sourceStorageContext = New-AzStorageContext -StorageAccountName $sourceStorageAccount -StorageAccountKey $sourceStorageAccountKey
$destinationStorageContext = New-AzStorageContext -StorageAccountName $destinationStorageAccount -StorageAccountKey $destinationStorageAccountKey

# List all blobs in the source container
$blobs = Get-AzStorageBlob -Container $sourceContainerName -Context $sourceStorageContext

# Loop through each blob and copy it to the destination container
foreach ($blob in $blobs) {
    Write-Host "Copying blob: $($blob.Name)"

    # Copy the blob to the destination container
    Start-AzStorageBlobCopy -SrcBlob $blob.Name -SrcContainer $sourceContainerName -Context $sourceStorageContext `
                             -DestBlob $blob.Name -DestContainer $destinationContainerName -DestContext $destinationStorageContext

    # Wait for the copy operation to complete (optional)
    while ((Get-AzStorageBlobCopyState -Blob $blob.Name -Container $destinationContainerName -Context $destinationStorageContext).Status -eq "Pending") {
        Write-Host "Waiting for blob copy to complete..."
        Start-Sleep -Seconds 5
    }

    Write-Host "Finished copying blob: $($blob.Name)"
}

Write-Host "Blob migration completed successfully."
