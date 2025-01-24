#Author         :   Jesus Lopez Mesia
#Linkedin       :   https://www.linkedin.com/in/susejzepol/
#Created date   :   January-16-2025
#Modified date  :   January-23-2025
#Script Purpose :   This script deploys a storage account with a static web page.

#JLopez: Import the module "print-message-custom-v1.psm1".
if($pwd.path -like "*Scripts"){
    $root = "."
}else {
    $root = ".\Scripts"
}
Import-Module  "$root\utilities\print-message-custom-v1.psm1"

Write-Host "$(get-date)" -BackgroundColor DarkGreen

#JLopez: Internal variables
$date                       = $(get-date -format "yyyyMMdd")
$project                    = "IP5_1_"      + $date
$location                   = "West US"
$rg                         = "rg_"         + $project 
$storage_account            = "st"          + $project.Replace("_","").ToLower()


printMyMessage -message "Starting with the resource groups validations." -c 0

    checkMyResourceGroup -rg $rg -l $location -t Project=$project

printMyMessage -message "Resource groups validations done!."

printMyMessage -message "Creating a new storage account ($storage_account)." -c 0

    Write-Host "Setting the default resource group to $rg." -BackgroundColor DarkGreen
    az configure --defaults group=$rg
    #JLopez-20250116: In order to create a static web page in the storage account,
    #                 you need to create a general purpose v2 or BlobStorage storage account.
    #                 Also, you need to enable the static website feature.
    az storage account create `
        --name $storage_account `
        --location $location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --access-tier Hot `
        --tags Project=$project `
        --allow-blob-public-access true
    
    Write-Host "Enabling the static website feature." -BackgroundColor DarkGreen
                            az storage blob service-properties update `
                                --account-name $storage_account `
                                --static-website `
                                --index-document index.html `
                                --404-document error.html `
                                --output none

    $primaryEndpoint = $(
                            az storage account show --name $storage_account `
                                --query "primaryEndpoints.web" `
                                --output tsv
                        )

printMyMessage -message "The storage account ($storage_account) was deployed."

printMyMessage -message "Uploading the webside files into the $web container." -c 0
    
    az storage blob upload-batch `
        --account-name $storage_account `
        --destination "$web" `
        --source ".\Utilities\" `
        --pattern "*.html"	

printMyMessage -message "Webside files deployed into the $web container."
Write-Host "The endpoint for the web site app is: $primaryEndpoint" -BackgroundColor DarkYellow