# LuxaforPowershellCLI

PowerShell CLI and module for controlling Luxafor flags through the [Luxafor Webhook API](https://luxafor.com/webhook-api/).

This version keeps device IDs and site-specific automation outside the project. It can be used from scheduled scripts, monitoring systems, or interactively.

- Device IDs are supplied through `-LuxID` or a caller-owned configuration file instead of being embedded in the script.
- Configuration paths are resolved beside the script, so the CLI does not depend on the current working directory.
- API calls are centralized in a reusable module, avoiding duplicated request construction for each action.
- Custom hexadecimal colors and turning a flag off are supported for monitoring and workflow automation.
- Mutating commands support `-WhatIf`, allowing scheduled scripts to be tested without contacting the API.
- The public CLI retains the original single-ID text configuration model; multi-device and owner mappings remain caller-specific.
- Legacy command and function names remain available so existing scripts can migrate incrementally.

## Install

1. Clone or download this repository.
2. Create a file named `luxid.conf` beside `luxps.ps1` containing one webhook ID, or pass `-LuxID` at runtime.
3. Run PowerShell 5.1 or later.

The included `luxid.conf` is ignored by Git. Never commit a real webhook ID.

## CLI examples

```powershell
.\luxps.ps1 -colour red -LuxID 'your-webhook-id'
.\luxps.ps1 -customcolour FF8800 -LuxID 'your-webhook-id'
.\luxps.ps1 -blink yellow -LuxID 'your-webhook-id'
.\luxps.ps1 -pattern police -LuxID 'your-webhook-id'
.\luxps.ps1 -off -LuxID 'your-webhook-id'
.\luxps.ps1 -colour green -LuxID 'your-webhook-id' -WhatIf
```

`-ConfigPath` accepts a text file containing one webhook ID. Multi-device configuration and owner mappings are intentionally left to calling scripts.

## Module examples

```powershell
Import-Module .\LuxaforPowershellCLI.psm1
Set-LuxaforColor -LuxID $id -Color green
Set-LuxaforCustomColor -LuxID $id -Color FF8800
Set-LuxaforBlink -LuxID $id -Color yellow
Set-LuxaforOff -LuxID $id
```

All mutating commands support `-WhatIf`. Calling scripts can import the module directly and provide each webhook ID explicitly.

## Notes

- Named colors are limited to the colors documented by the Webhook API.
- Custom colors require exactly six hexadecimal characters, without a leading `#`.
- The service command is intended for Windows and runs until interrupted with `Ctrl+C`.
- Use `-ApiBaseUrl` when targeting an alternate API host; it defaults to `https://api.luxafor.com`.
