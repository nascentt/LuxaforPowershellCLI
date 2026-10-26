# PowerShell module for the Luxafor Webhook API.
# This file contains no device IDs; pass -LuxID or use a caller-owned config file.

$script:DefaultApiBaseUrl = 'https://api.luxafor.com'
$script:LuxaforActionPath = @{
    Solid   = '/webhook/v1/actions/solid_color'
    Blink   = '/webhook/v1/actions/blink'
    Pattern = '/webhook/v1/actions/pattern'
}

# Keep device IDs outside the module so the same code can be reused by
# interactive users, scheduled jobs, and scripts controlling multiple flags.
$script:LuxaforColors = @('red', 'green', 'yellow', 'blue', 'white', 'cyan', 'magenta')
$script:LuxaforPatterns = @('police', 'traffic lights', 'random 1', 'random 2', 'random 3', 'random 4', 'random 5')
$script:LuxaforWindowsPatterns = @('rainbow', 'sea', 'white wave', 'synthetic')

# Keeping request construction in one function makes new actions consistent and
# gives every mutating command the same WhatIf and error-handling behavior.
function Invoke-LuxaforAction {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][ValidateSet('Solid', 'Blink', 'Pattern')][string]$Action,
        [Parameter(Mandatory)][string]$LuxID,
        [Parameter(Mandatory)][hashtable]$ActionFields,
        [string]$ApiBaseUrl = $script:DefaultApiBaseUrl
    )

    if ([string]::IsNullOrWhiteSpace($LuxID)) {
        throw 'A Luxafor webhook ID is required.'
    }

    $body = @{ userId = $LuxID; actionFields = $ActionFields } | ConvertTo-Json -Depth 3
    $request = @{
        Uri         = '{0}{1}' -f $ApiBaseUrl.TrimEnd('/'), $script:LuxaforActionPath[$Action]
        Method      = 'Post'
        Body        = $body
        ContentType = 'application/json'
        ErrorAction = 'Stop'
    }

    if ($PSCmdlet.ShouldProcess($LuxID, "$Action Luxafor action")) {
        Invoke-RestMethod @request
    }
}

function Set-LuxaforColor {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Set-Color', 'Set-Colour', 'SetColor', 'SetColour')]
    param(
        [Parameter(Mandatory)][Alias('Colour')][string]$Color,
        [Parameter(Mandatory)][string]$LuxID,
        [string]$ApiBaseUrl = $script:DefaultApiBaseUrl
    )

    if ($script:LuxaforColors -notcontains $Color.ToLowerInvariant()) {
        throw "Invalid color '$Color'. Valid colors: $($script:LuxaforColors -join ', ')."
    }
    Invoke-LuxaforAction -Action Solid -LuxID $LuxID -ActionFields @{ color = $Color.ToLowerInvariant() } -ApiBaseUrl $ApiBaseUrl -WhatIf:$WhatIfPreference
}

function Set-LuxaforCustomColor {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Set-CustomColor', 'Set-CustomColour', 'SetCustomColor', 'SetCustomColour')]
    param(
        [Parameter(Mandatory)][Alias('Colour')][string]$Color,
        [Parameter(Mandatory)][string]$LuxID,
        [string]$ApiBaseUrl = $script:DefaultApiBaseUrl
    )

    # Added for automation that needs colors beyond the API's named colors.
    # The stricter expression also fixes the upstream character-class bug.
    if ($Color -notmatch '^[0-9A-Fa-f]{6}$') {
        throw "Invalid custom color '$Color'. Use exactly six hexadecimal characters, for example FF8800."
    }
    Invoke-LuxaforAction -Action Solid -LuxID $LuxID -ActionFields @{ color = 'custom'; custom_color = $Color.ToUpperInvariant() } -ApiBaseUrl $ApiBaseUrl -WhatIf:$WhatIfPreference
}

function Set-LuxaforOff {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Set-Off', 'SetOff')]
    param(
        [Parameter(Mandatory)][string]$LuxID,
        [string]$ApiBaseUrl = $script:DefaultApiBaseUrl
    )

    # Added as a named operation for monitoring scripts; reuse the custom-color
    # path so off has identical request and WhatIf behavior.
    Set-LuxaforCustomColor -LuxID $LuxID -Color '000000' -ApiBaseUrl $ApiBaseUrl -WhatIf:$WhatIfPreference
}

function Set-LuxaforBlink {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Set-Blink', 'SetBlink')]
    param(
        [Parameter(Mandatory)][Alias('Colour')][string]$Color,
        [Parameter(Mandatory)][string]$LuxID,
        [string]$ApiBaseUrl = $script:DefaultApiBaseUrl
    )

    if ($script:LuxaforColors -notcontains $Color.ToLowerInvariant()) {
        throw "Invalid color '$Color'. Valid colors: $($script:LuxaforColors -join ', ')."
    }
    Invoke-LuxaforAction -Action Blink -LuxID $LuxID -ActionFields @{ color = $Color.ToLowerInvariant() } -ApiBaseUrl $ApiBaseUrl -WhatIf:$WhatIfPreference
}

function Set-LuxaforPattern {
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Set-Pattern', 'SetPattern')]
    param(
        [Parameter(Mandatory)][string]$Pattern,
        [Parameter(Mandatory)][string]$LuxID,
        [switch]$IncludeWindowsOnly,
        [string]$ApiBaseUrl = $script:DefaultApiBaseUrl
    )

    $validPatterns = @($script:LuxaforPatterns)
    if ($IncludeWindowsOnly) { $validPatterns += $script:LuxaforWindowsPatterns }
    if ($validPatterns -notcontains $Pattern) {
        throw "Invalid pattern '$Pattern'. Valid patterns: $($validPatterns -join ', ')."
    }
    Invoke-LuxaforAction -Action Pattern -LuxID $LuxID -ActionFields @{ pattern = $Pattern } -ApiBaseUrl $ApiBaseUrl -WhatIf:$WhatIfPreference
}

function Get-LuxaforColors {
    [Alias('Get-Colors', 'Get-Colours', 'ListColors', 'ListColours')]
    param()
    $script:LuxaforColors
}

function Get-LuxaforPatterns {
    [Alias('Get-Patterns', 'ListPatterns')]
    param([switch]$IncludeWindowsOnly)
    $script:LuxaforPatterns
    if ($IncludeWindowsOnly) { $script:LuxaforWindowsPatterns }
}

Export-ModuleMember -Function @(
    'Get-LuxaforColors', 'Get-LuxaforPatterns',
    'Set-LuxaforBlink', 'Set-LuxaforColor', 'Set-LuxaforCustomColor', 'Set-LuxaforOff', 'Set-LuxaforPattern'
) -Alias @(
    'Get-Colors', 'Get-Colours', 'Get-Patterns', 'ListColors', 'ListColours',
    'Set-Color', 'Set-Colour', 'SetColor', 'SetColour',
    'Set-CustomColor', 'Set-CustomColour', 'SetCustomColor', 'SetCustomColour',
    'Set-Off', 'SetOff', 'Set-Blink', 'SetBlink', 'Set-Pattern', 'SetPattern'
)
