Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'SilentlyContinue'
$appUrl = "http://localhost:5000"
$savePath = "C:\opencode projects\project1\markitdown app\assets"

function Take-Screenshot {
    param([string]$filename, [int]$delay = 1)
    Start-Sleep -Seconds $delay
    $bitmap = New-Object System.Drawing.Bitmap(1536, 864)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen(0, 0, 0, 0, $bitmap.Size)
    $bitmap.Save("$savePath\$filename")
    $graphics.Dispose()
    $bitmap.Dispose()
    Write-Host "Saved: $filename"
}

# Create Edge with app
$proc = Start-Process msedge -ArgumentList "$appUrl/login" -PassThru -WindowStyle Minimized
Start-Sleep -Seconds 3

# Login page screenshot
Take-Screenshot "login-page.png"

# Navigate to home (should redirect to login or show upload)
$w = Get-Process | Where-Object {$_.ProcessName -eq "msedge" -and $_.MainWindowTitle -match "login|markitdown"}
if ($w) { $w | Stop-Process -Force }

# Login via form submission
Invoke-RestMethod -Uri "$appUrl/login" -Method POST -Body @{username="admin";password="admin"} -SessionVariable sess -ErrorAction SilentlyContinue

# Open main page
$proc = Start-Process msedge -ArgumentList "$appUrl/" -PassThru -WindowStyle Minimized
Start-Sleep -Seconds 3
Take-Screenshot "upload-page.png"

# Open history
$proc = Start-Process msedge -ArgumentList "$appUrl/history" -PassThru -WindowStyle Minimized
Start-Sleep -Seconds 3
Take-Screenshot "history-page.png"

# Open admin
$proc = Start-Process msedge -ArgumentList "$appUrl/admin" -PassThru -WindowStyle Minimized
Start-Sleep -Seconds 3
Take-Screenshot "admin-page.png"

# Clean up all Edge processes
Get-Process msedge | Stop-Process -Force

Write-Host "All screenshots taken!"
dir $savePath