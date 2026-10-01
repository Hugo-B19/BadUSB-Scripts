# Ouvrir le Rick Roll dans le navigateur par défaut
Start-Process "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

# Attendre que le navigateur s'ouvre
Start-Sleep -Seconds 2

# Mettre en plein écran avec F11
$shell = New-Object -ComObject WScript.Shell
$shell.SendKeys("{F11}")

Write-Host "Rick Roll lancé en plein écran ! 🎵" -ForegroundColor Green
New-Item -Path "$env:USERPROFILE\Desktop\rickroll_executed.txt" -ItemType File -Force
