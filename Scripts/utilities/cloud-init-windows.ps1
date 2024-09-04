# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Create and set content for a default web page
$webpageContent = @"
<head><title>Retail Website: $(hostname)</title></head>
<body>
    <h1>Retail Website</h1>
    <p>Web server: <strong>$(hostname)</strong></p>
</body>
"@
$webpagePath = "C:\inetpub\wwwroot\index.html"
Set-Content -Path $webpagePath -Value $webpageContent
