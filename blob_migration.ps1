param (
    [string]$sourceStorageAccount = "ozstorageaccounta",
    [string]$destinationStorageAccount = "ozstorageaccountb",
    [string]$containerName = "mycontainer",
    [string]$resourceGroup = "OzResourceGroup",
    [int]$blobCount = 2,
    [int]$throttleLimit = 20
)

# Define a writable directory (inside Azure DevOps agent working directory)
$tempDir = "$HOME/work/temp_blobs"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "🔄 Deleting all blobs in the source storage and destination storage..."
az storage blob delete-batch --account-name $sourceStorageAccount --source $containerName --auth-mode login
az storage blob delete-batch --account-name $destinationStorageAccount --source $containerName --auth-mode login
Write-Host "✅ All blobs deleted."

# Create and upload 100 test blobs in parallel
Write-Host "Creating and uploading $blobCount blobs..."
1..$blobCount | ForEach-Object -Parallel {
    $filePath = "$using:tempDir/file$_"  # Using forward slash for Ubuntu compatibility
    "This is test file $_" | Out-File -FilePath $filePath

    try {
        $uploadResult = az storage blob upload `
            --account-name $using:sourceStorageAccount `
            --container-name $using:containerName `
            --file $filePath `
            --name "file$_.txt" `
            --auth-mode login --debug 2>&1 | Out-Null

        if ($uploadResult -match "error|failed") {
            Write-Host "⚠️ Warning: Error uploading file$_.txt: $uploadResult"
        } else {
            Write-Host "✅ Blob file$_.txt uploaded successfully"
        }
    } catch {
        Write-Host "⚠️ Exception: Failed to upload file$_.txt - $_"
    }
} -ThrottleLimit $throttleLimit  # Adjust concurrency as needed

Write-Host "📦 Copying blobs from Storage Account A to B..."

# Copy blobs in parallel
1..$blobCount | ForEach-Object -Parallel {
    try {
        Write-Host "🚀 Copying file$_.txt..."
        $copyResult = az storage blob copy start `
            --account-name $using:destinationStorageAccount `
            --destination-container $using:containerName `
            --destination-blob "file$_.txt" `
            --source-account-name $using:sourceStorageAccount `
            --source-container $using:containerName `
            --source-blob "file$_.txt" `
            --auth-mode login 2>&1

        if ($copyResult -match "error|failed") {
            Write-Host "⚠️ Warning: Error copying file$_.txt: $copyResult"
        } else {
            Write-Host "✅ Successfully copied file$_.txt"
        }
    } catch {
        Write-Host "⚠️ Exception: Failed to copy file$_.txt - $_"
    }
} -ThrottleLimit $throttleLimit

Write-Host "✅ Copy process completed."

