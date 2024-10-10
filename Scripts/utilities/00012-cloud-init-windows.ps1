[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$account,
    [Parameter(Mandatory=$true)]
    [string]$shared,
    [Parameter(Mandatory=$true)]
    [string]$key,
    #$JLopez-20241009: This parameter will containts the drive letter for the drive to be mounting.
    [string]$drive = "Z"
)

$connectTestResult = Test-NetConnection -ComputerName "$account.file.core.windows.net" -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Guardar la contraseña para que la unidad persista al reiniciar
    $cred = New-Object System.Management.Automation.PSCredential("$account", (ConvertTo-SecureString $key -AsPlainText -Force))
    # Montar la unidad
    New-PSDrive -Name Y -PSProvider FileSystem -Root "\\$account.file.core.windows.net\$shared" -Credential $cred -Persist 
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}