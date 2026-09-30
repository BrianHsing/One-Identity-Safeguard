param (
    [string]$username,
    [string]$password,
    [string]$asset
)

$user = $username
$pwd = $password
$ip = "http://"+$asset

Start-SeDriver -Browser chrome -Arguments @('start-maximized','ignore-certificate-errors')  -StartURL $ip
Start-Sleep -Seconds 2

$elementUser =  Get-SeElement -By XPath '//*[@id="dsm-user-fieldset"]/div/div/div[1]/input'
Invoke-SeKeys -Element $elementUser -Keys $user
$elementClick1 = Get-SeElement -By Class "login-btn"
Invoke-SeClick -Element $elementClick1
sleep 1
$elementPasswd =  Get-SeElement -By XPath '//*[@id="dsm-pass-fieldset"]/div[1]/div/div[1]/input'
$elementClick2 = Get-SeElement -By Class "login-btn"
Invoke-SeKeys -Element $elementPasswd -Keys $pwd
Invoke-SeClick -Element $elementClick2

taskkill /f /im chromedriver.exe
