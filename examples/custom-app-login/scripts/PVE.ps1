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

$elementUser =  Get-SeElement -By XPath '//*[@id="textfield-1067-inputEl"]'
Invoke-SeKeys -Element $elementUser -Keys $user
$elementPasswd =  Get-SeElement -By XPath '//*[@id="textfield-1068-inputWrap"]'
Invoke-SeKeys -Element $elementPasswd -Keys $pwd
sleep 1
Invoke-SeJavascript -Script "Ext.ComponentQuery.query('[namr=realm]')[0].setValue('Proxmox VE authentication server');"

#$elemenAuth =  Get-SeElement -By XPath '//*[@id="ext-174"]'
#Invoke-SeClick -Element $elemenAuth
sleep 1
$elementClick = Get-SeElement -By Xpath '//*[@id="button-1072-btnInnerEl"]'
Invoke-SeClick -Element $elementClick

taskkill /f /im chromedriver.exe
