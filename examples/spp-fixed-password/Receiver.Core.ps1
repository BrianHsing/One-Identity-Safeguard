# Byte-oriented RFC6587 framing: octet-counting and LF. No command is taken from a message.
function Read-SyslogFrames {
    param([Collections.Generic.List[byte]]$Buffer)
    while($Buffer.Count -gt 0) {
        if($Buffer[0] -ge 48 -and $Buffer[0] -le 57) {
            $space=$Buffer.IndexOf([byte]32)
            if($space -lt 0){if($Buffer.Count -gt 8){throw 'Invalid frame header'};return}
            if($space -gt 7){throw 'Frame length too long'}
            $digits=[Text.Encoding]::ASCII.GetString($Buffer.GetRange(0,$space).ToArray())
            if($digits -notmatch '^\d+$'){throw 'Invalid length'}
            $length=[int]$digits
            if($length -lt 1 -or $length -gt 131072){throw 'Frame exceeds limit'}
            if($Buffer.Count -lt ($space+1+$length)){return}
            $bytes=$Buffer.GetRange($space+1,$length).ToArray()
            $Buffer.RemoveRange(0,$space+1+$length)
        } else {
            $lf=$Buffer.IndexOf([byte]10)
            if($lf -lt 0){if($Buffer.Count -gt 131072){throw 'Frame exceeds limit'};return}
            if($lf -gt 131072){throw 'Frame exceeds limit'}
            $bytes=$Buffer.GetRange(0,$lf).ToArray();$Buffer.RemoveRange(0,$lf+1)
        }
        $utf8=[Text.UTF8Encoding]::new($false,$true)
        $utf8.GetString($bytes).TrimEnd([char]13)
    }
}
function Get-JsonField {
    param([System.Collections.IDictionary]$Data,[string]$Name)
    foreach($key in $Data.Keys){if([string]::Equals([string]$key,$Name,[StringComparison]::OrdinalIgnoreCase)){return $Data[$key]}}
    return $null
}
function Convert-CheckinMessage {
    param([string]$Message,[int]$AccountId,[int]$AssetId)
    $start=$Message.IndexOf('{')
    if($start -lt 0){return $null}
    try {$data=$Message.Substring($start)|ConvertFrom-Json -AsHashtable -ErrorAction Stop}catch{return $null}
    if($data -isnot [System.Collections.IDictionary]){return $null}
    $eventName=Get-JsonField $data 'EventName'
    if($eventName -cne 'AccessRequestCheckedIn'){return $null}
    $account=0;$asset=0
    if(![int]::TryParse([string](Get-JsonField $data 'AccountId'),[ref]$account) -or ![int]::TryParse([string](Get-JsonField $data 'AssetId'),[ref]$asset)){return $null}
    if($account -ne $AccountId -or $asset -ne $AssetId){return $null}
    $request=[string](Get-JsonField $data 'RequestId')
    if($request -notmatch '\A[A-Za-z0-9-]{1,200}\z'){return $null}
    return [pscustomobject]@{RequestId=$request;AccountId=$account;AssetId=$asset;EventName=$eventName}
}
