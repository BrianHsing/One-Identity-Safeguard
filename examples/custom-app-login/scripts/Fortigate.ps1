param (
    [string]$username,
    [string]$password,
    [string]$asset
)

$user = $username
$pwd = $password
$ip = "https://"+$asset

Start-SeDriver -Browser chrome -Arguments @('start-maximized','ignore-certificate-errors')  -StartURL $ip
Start-Sleep -Seconds 2

$elementUser =  Get-SeElement -By XPath '//*[@id="username"]'
Invoke-SeKeys -Element $elementUser -Keys $user

sleep 1
$elementPasswd =  Get-SeElement -By XPath '//*[@id="secretkey"]'
$elementClick = Get-SeElement -By Xpath '//*[@id="login_button"]'
Invoke-SeKeys -Element $elementPasswd -Keys $pwd
Invoke-SeClick -Element $elementClick

taskkill /f /im chromedriver.exe
