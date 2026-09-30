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

$elementUser =  Get-SeElement -By XPath '//*[@id="user"]'
Invoke-SeKeys -Element $elementUser -Keys $user
$elementPasswd =  Get-SeElement -By XPath '//*[@id="passwd"]'
$elementClick = Get-SeElement -By XPath '//*[@id="submit"]'
Invoke-SeKeys -Element $elementPasswd -Keys $pwd
Invoke-SeClick -Element $elementClick

taskkill /f /im chromedriver.exe
