#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Publish', 'Activate', 'Verify')][string]$Mode = 'Publish',
    [string]$DeploymentDirectory,
    [string]$InstanceRoot = $env:TGS_INSTANCE_ROOT
)

# No AWS CLI/module required. Signed requests use TLS; BYOND downloads use HTTP.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

function Get-Hex([byte[]]$Bytes) {
    [BitConverter]::ToString($Bytes).Replace('-', '').ToLowerInvariant()
}

function Get-Sha256([string]$Text) {
    $hash = [Security.Cryptography.SHA256]::Create()
    try { Get-Hex ($hash.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))) }
    finally { $hash.Dispose() }
}

function Open-RscRead([string]$Path) {
    # DreamDaemon keeps a write-capable RSC handle open even for static resources.
    # File.OpenRead/Get-FileHash deny that sharing and fail against Game/Live.
    [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read,
        ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
}

function Get-RscMd5([string]$Path) {
    $stream = Open-RscRead $Path
    $hash = [Security.Cryptography.MD5]::Create()
    try { Get-Hex ($hash.ComputeHash($stream)) }
    finally { $stream.Dispose(); $hash.Dispose() }
}

function New-RscZip([string]$RscFile, [string]$ZipFile) {
    $archive = [IO.Compression.ZipFile]::Open($ZipFile, [IO.Compression.ZipArchiveMode]::Create)
    try {
        $entry = $archive.CreateEntry('tgstation.rsc', [IO.Compression.CompressionLevel]::Fastest)
        $source = Open-RscRead $RscFile
        try {
            $target = $entry.Open()
            try { $source.CopyTo($target) } finally { $target.Dispose() }
        } finally { $source.Dispose() }
    } finally { $archive.Dispose() }
}

function Get-Hmac([byte[]]$Key, [string]$Text) {
    $hash = New-Object Security.Cryptography.HMACSHA256
    try {
        $hash.Key = $Key
        ,$hash.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
    } finally { $hash.Dispose() }
}

function Get-S3Headers($Settings, $Credentials, [string]$Method, [string]$Path,
    [string]$Query, [string]$PayloadHash, [hashtable]$ExtraHeaders = @{},
    [datetime]$Now = [datetime]::UtcNow) {
    $date = $Now.ToUniversalTime().ToString('yyyyMMdd')
    $stamp = $Now.ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    $headers = @{
        host = "$($Settings.Bucket).s3.$($Settings.Region).amazonaws.com"
        'x-amz-date' = $stamp
        'x-amz-content-sha256' = $PayloadHash
    }
    foreach ($key in $ExtraHeaders.Keys) { $headers[$key.ToLowerInvariant()] = $ExtraHeaders[$key] }
    if ($Credentials.PSObject.Properties['SessionToken'] -and $Credentials.SessionToken) {
        $headers['x-amz-security-token'] = $Credentials.SessionToken
    }
    $names = @($headers.Keys | Sort-Object -CaseSensitive)
    $canonicalHeaders = ($names | ForEach-Object { "${_}:$($headers[$_].Trim())`n" }) -join ''
    $signedHeaders = $names -join ';'
    $canonical = "$Method`n$Path`n$Query`n$canonicalHeaders`n$signedHeaders`n$PayloadHash"
    $scope = "$date/$($Settings.Region)/s3/aws4_request"
    $toSign = "AWS4-HMAC-SHA256`n$stamp`n$scope`n$(Get-Sha256 $canonical)"
    $key = Get-Hmac ([Text.Encoding]::UTF8.GetBytes("AWS4$($Credentials.SecretAccessKey)")) $date
    $key = Get-Hmac $key $Settings.Region
    $key = Get-Hmac $key 's3'
    $key = Get-Hmac $key 'aws4_request'
    $signature = Get-Hex (Get-Hmac $key $toSign)
    $headers['Authorization'] = "AWS4-HMAC-SHA256 Credential=$($Credentials.AccessKeyId)/$scope, SignedHeaders=$signedHeaders, Signature=$signature"
    $headers
}

function Invoke-S3($Settings, $Credentials, [string]$Method, [string]$Key = '',
    [hashtable]$Query = @{}, [string]$File, [hashtable]$Headers = @{}) {
    $path = '/' + (($Key.Split('/') | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/')
    $queryString = (@($Query.Keys | Sort-Object -CaseSensitive | ForEach-Object {
        [uri]::EscapeDataString($_) + '=' + [uri]::EscapeDataString([string]$Query[$_])
    })) -join '&'
    $payloadHash = if ($File) { (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash.ToLowerInvariant() } else { Get-Sha256 '' }
    $signed = Get-S3Headers $Settings $Credentials $Method $path $queryString $payloadHash $Headers
    $uri = "https://$($signed.host)$path"
    if ($queryString) { $uri += '?' + $queryString }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $request = [Net.HttpWebRequest]::Create($uri)
    $request.Method = $Method
    $request.AllowAutoRedirect = $false
    $request.Timeout = 180000
    $request.ReadWriteTimeout = 180000
    $request.AllowWriteStreamBuffering = $false
    foreach ($name in $signed.Keys) {
        if ($name -eq 'host') { continue }
        if ($name -eq 'content-type') { $request.ContentType = $signed[$name] }
        else { $request.Headers[$name] = $signed[$name] }
    }
    $response = $null
    try {
        if ($File) {
            $request.ContentLength = (Get-Item -LiteralPath $File).Length
            $inputStream = [IO.File]::OpenRead($File)
            try {
                $outputStream = $request.GetRequestStream()
                try { $inputStream.CopyTo($outputStream) } finally { $outputStream.Dispose() }
            } finally { $inputStream.Dispose() }
        }
        $response = $request.GetResponse()
        $reader = New-Object IO.StreamReader($response.GetResponseStream())
        try { $reader.ReadToEnd() } finally { $reader.Dispose() }
    } catch [Net.WebException] {
        # Never include request headers, credentials, or AWS's reflected canonical request.
        $failure = $_.Exception.Response
        if ($failure) {
            $status = [int]$failure.StatusCode
            $requestId = $failure.Headers['x-amz-request-id']
            $failure.Close()
            throw "S3 $Method failed: HTTP $status; request ID $requestId."
        }
        throw "S3 $Method failed: $($_.Exception.Status)."
    } finally {
        if ($response) { $response.Close() }
        $request.Abort()
    }
}

function Write-AtomicText([string]$Path, [string]$Text, [Text.Encoding]$Encoding = (New-Object Text.UTF8Encoding($false))) {
    $temporary = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        [IO.File]::WriteAllText($temporary, $Text, $Encoding)
        if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temporary, $Path, [NullString]::Value) }
        else { [IO.File]::Move($temporary, $Path) }
    } finally {
        if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

function Set-ResourceUrl([string]$ResourcesFile, [string]$Url) {
    # Read the authoritative GameStaticFiles path, never the soon-to-be-replaced clone config.
    $reader = New-Object IO.StreamReader($ResourcesFile, [Text.Encoding]::UTF8, $true)
    try { $original = $reader.ReadToEnd(); $encoding = $reader.CurrentEncoding }
    finally { $reader.Dispose() }
    if ($encoding.CodePage -eq 65001) {
        $bytes = [IO.File]::ReadAllBytes($ResourcesFile)
        $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191
        $encoding = New-Object Text.UTF8Encoding($hasBom)
    }
    $newline = if ($original.Contains("`r`n")) { "`r`n" } else { "`n" }
    $updated = [regex]::Replace($original, '(?im)^[\t ]*EXTERNAL_RSC_URLS(?:[\t ][^\r\n]*)?\r?\n?', '')
    if ($Url) {
        if ($Url -notmatch '^http://[^\s]+$') { throw 'BYOND resource URL must be plain HTTP without whitespace.' }
        $updated = "EXTERNAL_RSC_URLS $Url$newline" + $updated
    }
    if ($updated -cne $original) { Write-AtomicText $ResourcesFile $updated $encoding }
}

function Get-ZipRscHash([string]$ZipFile) {
    $zip = [IO.Compression.ZipFile]::OpenRead($ZipFile)
    try {
        if ($zip.Entries.Count -ne 1 -or $zip.Entries[0].FullName -cne 'tgstation.rsc') {
            throw 'Resource ZIP must contain only tgstation.rsc at its root.'
        }
        $stream = $zip.Entries[0].Open()
        $hash = [Security.Cryptography.MD5]::Create()
        try { Get-Hex ($hash.ComputeHash($stream)) }
        finally { $stream.Dispose(); $hash.Dispose() }
    } finally { $zip.Dispose() }
}

function Test-PublicResource([string]$Url, [string]$RscHash, [long]$ZipBytes, [string]$DownloadFile) {
    if ($Url -notmatch '^http://[^\s]+$') { throw 'Expected a plain HTTP resource URL.' }
    # Redirects (especially to TLS), 403s, and 404s must fail verification.
    $request = [Net.HttpWebRequest]::Create($Url)
    $request.Method = 'HEAD'
    $request.AllowAutoRedirect = $false
    $request.Timeout = 30000
    $response = $request.GetResponse()
    try {
        if ([int]$response.StatusCode -ne 200 -or $response.ContentLength -ne $ZipBytes -or
            $response.Headers['x-amz-meta-rsc-md5'] -cne $RscHash) {
            throw 'HTTP HEAD failed status, ZIP size, or rsc-md5 metadata validation.'
        }
    } finally { $response.Close() }
    if ($DownloadFile) {
        & curl.exe --fail --silent --show-error --proto '=http' --max-redirs 0 --connect-timeout 15 --max-time 600 --output $DownloadFile $Url
        if ($LASTEXITCODE -ne 0) { throw "HTTP download failed: curl exit $LASTEXITCODE." }
        if ((Get-ZipRscHash $DownloadFile) -cne $RscHash) { throw 'Downloaded tgstation.rsc MD5 does not match this deployment.' }
    }
    Write-Host "[external-rsc] Verified HTTP 200, rsc-md5=$RscHash, zip-bytes=$ZipBytes$(if ($DownloadFile) { ', downloaded ZIP contents match' })."
}

function Remove-OldResources($Settings, $Credentials, [string[]]$ProtectedKeys) {
    $objects = @()
    $query = @{ 'list-type' = '2'; prefix = $Settings.Prefix + 'tgstation-' }
    do {
        [xml]$page = Invoke-S3 $Settings $Credentials GET -Query $query
        $root = $page.DocumentElement
        if ($root.LocalName -ne 'ListBucketResult') { throw 'Unexpected S3 listing response; pruning aborted.' }
        $pattern = '^' + [regex]::Escape($Settings.Prefix) + 'tgstation-[0-9a-f]{32}\.zip$'
        foreach ($item in $root.SelectNodes("*[local-name()='Contents']")) {
            if ($item.Key -cmatch $pattern) {
                $objects += [pscustomobject]@{ Key = [string]$item.Key; Modified = [datetime]$item.LastModified }
            }
        }
        $truncated = $root.SelectSingleNode("*[local-name()='IsTruncated']")
        if (!$truncated) { throw 'Missing S3 pagination flag; pruning aborted.' }
        if ($truncated.InnerText -eq 'true') {
            $token = $root.SelectSingleNode("*[local-name()='NextContinuationToken']")
            if (!$token -or !$token.InnerText -or $token.InnerText -eq $query['continuation-token']) { throw 'Invalid S3 continuation token.' }
            $query['continuation-token'] = $token.InnerText
        }
    } while ($truncated.InnerText -eq 'true')
    # Keep the just-published and running builds, then newest uploads, to a total of three.
    $keep = @($ProtectedKeys | Select-Object -Unique)
    foreach ($item in ($objects | Sort-Object Modified -Descending)) {
        if ($keep.Count -ge 3) { break }
        if ($item.Key -notin $keep) { $keep += $item.Key }
    }
    foreach ($item in $objects) {
        if ($item.Key -notin $keep) {
            $null = Invoke-S3 $Settings $Credentials DELETE -Key $item.Key
            Write-Host "[external-rsc] Pruned $($item.Key)."
        }
    }
}

function Invoke-ExternalRsc {
    [CmdletBinding()]
    param([string]$Operation, [string]$Deploy, [string]$Root)
    $resources = $null
    $lock = $null
    $workFiles = @()
    $workDirectory = $null
    $manifestPath = $null
    try {
        if (!$Root -or !$Deploy) { throw 'TGS_INSTANCE_ROOT and the deployment directory argument are required.' }
        $Root = [IO.Path]::GetFullPath($Root)
        $Deploy = [IO.Path]::GetFullPath($Deploy)
        $gameRoot = [IO.Path]::Combine($Root, 'Game') + [IO.Path]::DirectorySeparatorChar
        if (!$Deploy.StartsWith($gameRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Deployment directory must be inside this instance Game directory.'
        }
        $configuration = Join-Path $Root 'Configuration'
        $lock = [IO.File]::Open((Join-Path $configuration 'external-rsc.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
        $resources = Join-Path $configuration 'GameStaticFiles/config/resources.txt'
        $manifestPath = Join-Path $Deploy 'external-rsc-build.json'
        if ($Operation -ne 'Verify') { Set-ResourceUrl $resources '' }
        $settings = Get-Content -LiteralPath (Join-Path $configuration 'external-rsc.json') -Raw | ConvertFrom-Json
        if ($settings.Enabled -isnot [bool]) { throw 'Enabled must be a JSON boolean.' }
        if (!$settings.Enabled) {
            if ($Operation -eq 'Verify') { throw 'External resources are disabled.' }
            Write-Host '[external-rsc] Disabled; using on-demand resources (PRELOAD_RSC must be 0).'
            return 0
        }
        if ($settings.Bucket -cnotmatch '^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$' -or
            $settings.Region -cnotmatch '^[a-z]{2}-[a-z]+-[0-9]+$' -or
            $settings.Prefix -cnotmatch '^(?:[a-zA-Z0-9_-]+/)+$') {
            throw 'Invalid bucket, region, or per-instance prefix (must end in /).'
        }
        $rsc = Join-Path $Deploy 'tgstation.rsc'
        $rscHash = Get-RscMd5 $rsc
        $key = $settings.Prefix + "tgstation-$rscHash.zip"
        $url = "http://$($settings.Bucket).s3.$($settings.Region).amazonaws.com/$key"
        if ($Operation -eq 'Publish') {
            try {
                $credentials = Get-Content -LiteralPath (Join-Path $configuration 'Secrets/external-rsc-aws.json') -Raw | ConvertFrom-Json
                if ($credentials.AccessKeyId -isnot [string] -or !$credentials.AccessKeyId -or
                    $credentials.SecretAccessKey -isnot [string] -or !$credentials.SecretAccessKey) { throw 'Invalid fields.' }
            } catch { throw 'Cannot read valid S3 credentials from Configuration/Secrets/external-rsc-aws.json.' }
            $workDirectory = Join-Path $Deploy "external-rsc-$([guid]::NewGuid().ToString('N'))"
            $null = [IO.Directory]::CreateDirectory($workDirectory)
            $zipPath = Join-Path $workDirectory "tgstation-$rscHash.zip"
            $download = Join-Path $workDirectory 'download.zip'
            $workFiles = @($download)
            $workFiles += $zipPath
            New-RscZip $rsc $zipPath
            if ((Get-ZipRscHash $zipPath) -cne $rscHash) { throw 'RSC changed during packaging.' }
            $zipBytes = (Get-Item -LiteralPath $zipPath).Length
            Write-Host "[external-rsc] Uploading $key ($zipBytes bytes)."
            $null = Invoke-S3 $settings $credentials PUT -Key $key -File $zipPath -Headers @{
                'x-amz-acl' = 'public-read'
                'content-type' = 'application/zip'
                'cache-control' = 'public,max-age=31536000,immutable'
                'x-amz-meta-rsc-md5' = $rscHash
            }
            Test-PublicResource $url $rscHash $zipBytes $download
            $manifest = [ordered]@{ rsc_md5 = $rscHash; zip_bytes = $zipBytes; url = $url; key = $key; verified_utc = [datetime]::UtcNow.ToString('o') }
            Write-AtomicText $manifestPath ($manifest | ConvertTo-Json)
            # Publish only after both S3 upload and a full anonymous HTTP download verify.
            Set-ResourceUrl $resources $url
            Write-Host "[external-rsc] Published $url"
            try {
                $protected = @($key)
                $liveRsc = Join-Path $Root 'Game/Live/tgstation.rsc'
                if (Test-Path -LiteralPath $liveRsc) {
                    $liveHash = Get-RscMd5 $liveRsc
                    $protected += $settings.Prefix + "tgstation-$liveHash.zip"
                }
                Remove-OldResources $settings $credentials $protected
            } catch { Write-Warning "[external-rsc] PRUNING FAILED; published URL retained: $($_.Exception.Message)" }
        } else {
            $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
            if ($manifest.rsc_md5 -cne $rscHash -or $manifest.url -cne $url -or $manifest.key -cne $key) {
                throw 'Stale resource manifest: does not match the selected deployment or bucket configuration.'
            }
            $download = ''
            if ($Operation -eq 'Verify') {
                $download = Join-Path $Deploy "external-rsc-$([guid]::NewGuid().ToString('N')).zip"
                $workFiles += $download
                & curl.exe --fail --silent --show-error --proto '=http' --max-redirs 0 --connect-timeout 15 --max-time 30 -I $url | ForEach-Object { Write-Host $_ }
                if ($LASTEXITCODE -ne 0) { throw "curl -I failed: exit $LASTEXITCODE." }
                $configured = [IO.File]::ReadAllText($resources)
                $urls = [regex]::Matches($configured, '(?im)^[\t ]*EXTERNAL_RSC_URLS[\t ]+([^\r\n]+)')
                if ($urls.Count -ne 1 -or $urls[0].Groups[1].Value.Trim() -cne $url) { throw 'resources.txt does not select this deployment URL.' }
            }
            Test-PublicResource $url $rscHash $manifest.zip_bytes $download
            if ($Operation -eq 'Activate') { Set-ResourceUrl $resources $url }
        }
        return 0
    } catch {
        Write-Warning "[external-rsc] ERROR ($Operation): $($_.Exception.Message)"
        if ($Operation -ne 'Verify' -and $resources) {
            try {
                Set-ResourceUrl $resources ''
                Write-Warning '[external-rsc] On-demand fallback selected; deployment continues. PRELOAD_RSC must be 0.'
                if ($Operation -eq 'Publish' -and $manifestPath -and [IO.File]::Exists($manifestPath)) { [IO.File]::Delete($manifestPath) }
            } catch { Write-Warning "[external-rsc] FALLBACK CONFIG WRITE FAILED: $($_.Exception.Message). Remove EXTERNAL_RSC_URLS manually." }
        }
        if ($Operation -eq 'Verify') { return 1 }
        return 0
    } finally {
        foreach ($file in $workFiles) {
            try { if ([IO.File]::Exists($file)) { [IO.File]::Delete($file) } }
            catch { Write-Warning '[external-rsc] Could not remove temporary ZIP.' }
        }
        if ($workDirectory) {
            try { [IO.Directory]::Delete($workDirectory) } # Non-recursive: only our now-empty staging directory.
            catch { Write-Warning '[external-rsc] Could not remove staging directory.' }
        }
        if ($lock) { $lock.Dispose() }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    exit (Invoke-ExternalRsc $Mode $DeploymentDirectory $InstanceRoot)
}
