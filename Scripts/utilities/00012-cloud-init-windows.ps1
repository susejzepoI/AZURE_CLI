[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$account,
    [Parameter(Mandatory=$true)]
    [string]$shared,
    [Parameter(Mandatory=$true)]
    [string]$key,
    #$JLopez-20241010: This parameter will containts the drive letter for the drive to be mounting.
    [string]$drive = "Z:"
)

$connectTestResult = Test-NetConnection -ComputerName "$account.file.core.windows.net" -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    $path = "\\$account.file.core.windows.net\$shared"
    net use $drive $path $key /user:$account /persistent:yes    
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}