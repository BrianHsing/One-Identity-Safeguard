#requires -Version 7.0
[CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
param([string]$ConfigPath=(Join-Path $PSScriptRoot 'config.json'),[switch]$Apply,[pscredential]$Credential)
if (($WhatIfPreference -or $Apply) -and !$PSCmdlet.ShouldProcess($ConfigPath, 'Create SPP syslog server and subscription')) { return }
if (!$IsWindows) { throw 'This deployment requires Windows and DPAPI.' }
. (Join-Path $PSScriptRoot 'Common.ps1')
Read-Configuration $ConfigPath
$connected=$false
try {
    Open-SppSession -Credential $Credential;$connected=$true
    $event=Invoke-SppApi GET 'Events/AccessRequestCheckedIn'
    if(!$event.SyslogFlag){throw 'This SPP does not support check-in syslog notifications.'}
    $serverName='SPP-CheckinPush-'+$Config.ListenAddress
    $description='SPP-CheckinPush: AccessRequestCheckedIn to '+$Config.ListenAddress
    $servers=@(Invoke-SppApi GET 'SyslogServers?limit=1000')
    $matches=@($servers|Where-Object{$_.Name -eq $serverName})
    if($matches.Count -gt 1){throw 'Ambiguous existing syslog server.'}
    if($matches.Count -eq 1) {
        $server=$matches[0]
        if($server.NetworkAddress -ne $Config.ListenAddress -or $server.Port -ne $Config.Port -or $server.Protocol -ne 'Tcp' -or $server.TcpFraming -ne 'OctetCounting' -or $server.UseSslEncryption){throw 'Existing syslog server differs. Review instead of overwriting it.'}
    } else {$server=$null}
    $subscribers=@(Invoke-SppApi GET 'EventSubscribers?limit=1000')
    $existing=@($subscribers|Where-Object{$_.Description -eq $description})
    if($existing.Count -gt 1){throw 'Ambiguous existing subscriber.'}
    if(!$Apply) {
        [pscustomobject]@{Mode='Preview';Destination=$Config.ListenAddress;Port=$Config.Port;Protocol='TCP';Framing='OctetCounting';Format='Json';Event='AccessRequestCheckedIn';ExistingServerId=if($server){$server.Id}else{$null};ExistingSubscriberCount=$existing.Count}
        return
    }
    Write-Log 'installation' ('Notification before: serverExists='+[bool]$server+'; subscriberCount='+$existing.Count)
    if(!$server) {
        $server=Invoke-SppApi POST 'SyslogServers' -Body @{Name=$serverName;NetworkAddress=$Config.ListenAddress;Port=$Config.Port;Protocol='Tcp';TcpFraming='OctetCounting';UseSslEncryption=$false;UseClientCertificate=$false;VerifySslCertificate=$false}
    }
    $properties=@{SyslogServerId=$server.Id;Protocol='Tcp';TcpFraming='OctetCounting';LogFormat='JSON';KeyPrefix='';Facility='User';TimeZoneId='UTC';UseSslEncryption=$false}
    if($existing.Count -eq 1) {
        $subscriber=$existing[0]
        $names=@($subscriber.Subscriptions|ForEach-Object{$_.Name})
        if($subscriber.Type -ne 'Syslog' -or $subscriber.SubscribeToAllEvents -or $subscriber.SyslogProperties.SyslogServerId -ne $server.Id -or $subscriber.SyslogProperties.LogFormat -ne 'Json' -or $subscriber.SyslogProperties.KeyPrefix -or $names.Count -ne 1 -or $names[0] -ne 'AccessRequestCheckedIn'){throw 'Existing subscriber differs. Review instead of overwriting it.'}
    } else {
        $subscriber=Invoke-SppApi POST 'EventSubscribers' -Body @{Type='Syslog';Description=$description;IsApplianceShared=$true;SubscribeToAllEvents=$false;SyslogProperties=$properties;Subscriptions=@(@{Name='AccessRequestCheckedIn'})}
    }
    Write-Log 'installation' ('Notification after: serverId='+$server.Id+'; subscriberId='+$subscriber.Id)
    [pscustomobject]@{Mode='Configured';SyslogServerId=$server.Id;SubscriberId=$subscriber.Id;Destination=$Config.ListenAddress;Port=$Config.Port}
} finally {if($connected){Close-SppSession}}
