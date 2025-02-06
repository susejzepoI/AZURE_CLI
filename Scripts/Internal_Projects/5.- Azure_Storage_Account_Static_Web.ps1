#Author         :   Jesus Lopez Mesia
#Linkedin       :   https://www.linkedin.com/in/susejzepol/
#Created date   :   January-16-2025
#Modified date  :   February-05-2025
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
$project                    = "IP5_2_"      + $date
$location                   = "West US"
$rg                         = "rg_"         + $project 
$storage_account            = "st"          + $project.Replace("_","").ToLower()
$dns_name                   = "clopez.com"

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
        --destination '$web' `
        --source ".\Utilities\" `
        --pattern "*.html" `
        --overwrite true `
        --metadata Project=$project

    az storage blob upload-batch `
        --account-name $storage_account `
        --destination '$web' `
        --source ".\Utilities\" `
        --pattern "*.css" `
        --overwrite true `
        --metadata Project=$project

printMyMessage -message "Webside files deployed into the $web container."

printMyMessage -message "Creating a Public DNS to create an alias for the webside." -c 0
    
    az network dns zone create `
        --name $dns_name `
        --tags Project=$project

    $FQDN = $primaryEndpoint -replace "https://","" -Replace"/$",""
    #Write-Host "$FQDN" 
    az network dns record-set cname set-record `
        --zone-name $dns_name `
        --record-set-name "www" `
        --cname $FQDN
    
    #JLopez-20250206: This section has been commented because I don't buy the domain name in an external provider.
    # $cname = "www." + $dns_name
    # Write-Host "Associating the custom domain with the Azure storage account." -BackgroundColor DarkGreen
    # az storage account update `
    #     --name $storage_account `
    #     --custom-domain $cname 

printMyMessage -message "Public DNS deployed."
Write-Host "The endpoint for the web site app is: $primaryEndpoint" -BackgroundColor DarkYellow
Write-Host "The custom domain for the web site app is: $cname" -BackgroundColor DarkYellow