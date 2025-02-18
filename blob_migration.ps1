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
Write-Host "tempdir is $tempDir"
Write-Host "sourceStorageAccount is $sourceStorageAccount"
Write-Host "containerName is $containerName"
for ($i = 1; $i -le 5; $i++) {
    $filePath = "$tempDir/file$i.txt"  # Using forward slash for Ubuntu compatibility
    "This is test file $i" | Out-File -FilePath $filePath

    try {
        az storage blob upload `
            --account-name $sourceStorageAccount `
            --container-name $containerName `
            --file $filePath `
            --name "file$i.txt" `
            --auth-mode login --debug 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Blob file$i.txt uploaded successfully"
        } else {
            Write-Host "⚠️ Warning: Error occurred uploading file$i.txt, but continuing..."
        }
    } catch {
        Write-Host "⚠️ Warning: Exception occurred while uploading file$i.txt, but continuing..."
    }
}

# Copy each blob individually from Storage Account A to B
Write-Host "Copying blobs from Storage Account A to B..."
for ($i = 1; $i -le 5; $i++) {
    az storage blob copy start `
        --account-name $destinationStorageAccount `
        --destination-container $containerName `
        --destination-blob "file$i.txt" `
        --source-account-name $sourceStorageAccount `
        --source-container $containerName `
        --source-blob "file$i.txt" `
        --auth-mode login
        Write-Host "Copying file $i"
}

Write-Host "Blob migration completed successfully."
