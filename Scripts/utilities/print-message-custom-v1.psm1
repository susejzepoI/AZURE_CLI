#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      September-06-2024
#Modified date:     September-06-2024

#JLopez-20240906: Funtion to print a custom message in console.
function printMyMessage {
    param (
        [string]$message,
        [int] $c = 6,
        [string]$color ="DarkGreen"
    )
    
    Write-Host "______________________________________________________" -BackgroundColor $color
    Write-Host "$message" -BackgroundColor $color
    Write-Host "______________________________________________________" -BackgroundColor $color
    
    for ($i = 0; $i -lt $c; $i++) {
        Write-Host ""
    }
}
#JLopez-20240918:   This function should validate if the resources group exist in the current subscription. 
#                   If it does not exist I will create it.
function checkMyResourceGroup {
    param(
        #Resource group
        [Parameter(Mandatory=$true)]
        [string]$rg,
        #Subscription
        [string]$s = "Suscripción de Plataformas de MSDN",
        #Location
        [Parameter(Mandatory=$true)]
        [string]$l,
        #Tags
        [string]$t,
        #BackgroundColor
        [string]$bc = "DarkGreen"
    )

    $check_rg = -not [bool]::Parse($(az group exists --name $rg))
    #JLopez: If the resource group not exists.
    if ($check_rg) {
        Write-Host "The resource group ($rg) doesn't exists in the current subscription ($s)." -BackgroundColor $bc
        #JLopez: Then create the resource group.
        Write-Host "Creating the resource group ($rg) in the location ($l)." -BackgroundColor $bc
        az group create `
            --name $rg `
            --subscription $s `
            --location $l `
            --tags $t
    }
}

#JLopez-20240906: Exporting functions to make them available when the module is imported.
Export-ModuleMember -Function printMyMessage,checkMyResourceGroup