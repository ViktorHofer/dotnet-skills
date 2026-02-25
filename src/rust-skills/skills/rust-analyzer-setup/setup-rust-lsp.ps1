<#
.SYNOPSIS
    Configure rust-analyzer LSP for Copilot CLI (Windows PowerShell).
.DESCRIPTION
    1. Creates ~/.copilot/ if it doesn't exist
    2. Writes (or merges) lsp-config.json with the rust-analyzer entry
    3. Checks that rust-analyzer is available on PATH
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$ConfigDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:USERPROFILE ".copilot" }
$LspConfig = Join-Path $ConfigDir "lsp-config.json"

$RustLspEntry = @'
{
    "lspServers": {
        "rust": {
            "command": "rust-analyzer",
            "args": [],
            "fileExtensions": {
                ".rs": "rust"
            }
        }
    }
}
'@

Write-Host "=== Copilot CLI - rust-analyzer LSP setup ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create config directory
if (-not (Test-Path $ConfigDir)) {
    Write-Host "[1/3] Creating config directory: $ConfigDir"
    New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null
} else {
    Write-Host "[1/3] Config directory exists: $ConfigDir"
}

# Step 2: Write or merge lsp-config.json
if (-not (Test-Path $LspConfig)) {
    Write-Host "[2/3] Creating $LspConfig"
    $RustLspEntry | Set-Content -Path $LspConfig -Encoding UTF8
} elseif ((Get-Content $LspConfig -Raw) -match '"rust"') {
    Write-Host "[2/3] $LspConfig already contains a 'rust' server entry - skipping"
    Write-Host "       Review manually if /lsp test rust fails."
} else {
    Write-Host "[2/3] $LspConfig exists but has no 'rust' entry."
    Write-Host "       Manually add to lspServers:"
    Write-Host ""
    Write-Host '       "rust": {'
    Write-Host '           "command": "rust-analyzer",'
    Write-Host '           "args": [],'
    Write-Host '           "fileExtensions": { ".rs": "rust" }'
    Write-Host '       }'
    Write-Host ""
}

# Step 3: Check rust-analyzer
Write-Host -NoNewline "[3/3] Checking rust-analyzer... "
$ra = Get-Command rust-analyzer -ErrorAction SilentlyContinue
if ($ra) {
    $ver = & rust-analyzer --version 2>&1 | Select-Object -First 1
    Write-Host "found: $ver" -ForegroundColor Green
} else {
    Write-Host "NOT FOUND" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Install via:  rustup component add rust-analyzer"
    Write-Host "  Or download:  https://github.com/rust-lang/rust-analyzer/releases"
    exit 1
}

Write-Host ""
Write-Host "Done. Verify in Copilot CLI with:"
Write-Host "  /lsp show"
Write-Host "  /lsp test rust"
