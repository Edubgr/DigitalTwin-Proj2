[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$Port = 'COM7',
    [switch]$ListPorts
)

$ErrorActionPreference = 'Stop'
$exitCode = 1

try {
    $pio = Get-Command platformio, pio -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty Source

    if (-not $pio) {
        $candidate = Join-Path $HOME '.platformio\penv\Scripts\platformio.exe'
        if (Test-Path -LiteralPath $candidate) {
            $pio = $candidate
        }
    }

    if (-not $pio) {
        throw 'PlatformIO was not found. Install the PlatformIO IDE extension in VS Code, open this project, and wait for its setup to finish.'
    }

    if ($ListPorts) {
        & $pio device list
        $exitCode = $LASTEXITCODE
    }
    else {
        Write-Host "Building and uploading espcontrol.ino to $Port..."
        & $pio run --project-dir $PSScriptRoot -e esp32dev -t upload --upload-port $Port
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) {
            Write-Host 'Firmware uploaded successfully. The ESP32 has been reset.'
        }
        else {
            Write-Warning "Upload failed. Close the backend and any serial monitors using $Port, reconnect the USB cable, and check the port with -ListPorts. If the uploader remains at Connecting, hold BOOT until writing starts."
        }
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

exit $exitCode
