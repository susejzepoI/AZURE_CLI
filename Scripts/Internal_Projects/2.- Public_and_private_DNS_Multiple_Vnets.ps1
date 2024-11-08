#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      November-05-2024
#Modified date:     November-05-2024

#JLopez: Import the module "print-message-custom-v1.psm1".
if($pwd.path -like "*Scripts"){
    $root = "."
}else {
    $root = ".\Scripts"
}
Import-Module  "$root\utilities\print-message-custom-v1.psm1"

Write-Host "$(get-date)" -BackgroundColor DarkGreen

#JLopez: Internal variables
$date                   = $(get-date -format "MMdd")
$project                = "IP2" + $date
$rg                     = "rg_" + $project 
$vnet                   = "vnet_" + $project
$vnet1_range            = "10.1.0.0/16"
$subnet1_range          = "10.1.0.0/24"
$vnet2_range            = "10.2.0.0/16"
$subnet2_range          = "10.2.0.0/24"
$vnet3_range            = "10.3.0.0/16"
$subnet3_range          = "10.3.0.0/24"
$vnet4_range            = "10.4.0.0/16"
$subnet4_range          = "10.4.0.0/24"


printMyMessage -message "Starting with the resource group validation." -c 0
checkMyResourceGroup -rg $rg -s $s -l $l -t Project=$project

Write-Host "Setting the default resource group to $rg." -BackgroundColor DarkGreen
az configure --defaults group=$rg

printMyMessage -message "Resource group validation done!."

printMyMessage -message "Starting with the virtual networks creation." -c 0

for ($i = 1; $i -le 4; $i++) {
    <# Action that will repeat until the condition is met #>
}

printMyMessage -message "All virtual networks were deployed!."