[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ZoneName,

    [string]$ApiToken = $env:CLOUDFLARE_API_TOKEN,

    [string[]]$CountryCodes = @("CN", "IR", "SG"),

    [ValidateSet("managed_challenge", "block", "challenge", "js_challenge")]
    [string]$CountryAction = "managed_challenge",

    [string[]]$RateLimitPaths = @(),

    [int]$RateLimitRequests = 10,

    [ValidateSet(10, 60, 120, 300, 600, 3600)]
    [int]$RateLimitPeriodSeconds = 60,

    [ValidateSet("managed_challenge", "block", "challenge", "js_challenge", "log")]
    [string]$RateLimitAction = "managed_challenge",

    [switch]$SkipBotFightMode,

    [switch]$SkipDnsCheck
)

$ErrorActionPreference = "Stop"

if (-not $ApiToken) {
    throw "Set CLOUDFLARE_API_TOKEN or pass -ApiToken before running this script."
}

$headers = @{
    Authorization = "Bearer $ApiToken"
}

function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message"
}

function ConvertTo-CloudflareJson {
    param($Value)
    return ($Value | ConvertTo-Json -Depth 20 -Compress)
}

function Invoke-CloudflareApi {
    param(
        [ValidateSet("GET", "POST", "PUT", "PATCH")]
        [string]$Method,

        [string]$Path,

        $Body
    )

    $uri = "https://api.cloudflare.com/client/v4$Path"

    try {
        if ($PSBoundParameters.ContainsKey("Body")) {
            $response = Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -ContentType "application/json" -Body (ConvertTo-CloudflareJson $Body)
        }
        else {
            $response = Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
        }
    }
    catch {
        if ($_.ErrorDetails.Message) {
            throw "Cloudflare API error calling $Method $Path`n$($_.ErrorDetails.Message)"
        }

        throw
    }

    if (-not $response.success) {
        $errorText = if ($response.errors) {
            ($response.errors | ForEach-Object { $_.message }) -join "; "
        }
        else {
            "Unknown Cloudflare API failure."
        }

        throw "Cloudflare API request failed for $Method $($Path): $errorText"
    }

    return $response.result
}

function Get-ExactZone {
    param([string]$Name)

    $encodedName = [uri]::EscapeDataString($Name)
    $zones = @(Invoke-CloudflareApi -Method GET -Path "/zones?name=$encodedName")
    $zone = $zones | Where-Object { $_.name -eq $Name } | Select-Object -First 1

    if (-not $zone) {
        throw "Could not find a Cloudflare zone named '$Name'."
    }

    return $zone
}

function Get-EntryPointRuleset {
    param(
        [string]$ZoneId,
        [string]$Phase
    )

    try {
        $result = Invoke-CloudflareApi -Method GET -Path "/zones/$ZoneId/rulesets/phases/$Phase/entrypoint"
    }
    catch {
        if ($_.Exception.Message -match "404") {
            return $null
        }

        throw
    }

    if (-not $result) {
        return $null
    }

    if ($result -is [System.Array] -and $result.Count -eq 0) {
        return $null
    }

    return $result
}

function New-CountrySetExpression {
    param([string[]]$Codes)

    $normalized = $Codes |
        Where-Object { $_ } |
        ForEach-Object { $_.Trim().ToUpperInvariant() } |
        Sort-Object -Unique

    if (-not $normalized) {
        throw "CountryCodes cannot be empty."
    }

    $quoted = $normalized | ForEach-Object { '"' + $_ + '"' }
    return "{" + ($quoted -join " ") + "}"
}

function Get-RuleRefSuffix {
    param([string]$Path)

    if ($Path -eq "/") {
        return "root"
    }

    $trimmed = $Path.Trim("/")
    if (-not $trimmed) {
        return "root"
    }

    $safe = ($trimmed -replace "[^A-Za-z0-9]+", "_").Trim("_").ToLowerInvariant()
    if (-not $safe) {
        return "path"
    }

    return $safe
}

function New-CountryRule {
    param(
        [string[]]$Codes,
        [string]$Action
    )

    $normalized = $Codes |
        Where-Object { $_ } |
        ForEach-Object { $_.Trim().ToUpperInvariant() } |
        Sort-Object -Unique

    $countryList = $normalized -join ", "
    $countrySet = New-CountrySetExpression -Codes $normalized

    return @{
        ref         = "codex_geo_bot_gate"
        description = "Codex: challenge traffic from $countryList except verified bots"
        expression  = "(ip.src.country in $countrySet and not cf.client.bot)"
        action      = $Action
        enabled     = $true
    }
}

