#requires -Version 7.0
param (
    [Parameter(Mandatory = $true)]
    [string]$username,

    [Parameter(Mandatory = $true)]
    [string]$password,

    [Parameter(Mandatory = $true)]
    [string]$asset,

    # Realm 下拉的「顯示文字」，AD/LDAP 請填該 realm 在畫面上顯示的名稱
    [string]$realm = 'Proxmox VE authentication server'
)

if ($asset -notmatch '^https?://') {
    $asset = "https://$asset"
}

Start-SeDriver `
    -Browser Chrome `
    -Arguments @('start-maximized', 'ignore-certificate-errors') `
    -StartURL $asset

# 等登入視窗真的畫出來
$elementUser = Get-SeElement -By XPath '//input[@name="username"]' -Timeout 20
$elementPasswd = Get-SeElement -By XPath '//input[@name="password"]' -Timeout 20

Invoke-SeKeys -Element $elementUser -Keys $username
Invoke-SeKeys -Element $elementPasswd -Keys $password

# 展開 Realm 下拉
$realmTrigger = Get-SeElement -By Id 'pveloginrealm-trigger-picker' -Timeout 10
Invoke-SeClick -Element $realmTrigger

# 點選指定 realm
$realmXPath = "//div[@id='pveloginrealm-picker']//li[contains(@class,'x-boundlist-item') and normalize-space(.)='$realm']"
$realmItem = Get-SeElement -By XPath $realmXPath -Timeout 10
Invoke-SeClick -Element $realmItem

# 確認真的套用，沒套用就不要硬送帳密
$realmInput = Get-SeElement -By Id 'pveloginrealm-inputEl'
$current = $realmInput.GetAttribute('value')
if ($current -ne $realm) {
    Stop-SeDriver
    throw "Realm 選取失敗，目前為「$current」，預期「$realm」"
}

# 送出登入
$elementPasswd.SendKeys([OpenQA.Selenium.Keys]::Enter)

# 以左側資源樹出現視為登入成功
#$null = Get-SeElement -By XPath '//span[text()="Datacenter"]' -Timeout 20
Start-Sleep -Seconds 1
taskkill /f /im chromedriver.exe
