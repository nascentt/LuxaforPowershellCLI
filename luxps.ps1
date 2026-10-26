# Luxafor PowerShell CLI using the Luxafor Webhook REST API.
# Modified from makcuber/LuxaforPowershellCLI; no device IDs are stored in this repository.

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$LuxID,
    [string]$ConfigPath,
    [string]$ApiBaseUrl = 'https://api.luxafor.com',
    [Alias('Color')][string]$Colour,
    [Alias('CustomColor')][string]$CustomColour,
    [string]$Blink,
    [string]$Pattern,
    [switch]$Off,
    [switch]$Service,
    [switch]$Help,
    [switch]$IncludeWindowsOnly,
    [string]$LockColor = 'red',
    [string]$OnlineColor = 'green'
)

Import-Module (Join-Path $PSScriptRoot 'LuxaforPowershellCLI.psm1') -Force

# Retain the upstream five-second service interval; it is intentionally not
# exposed as another CLI setting.
$scanPeriod = 5

# Added script-relative configuration. Resolve it after parameter binding because
# PSScriptRoot can be empty while Windows PowerShell evaluates parameter defaults.
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $PSScriptRoot 'luxid.conf'
}

function Resolve-LuxaforId {
    # Added runtime ID selection so webhook IDs are not committed and one CLI
    # copy can control different flags.
    if (-not [string]::IsNullOrWhiteSpace($LuxID)) { return $LuxID.Trim() }
    if (Test-Path -LiteralPath $ConfigPath -PathType Leaf) {
        $id = (Get-Content -LiteralPath $ConfigPath -Raw -ErrorAction Stop).Trim()
        if ($id -and $id -notmatch '\r|\n') { return $id }
        if ($id -match '\r|\n') { throw 'The CLI configuration file must contain exactly one webhook ID.' }
    }
    throw "No Luxafor ID supplied. Use -LuxID or create '$ConfigPath'."
}

function Show-Help {
    @"
Luxafor PowerShell CLI

Commands:
  -colour red                     Set a named color
  -customcolour FF8800            Set a six-digit hexadecimal color
  -blink yellow                   Blink a named color
  -pattern police                 Run a pattern
  -off                            Turn the flag off
  -service                        Set LockColor/OnlineColor based on screen lock state
  -help                           Show this help

Options:
  -LuxID <id>                     Webhook ID; takes precedence over -ConfigPath
  -ConfigPath <path>              Text file containing one webhook ID
  -ApiBaseUrl <url>               API host; defaults to https://api.luxafor.com
  -IncludeWindowsOnly             Include Windows-only patterns
  -WhatIf                         Show actions without calling the API
"@ | Write-Output
}

$selectedActions = @($Colour, $CustomColour, $Blink, $Pattern, $Off, $Service, $Help) | Where-Object { $_ }
if ($selectedActions.Count -eq 0 -or $Help) { Show-Help; return }
if ($selectedActions.Count -gt 1) { throw 'Specify only one Luxafor action.' }

$id = Resolve-LuxaforId
if ($Colour) { Set-LuxaforColor -LuxID $id -Color $Colour -ApiBaseUrl $ApiBaseUrl -WhatIf:$WhatIfPreference }
elseif ($CustomColour) { Set-LuxaforCustomColor -LuxID $id -Color $CustomColour -ApiBaseUrl $ApiBaseUrl -WhatIf:$WhatIfPreference }
elseif ($Blink) { Set-LuxaforBlink -LuxID $id -Color $Blink -ApiBaseUrl $ApiBaseUrl -WhatIf:$WhatIfPreference }
elseif ($Pattern) { Set-LuxaforPattern -LuxID $id -Pattern $Pattern -ApiBaseUrl $ApiBaseUrl -IncludeWindowsOnly:$IncludeWindowsOnly -WhatIf:$WhatIfPreference }
elseif ($Off) { Set-LuxaforOff -LuxID $id -ApiBaseUrl $ApiBaseUrl -WhatIf:$WhatIfPreference }
elseif ($Service) {
        while ($true) {
            $user = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue | Select-Object -ExpandProperty UserName
            $locked = [bool]($user -and (Get-Process -Name logonui -ErrorAction SilentlyContinue))
            $color = if ($locked) { $LockColor } else { $OnlineColor }
            Set-LuxaforColor -LuxID $id -Color $color -ApiBaseUrl $ApiBaseUrl -WhatIf:$WhatIfPreference
            Start-Sleep -Seconds $scanPeriod
        }
    }
