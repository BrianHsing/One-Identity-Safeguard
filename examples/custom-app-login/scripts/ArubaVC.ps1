param (
    [string]$username,
    [string]$password,
    [string]$asset
)

$user = $username
$pswd = $password
$ip = "https://"+$asset

Start-SeDriver -Browser chrome -Arguments @('start-maximized','ignore-certificate-errors')  -StartURL $ip
Start-Sleep -Seconds 2
$elementUser =  Get-SeElement -By XPath '//*[@id="login-username"]'
$elementPasswd =  Get-SeElement -By XPath '//*[@id="login-password"]'
$elementClick = Get-SeElement -By XPath '//*[@id="login-button"]'

Invoke-SeKeys -Element $elementUser -Keys $user
Invoke-SeKeys -Element $elementPasswd -Keys $pswd
Invoke-SeClick -Element $elementClick

taskkill /f /im chromedriver.exe
