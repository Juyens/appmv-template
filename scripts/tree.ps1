$ErrorActionPreference = 'Stop'

# Sin esto, en un Windows en espanol las coordenadas salen como y="32,2" y el
# SVG queda invalido. Afecta a todos los -f de este script.
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture

$repo = Split-Path $PSScriptRoot -Parent
Set-Location $repo

$Source    = 'docs/images/tree.txt'
$LightFile = 'docs/images/tree.svg'
$DarkFile  = 'docs/images/tree-dark.svg'

$CharWidth  = 7.83
$LineHeight = 19.0
$Padding    = 18.0
$FontSize   = 13
$FontStack  = 'ui-monospace, SFMono-Regular, Menlo, Consolas, monospace'

# Paletas de GitHub. La clara es la de por defecto; la oscura se sirve por
# prefers-color-scheme desde el <picture> del CONTRIBUTING.
$Themes = @(
    [pscustomobject]@{
        File   = $LightFile
        Canvas = '#f6f8fa'
        Border = '#d0d7de'
        Glyph  = '#afb8c1'
        Folder = '#0969da'
        File2  = '#1f2328'
        Text   = '#6e7781'
    }
    [pscustomobject]@{
        File   = $DarkFile
        Canvas = '#0d1117'
        Border = '#30363d'
        Glyph  = '#484f58'
        Folder = '#58a6ff'
        File2  = '#e6edf3'
        Text   = '#8b949e'
    }
)

if (-not (Test-Path $Source)) {
    Write-Host ''
    Write-Host ("ERROR: {0} does not exist." -f $Source) -ForegroundColor Red
    Write-Host 'That file is the source of the tree. Edit it, then run this script.'
    Write-Host ''
    exit 1
}

# Los caracteres de dibujo se construyen por codigo para que este script siga
# siendo ASCII puro: PowerShell 5.1 corrompe los acentos en archivos sin BOM.
$Branch   = [char]0x251C  # |-
$LastOne  = [char]0x2514  # L-
$Dash     = [char]0x2500  # -
$Vertical = [char]0x2502  # |

$namePattern = '^(.*?[{0}{1}]{2}{2} )(\S+)(\s*)(.*)$' -f $Branch, $LastOne, $Dash
$restPattern = '^([{0}\s]*)(.*)$' -f $Vertical

$lines = [System.IO.File]::ReadAllLines((Join-Path $repo $Source), [System.Text.Encoding]::UTF8)
while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[-1])) {
    $lines = $lines[0..($lines.Count - 2)]
}

$longest = ($lines | Measure-Object -Property Length -Maximum).Maximum
$width   = [math]::Round($longest * $CharWidth + $Padding * 2)
$height  = [math]::Round($lines.Count * $LineHeight + $Padding * 2)

function Get-Escaped {
    param([string]$Text)
    $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
}

function Get-Spans {
    param([string]$Line, $Theme)

    if ($Line -eq 'appmv/') {
        return '<tspan fill="{0}">{1}</tspan>' -f $Theme.Folder, (Get-Escaped $Line)
    }

    if ($Line -match $namePattern) {
        $prefix = $Matches[1]
        $name   = $Matches[2]
        $gap    = $Matches[3]
        $desc   = $Matches[4]

        if ($name.EndsWith('/')) { $nameColor = $Theme.Folder } else { $nameColor = $Theme.File2 }

        $spans = '<tspan fill="{0}">{1}</tspan>' -f $Theme.Glyph, (Get-Escaped $prefix)
        $spans += '<tspan fill="{0}">{1}</tspan>' -f $nameColor, (Get-Escaped $name)
        if ($gap -or $desc) {
            $spans += '<tspan fill="{0}">{1}</tspan>' -f $Theme.Text, (Get-Escaped ($gap + $desc))
        }
        return $spans
    }

    $null = $Line -match $restPattern
    $prefix = $Matches[1]
    $rest   = $Matches[2]

    $spans = '<tspan fill="{0}">{1}</tspan>' -f $Theme.Glyph, (Get-Escaped $prefix)
    if ($rest) {
        $spans += '<tspan fill="{0}">{1}</tspan>' -f $Theme.Text, (Get-Escaped $rest)
    }
    return $spans
}

Write-Host ''
Write-Host ('Drawing {0} lines...' -f $lines.Count) -ForegroundColor Cyan
Write-Host ''

foreach ($theme in $Themes) {
    $svg = New-Object System.Text.StringBuilder

    [void]$svg.AppendLine(('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {0} {1}" width="{0}" height="{1}">' -f $width, $height))
    [void]$svg.AppendLine(('  <rect width="{0}" height="{1}" rx="8" fill="{2}" stroke="{3}"/>' -f $width, $height, $theme.Canvas, $theme.Border))

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $y = [math]::Round($Padding + $LineHeight * ($i + 0.75), 1)
        $spans = Get-Spans -Line $lines[$i] -Theme $theme
        [void]$svg.AppendLine(('  <text xml:space="preserve" x="{0}" y="{1}" font-family="{2}" font-size="{3}">{4}</text>' -f $Padding, $y, $FontStack, $FontSize, $spans))
    }

    [void]$svg.AppendLine('</svg>')

    $target = Join-Path $repo $theme.File
    [System.IO.File]::WriteAllText($target, $svg.ToString(), (New-Object System.Text.UTF8Encoding($false)))

    Write-Host ('  {0}' -f $theme.File) -ForegroundColor Green
}

Write-Host ''
Write-Host ('Done. {0} x {1} px.' -f $width, $height) -ForegroundColor Green
Write-Host ''
