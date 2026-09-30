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
$elementPasswd =  Get-SeElement -By XPath '//*[@id="password"]'
Invoke-SeKeys -Element $elementPasswd -Keys $pwd
$elementClick = Get-SeElement -By Xpath '//*[@id="login"]/div/div/div/div/form/button'

Invoke-SeClick -Element $elementClick

taskkill /f /im chromedriver.exe
