[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$account,
    [Parameter(Mandatory=$true)]
    [string]$shared,
    [Parameter(Mandatory=$true)]
    [string]$key,
    #$JLopez-20240810: This parameter
    [string]$drive
)

$connectTestResult = Test-NetConnection -ComputerName $account.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Guardar la contraseña para que la unidad persista al reiniciar
    cmd.exe /C "cmdkey /add:`"$account.file.core.windows.net`" /user:`"localhost\$account`" /pass:`"$key`""
    # Montar la unidad
    New-PSDrive -Name $drive -PSProvider FileSystem -Root "\\$account.file.core.windows.net\$shared" -Persist
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}