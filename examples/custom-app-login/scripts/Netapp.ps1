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

$elementUser =  Get-SeElement -By XPath '//*[@id="nwf-login-form"]/div[1]/input'
Invoke-SeKeys -Element $elementUser -Keys $user
$elementPasswd =  Get-SeElement -By XPath '//*[@id="nwf-login-form"]/div[2]/input'
$elementClick = Get-SeElement -By CssSelector "nwf-loading-button[data-netapp-id='loginPage-signIn-button'] button"
Invoke-SeKeys -Element $elementPasswd -Keys $pwd
Invoke-SeClick -Element $elementClick

taskkill /f /im chromedriver.exe
