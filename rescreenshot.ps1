Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$appUrl = "http://localhost:5000"
$savePath = "C:\opencode projects\project1\markitdown app\assets"

# Login first to get session
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
Invoke-RestMethod -Uri "$appUrl/login" -Method POST -Body @{username="admin";password="admin"} -WebSession $session -ErrorAction SilentlyContinue

function Take-Screenshot {
    param([string]$filename)
    $bitmap = New-Object System.Drawing.Bitmap(1536, 864)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen(0, 0, 0, 0, $bitmap.Size)
    $bitmap.Save("$savePath\$filename")
    $graphics.Dispose()
    $bitmap.Dispose()
}

# Close all Edge first
Get-Process msedge -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

# 1. Login Page
$edge = Start-Process msedge -ArgumentList "about:blank","--window-size=1536,864" -PassThru
Start-Sleep -Seconds 2
$edge.MainWindowHandle | ForEach-Object { Set-WindowPos $_ 0 0 1536 864 }
Start-Sleep -Seconds 1
Take-Screenshot "01-login.png"
Stop-Process $edge.Id -Force

# 2. Upload Page (need to login first via curl)
Invoke-RestMethod -Uri "$appUrl/login" -Method POST -Body @{username="admin";password="admin"} -SessionVariable sess -ErrorAction SilentlyContinue
$edge = Start-Process msedge -ArgumentList "$appUrl/" -PassThru
Start-Sleep -Seconds 3
Take-Screenshot "02-upload.png"
Stop-Process $edge.Id -Force

# 3. History Page
$edge = Start-Process msedge -ArgumentList "$appUrl/history" -PassThru
Start-Sleep -Seconds 3
Take-Screenshot "03-history.png"
Stop-Process $edge.Id -Force

# 4. Admin Page
$edge = Start-Process msedge -ArgumentList "$appUrl/admin" -PassThru
Start-Sleep -Seconds 3
Take-Screenshot "04-admin.png"
Stop-Process $edge.Id -Force

Write-Host "All screenshots taken!"
Get-ChildItem $savePath\*.png | Select-Object Name, Length