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
Write-Host "Waiting for 100 seconds..."
Start-Sleep -Seconds 100

# Recreate the containers after deletion
Write-Host "Recreating the containers..."
az storage container create --name $containerName --account-name $sourceStorageAccount --auth-mode login
az storage container create --name $containerName --account-name $destinationStorageAccount --auth-mode login

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

# Define the storage context for source and destination storage accounts
$srcStorageContext = New-AzStorageContext -StorageAccountName $sourceStorageAccount -StorageAccountKey $sourceStorageAccountKey
$destStorageContext = New-AzStorageContext -StorageAccountName $destinationStorageAccount -StorageAccountKey $destinationStorageAccountKey

for ($i = 1; $i -le 5; $i++) {
    $blobName = "file$i.txt"
    $sourceBlobUrl = "https://$sourceStorageAccount.blob.core.windows.net/$containerName/$blobName"
    $destinationBlobUrl = "https://$destinationStorageAccount.blob.core.windows.net/$containerName/$blobName"

    # Generate the SAS token for the source blob
    $srcBlobUri = New-AzStorageBlobSASToken -Container $containerName -Blob $blobName -Permission rt -ExpiryTime (Get-Date).AddDays(7) -Context $srcStorageContext -FullUri

    # Ensure the SAS URI was generated successfully
    if (-not $srcBlobUri) {
        Write-Error "Failed to generate SAS token for $blobName"
        continue
    }

    # Copy the blob to the destination container
    $destBlob = Copy-AzStorageBlob -AbsoluteUri $srcBlobUri -DestContainer $destinationContainerName -DestBlob $blobName -Context $destStorageContext

    Write-Host "Started copy for file$i.txt"
}

Write-Host "Blob migration completed successfully."
