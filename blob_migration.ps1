param (
    [string]$sourceStorageAccount = "ozstorageaccounta",
    [string]$destinationStorageAccount = "ozstorageaccountb",
    [string]$containerName = "mycontainer",
    [string]$resourceGroup = "OzResourceGroup",
    [int]$blobCount = 100
)

# Define a writable directory (inside Azure DevOps agent working directory)
$tempDir = "$HOME/work/temp_blobs"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "🔄 Deleting all blobs in the source storage and destination storage..."
az storage blob delete-batch --account-name $sourceStorageAccount --source $containerName --auth-mode login
az storage blob delete-batch --account-name $destinationStorageAccount --source $containerName --auth-mode login
Write-Host "✅ All blobs deleted."

# Create and upload 100 test blobs
Write-Host "Creating and uploading 100 blobs..."
Write-Host "tempdir is $tempDir"
Write-Host "sourceStorageAccount is $sourceStorageAccount"
Write-Host "containerName is $containerName"


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
} -ThrottleLimit 5  # Adjust concurrency as needed


# for ($i = 1; $i -le $blobCount; $i++) {
#     $filePath = "$tempDir/file$i.txt"  # Using forward slash for Ubuntu compatibility
#     "This is test file $i" | Out-File -FilePath $filePath

#     try {
#         az storage blob upload `
#             --account-name $sourceStorageAccount `
#             --container-name $containerName `
#             --file $filePath `
#             --name "file$i.txt" `
#             --auth-mode login --debug 2>&1 | Out-Null

#         if ($LASTEXITCODE -eq 0) {
#             Write-Host "✅ Blob file$i.txt uploaded successfully"
#         } else {
#             Write-Host "⚠️ Warning: Error occurred uploading file$i.txt, but continuing..."
#         }
#     } catch {
#         Write-Host "⚠️ Warning: Exception occurred while uploading file$i.txt, but continuing..."
#     }
# }

Write-Host "📦 Copying blobs from Storage Account A to B..."

for ($i = 1; $i -le $blobCount; $i++) {
    try {
        Write-Host "🚀 Copying file$i.txt..."
        az storage blob copy start `
            --account-name $destinationStorageAccount `
            --destination-container $containerName `
            --destination-blob "file$i.txt" `
            --source-account-name $sourceStorageAccount `
            --source-container $containerName `
            --source-blob "file$i.txt" `
            --auth-mode login 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully copied file$i.txt"
        } else {
            throw "⚠️ Error copying file$i.txt"
        }
    } catch {
        Write-Host "⚠️ Warning: Failed to copy file$i.txt, but continuing..."
    }
}

Write-Host "✅ Copy process completed."
