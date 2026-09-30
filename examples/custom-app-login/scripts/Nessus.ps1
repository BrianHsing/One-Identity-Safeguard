param (
    [string]$username,
    [string]$password,
    [string]$asset
)

$user = $username
$pswd = $password
$ip = "https://$asset`:8834"

Start-SeDriver -Browser chrome -Arguments @('start-maximized','ignore-certificate-errors')  -StartURL $ip
Start-Sleep -Seconds 2
$elementUser =  Get-SeElement -By XPath '//input[@type="text" and @aria-label="Username"]'
$elementPasswd =  Get-SeElement -By XPath '//input[@type="password" and @aria-label="Password"]'
$elementClick = Get-SeElement -By XPath '//button[@type="submit" and @data-domselect="sign-in"]'

Invoke-SeKeys -Element $elementUser -Keys $user
Invoke-SeKeys -Element $elementPasswd -Keys $pswd
Invoke-SeClick -Element $elementClick

taskkill /f /im chromedriver.exe