function New-RateLimitRule {
    param(
        [string]$Path,
        [int]$Requests,
        [int]$PeriodSeconds,
        [string]$Action
    )

    $operator = "eq"
    if ($Path.Contains("*")) {
        $operator = "wildcard"
    }

    $expression = "(http.request.uri.path $operator `"$Path`")"
    $refSuffix = Get-RuleRefSuffix -Path $Path
    $mitigationTimeout = if ($Action -in @("managed_challenge", "challenge", "js_challenge")) { 0 } else { 600 }

    return @{
        ref         = "codex_rate_limit_$refSuffix"
        description = "Codex: rate limit $Path to $Requests requests per $PeriodSeconds seconds"
        expression  = $expression
        action      = $Action
        enabled     = $true
        ratelimit   = @{
            characteristics     = @("cf.colo.id", "ip.src")
            period              = $PeriodSeconds
            requests_per_period = $Requests
            mitigation_timeout  = $mitigationTimeout
            requests_to_origin  = $true
        }
    }
}

function Upsert-EntryPointRule {
    param(
        [string]$ZoneId,
        [string]$Phase,
        [hashtable]$Rule
    )

    $ruleset = Get-EntryPointRuleset -ZoneId $ZoneId -Phase $Phase

    if (-not $ruleset) {
        $createBody = @{
            name        = "zone"
            description = "Zone-level phase entry point"
            kind        = "zone"
            phase       = $Phase
            rules       = @($Rule)
        }

        if ($PSCmdlet.ShouldProcess("$ZoneId/$Phase", "Create phase entry point and add rule '$($Rule.ref)'")) {
            Write-Step "Creating $Phase entry point ruleset with rule '$($Rule.ref)'."
            Invoke-CloudflareApi -Method POST -Path "/zones/$ZoneId/rulesets" -Body $createBody | Out-Null
        }

        return
    }

    $existingRule = @($ruleset.rules) | Where-Object { $_.ref -eq $Rule.ref } | Select-Object -First 1
    if ($existingRule) {
        if ($PSCmdlet.ShouldProcess("$ZoneId/$Phase/$($Rule.ref)", "Update existing rule")) {
            Write-Step "Updating existing rule '$($Rule.ref)' in $Phase."
            Invoke-CloudflareApi -Method PATCH -Path "/zones/$ZoneId/rulesets/$($ruleset.id)/rules/$($existingRule.id)" -Body $Rule | Out-Null
        }

        return
    }

    if ($PSCmdlet.ShouldProcess("$ZoneId/$Phase/$($Rule.ref)", "Add new rule")) {
        Write-Step "Adding new rule '$($Rule.ref)' to $Phase."
        Invoke-CloudflareApi -Method POST -Path "/zones/$ZoneId/rulesets/$($ruleset.id)/rules" -Body $Rule | Out-Null
    }
}

function Test-WebProxyRecords {
    param(
        [string]$ZoneId,
        [string]$ZoneName
    )

    try {
        $records = @(Invoke-CloudflareApi -Method GET -Path "/zones/$ZoneId/dns_records?per_page=100")
    }
    catch {
        Write-Warning "Skipping DNS proxy check: $($_.Exception.Message)"
        return
    }

    $candidateNames = @($ZoneName, "www.$ZoneName")
    $webRecords = $records | Where-Object {
        $_.type -in @("A", "AAAA", "CNAME") -and $_.name -in $candidateNames
    }

    if (-not $webRecords) {
        Write-Warning "Could not find root/www A, AAAA, or CNAME records. Confirm your live web hostname is proxied in Cloudflare."
        return
    }

    $dnsOnly = $webRecords | Where-Object { -not $_.proxied }
    if ($dnsOnly) {
        $names = ($dnsOnly | Select-Object -ExpandProperty name) -join ", "
        Write-Warning "These likely web records are DNS-only, so WAF/rate limits will not apply: $names"
        return
    }

    Write-Step "Confirmed root/www records are proxied through Cloudflare."
}

$zone = Get-ExactZone -Name $ZoneName
Write-Step "Using zone '$($zone.name)' ($($zone.id))."

if (-not $SkipDnsCheck) {
    Test-WebProxyRecords -ZoneId $zone.id -ZoneName $zone.name
}

if (-not $SkipBotFightMode) {
    $botConfig = Invoke-CloudflareApi -Method GET -Path "/zones/$($zone.id)/bot_management"

    if ($botConfig.fight_mode) {
        Write-Step "Bot Fight Mode is already enabled."
    }
    elseif ($PSCmdlet.ShouldProcess($zone.name, "Enable Bot Fight Mode")) {
        Write-Step "Enabling Bot Fight Mode."
        Invoke-CloudflareApi -Method PUT -Path "/zones/$($zone.id)/bot_management" -Body @{ fight_mode = $true } | Out-Null
    }
}

$countryRule = New-CountryRule -Codes $CountryCodes -Action $CountryAction
Upsert-EntryPointRule -ZoneId $zone.id -Phase "http_request_firewall_custom" -Rule $countryRule

if ($RateLimitPaths.Count -gt 0) {
    foreach ($path in $RateLimitPaths) {
        $rule = New-RateLimitRule -Path $path -Requests $RateLimitRequests -PeriodSeconds $RateLimitPeriodSeconds -Action $RateLimitAction
        Upsert-EntryPointRule -ZoneId $zone.id -Phase "http_ratelimit" -Rule $rule
    }
}
else {
    Write-Warning "No rate-limit path supplied. Review Cloudflare Security Events, then rerun with -RateLimitPaths '/exact-path'."
}

if ($zone.plan -and $zone.plan.name -match "Free") {
    Write-Step "Cloudflare Free Managed Ruleset is deployed by default on Free plans; no extra API action was applied for managed rules."
}

Write-Host ""
Write-Host "Manual Webflow step still required:"
Write-Host "1. Add a reCAPTCHA element to every public form."
Write-Host "2. In Webflow Site settings > Apps & Integrations > reCAPTCHA validation, add Google reCAPTCHA v2 keys, enable validation, and publish."
Write-Host "3. If any form uses a custom action or external endpoint, protect that endpoint separately with Turnstile or direct CAPTCHA validation."
