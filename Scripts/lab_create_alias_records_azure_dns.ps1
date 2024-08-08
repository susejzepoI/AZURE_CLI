#Interactive lab 03
#Author:            Jesus Lopez Mesia
#Linkedin:          https://www.linkedin.com/in/susejzepol/
#Created date:      August-07-2024
#Modified date:     August-07-2024
#Lab:               https://learn.microsoft.com/en-us/training/modules/host-domain-azure-dns/6-exercise-create-alias-records

[CmdletBinding()]
param (
    #JLopez-20240807: Location
    [Parameter(Mandatory=$true)]
    [string]$l,

    #JLopez-20240807: Resource group name
    [Parameter(Mandatory=$true)]
    [string]$rg,

    #JLopez-20240807: Subscription name
    [Parameter(Mandatory=$true)]
    [string]$subscription
)