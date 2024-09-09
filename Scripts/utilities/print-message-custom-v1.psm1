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
    Write-Host "$message" -BackgroundColor DarkGreen
    Write-Host "______________________________________________________" -BackgroundColor $color
    
    for ($i = 0; $i -lt $c; $i++) {
        Write-Host ""
    }
}

#JLopez-20240906: Exporting functions to make them available when the module is imported.
Export-ModuleMember -Function printMyMessage