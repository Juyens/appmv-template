param(
    [string]$Delivery
)

$ErrorActionPreference = 'Stop'

$Period     = '202620'
$CourseCode = '1acc0238'
$Nrc        = '13980'
$Startup    = 'nombrestartup'

$Deliveries = @('av1', 'tb1', 'av2', 'tb2')

$ChaptersByDelivery = @{
    'av1' = @(
        'README.md'
        'docs/chapter_1.md'
        'docs/chapter_2.md'
        'docs/closing.md'
    )
    'tb1' = @(
        'README.md'
        'docs/chapter_1.md'
        'docs/chapter_2.md'
        'docs/chapter_3.md'
        'docs/chapter_4.md'
        'docs/closing.md'
    )
    'av2' = @(
        'README.md'
        'docs/chapter_1.md'
        'docs/chapter_2.md'
        'docs/chapter_3.md'
        'docs/chapter_4.md'
        'docs/closing.md'
    )
    'tb2' = @(
        'README.md'
        'docs/chapter_1.md'
        'docs/chapter_2.md'
        'docs/chapter_3.md'
        'docs/chapter_4.md'
        'docs/closing.md'
    )
}

$ConfigFiles = @(
    'config/formato.yaml'
    'config/apa7.tex'
    'config/caratula.tex'
    'config/apa.csl'
    'referencias.bib'
)

function Show-Usage {
    Write-Host ''
    Write-Host 'Usage:  .\scripts\build.ps1 <delivery>' -ForegroundColor Yellow
    Write-Host ''
    Write-Host ('  <delivery> must be one of: {0}' -f ($Deliveries -join ', '))
    Write-Host '  It becomes the last part of the PDF file name.'
    Write-Host ''
    Write-Host '  Example:  .\scripts\build.ps1 tb1'
    Write-Host ('  Produces: upc-pre-{0}-{1}-{2}-{3}-report-tb1.pdf' -f $Period, $CourseCode, $Nrc, $Startup)
    Write-Host ''
}

if ([string]::IsNullOrWhiteSpace($Delivery)) {
    Write-Host ''
    Write-Host 'ERROR: no delivery given.' -ForegroundColor Red
    Show-Usage
    exit 1
}

$Delivery = $Delivery.Trim().ToLower()

if ($Deliveries -notcontains $Delivery) {
    Write-Host ''
    Write-Host ("ERROR: '{0}' is not a valid delivery." -f $Delivery) -ForegroundColor Red
    Show-Usage
    exit 1
}

$Chapters = $ChaptersByDelivery[$Delivery]

$repo = Split-Path $PSScriptRoot -Parent
Set-Location $repo

$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') +
            ';' +
            [System.Environment]::GetEnvironmentVariable('Path', 'User')

foreach ($tool in @('pandoc', 'xelatex')) {
    if ($null -eq (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host ''
        Write-Host ("ERROR: {0} is not installed." -f $tool) -ForegroundColor Red
        Write-Host 'Run this first:  .\scripts\dependencies.ps1'
        Write-Host ''
        exit 1
    }
}

$missing = @()
foreach ($file in ($Chapters + $ConfigFiles)) {
    if (-not (Test-Path $file)) { $missing += $file }
}

if ($missing.Count -gt 0) {
    Write-Host ''
    Write-Host 'ERROR: these files are missing:' -ForegroundColor Red
    foreach ($file in $missing) { Write-Host ('  - {0}' -f $file) }
    Write-Host ''
    exit 1
}

if (-not (Test-Path 'dist')) { New-Item -ItemType Directory 'dist' | Out-Null }

$output = "dist/upc-pre-$Period-$CourseCode-$Nrc-$Startup-report-$Delivery.pdf"

Write-Host ''
Write-Host ('Building {0} from {1} files...' -f $Delivery, $Chapters.Count) -ForegroundColor Cyan
foreach ($file in $Chapters) { Write-Host ('  {0}' -f $file) -ForegroundColor DarkGray }
Write-Host ''

pandoc $Chapters `
    --metadata-file=config/formato.yaml `
    --include-in-header=config/apa7.tex `
    --include-before-body=config/caratula.tex `
    --citeproc `
    --csl=config/apa.csl `
    --bibliography=referencias.bib `
    --pdf-engine=xelatex `
    --top-level-division=section `
    --resource-path=".;docs" `
    --syntax-highlighting=tango `
    -o $output

if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'Build failed. Read the LaTeX error above.' -ForegroundColor Red
    Write-Host ''
    exit 1
}

$sizeKb = [math]::Round((Get-Item $output).Length / 1KB)

Write-Host ''
Write-Host ('Done -> {0}  ({1} KB)' -f $output, $sizeKb) -ForegroundColor Green
Write-Host ''
