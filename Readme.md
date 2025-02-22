# Azure DevOps Pipeline README

This pipeline is designed to deploy resources to Azure, manage storage accounts, perform a blob migration, and set up alerting for resource usage. Below are the steps you need to follow to customize and run this pipeline:

## Prerequisites

1. **Azure DevOps Service Connection**:
   - Ensure you have a valid Azure DevOps service connection to your Azure subscription. This should be set as `MyAzureServiceConnection`. You can create one in the Azure DevOps UI under `Project Settings > Service Connections`.
   
2. **SSH Service Connection**:
   - You need to create an SSH service connection that connects to your VM using a private SSH key. Set this connection as `sshServiceConnection`. 
   - The private key file should be referenced by setting the correct path in the `privateKey` parameter (e.g., `~/.ssh/id_ed25519`).

3. **Email Address**:
   - Set your email address in the `AdminEmail` parameter. This email will be used for alert notifications.

4. **Variable Group in Azure DevOps**:
   - This pipeline uses a **Variable Group** named **azureLogin**.
   - The variable group must contain the following variables:
     - `AZURE_APP_ID`
     - `AZURE_OBJECT_ID`
     - `AZURE_PASSWORD`
     - `AZURE_TENANT_ID`
     - `SUBSCRIPTION_ID`
   - Ensure these variables are properly defined in **Azure DevOps > Library > Variable Groups** and linked to this pipeline.

## Files Included in the Repository

This repository contains the following files:

- `blob_migration.ps1` – PowerShell script for migrating blobs between storage accounts.
- `linux-vm-parameters.json` – Parameters for the Linux VM deployment.
- `linux-vm.json` – ARM template for deploying the Linux VM.
- `network-setup-parameters.json` – Parameters for setting up network resources.
- `network-setup.json` – ARM template for setting up network resources.
- `resource-group-parameters.json` – Parameters for creating the resource group.
- `resource-group.json` – ARM template for creating the resource group.
- `storage-accounts-parameters.json` – Parameters for creating storage accounts.
- `storage-accounts.json` – ARM template for creating storage accounts.

## Parameters to Edit

### 1. **Resource Group Name**
   - The resource group name can be changed by editing the `resourceGroup` parameter in the pipeline:
     ```yaml
     - name: resourceGroup
       value: 'OzResourceGroup'  # Change this to your desired resource group name
     ```

### 2. **SSH Service Connection**
   - You need to create a new SSH service connection in Azure DevOps, then update the `sshServiceConnection` parameter with the name of your service connection:
     ```yaml
     - name: sshServiceConnection
       value: 'MyVM_SSH_Connection'  # Change this to your SSH service connection name
     ```
   
### 3. **Private Key Path**
   - The private key used for SSH authentication should be set in the `privateKey` parameter. Make sure the key is stored in the specified path:
     ```yaml
     - name: privateKey
       value: '~/.ssh/id_ed25519'  # Ensure this path points to your private key
     ```

### 4. **Admin Email**
   - Set your email address for alert notifications:
     ```yaml
     - name: AdminEmail
       value: 'ozblech87@gmail.com'  # Change this to your email address
     ```

### 5. **Azure Subscription Connection**
   - The `azureSubscription` parameter is tied to your Azure DevOps service connection. Make sure it points to the correct subscription:
     ```yaml
     - name: azureSubscription
       value: 'MyAzureServiceConnection'  # Change this to your Azure service connection name
     ```

## Pipeline Overview

This pipeline is divided into three jobs:

### 1. **CreateManagedIdentity**
   - Ensures that the specified resource group exists.
   - Creates a user-assigned managed identity in the resource group.
   - Assigns the "Storage Blob Data Contributor" role to the managed identity.

### 2. **DeployResources**
   - Registers the `Microsoft.Storage` provider for the resource group.
   - Deploys network resources, virtual machines, and storage accounts using ARM templates and parameters.

### 3. **BlobMigration**
   - Copies a PowerShell script (`blob_migration.ps1`) to the VM.
   - Executes the script on the VM to perform the blob migration.
   - Sets up a public DNS name for the VM and assigns required permissions to the managed identity.

### 4. **CreateAlert**
   - Creates action groups and metrics alerts to monitor the usage of storage accounts and VM CPU usage.
   - Sends email notifications to the specified email address when thresholds are exceeded.

## How to Use

1. Clone or download this pipeline YAML file.
2. Customize the parameters as mentioned in the sections above.
3. Commit the file to your Azure DevOps repository.
4. Ensure that all required Azure DevOps Service Connections are set up.
5. Link the **Variable Group** named `Variable` to this pipeline.
6. Trigger the pipeline manually or on push to the `main` branch.

## Notes

- The pipeline assumes that SSH access to the VM is set up using a public/private key pair.
- Ensure that the `blob_migration.ps1` script exists in the repository and is accessible to the pipeline.
- Ensure that the VM has the necessary firewall settings to allow SSH connections.

## Troubleshooting

- If you encounter issues with SSH or Azure CLI commands, verify the service connections and credentials.
- Ensure that the VM is running and accessible for script execution.

For more details on Azure DevOps Pipelines, refer to the [official documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/?view=azure-pipelines&tabs=yaml).
