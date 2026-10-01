# Ouvrir le Rick Roll classique dans Edge
Start-Process "msedge.exe" -ArgumentList "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

Write-Host "Rick Roll lancé ! 🎵" -ForegroundColor Green
New-Item -Path "$env:USERPROFILE\Desktop\rickroll_executed.txt" -ItemType File -Force
