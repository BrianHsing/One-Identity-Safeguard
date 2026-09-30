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
$elementUser =  Get-SeElement -By XPath '/html/body/div[2]/idrac-start-screen/div/div/div/div/div/form/div[1]/div/div[1]/label/input'
$elementPasswd =  Get-SeElement -By XPath '/html/body/div[2]/idrac-start-screen/div/div/div/div/div/form/div[1]/div/div[2]/label/input[2]'
$elementClick = Get-SeElement -By XPath '/html/body/div[2]/idrac-start-screen/div/div/div/div/div/form/div[2]/div[3]/button'

Invoke-SeKeys -Element $elementUser -Keys $user
Invoke-SeKeys -Element $elementPasswd -Keys $pswd
Invoke-SeClick -Element $elementClick

taskkill /f /im chromedriver.exe
