# Ouvrir le Rick Roll
Start-Process "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

Start-Sleep -Seconds 2

# Mettre en plein écran (F11)
$shell = New-Object -ComObject WScript.Shell
$shell.SendKeys("{F11}")

# Appuyer sur Espace (pour lancer la vidéo par exemple)
Start-Sleep -Seconds 1
$shell.SendKeys(" ")

Start-Sleep -Seconds 1
$shell.SendKeys("f")

Write-Host "Rick Roll en plein écran ! 🎵" -ForegroundColor Green
