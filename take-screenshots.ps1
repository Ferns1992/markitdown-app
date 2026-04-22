Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$appUrl = "http://localhost:5000"
$savePath = "C:\opencode projects\project1\markitdown app\assets"

# Start Edge
$edge = Start-Process msedge -ArgumentList "$appUrl/login" -PassThru -WindowStyle Minimized
Start-Sleep -Seconds 3

# Take screenshot of login page
$bitmap = New-Object System.Drawing.Bitmap(1536, 864)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen(0, 0, 0, 0, $bitmap.Size)
$bitmap.Save("$savePath\login.png")
$graphics.Dispose()
$bitmap.Dispose()

# Login first
Start-Process "http://localhost:5000/login"

Write-Host "Screenshots saved to $savePath"
Stop-Process $edge.Id -ErrorAction SilentlyContinue