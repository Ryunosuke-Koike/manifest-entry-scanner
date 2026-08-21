param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9]+(?:-[a-z0-9]+)*$')]
    [string]$ProjectSlug,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName
)

$ErrorActionPreference = 'Stop'

$skillDirectory = Split-Path -Parent $PSScriptRoot
$templateDirectory = Join-Path $skillDirectory 'assets\project-template'
$starterRoot = Resolve-Path (Join-Path $skillDirectory '..\..\..')

$resolvedOutputRoot = [System.IO.Path]::GetFullPath((Join-Path $starterRoot 'generated-projects'))
$destination = [System.IO.Path]::GetFullPath((Join-Path $resolvedOutputRoot $ProjectSlug))
$expectedPrefix = $resolvedOutputRoot.TrimEnd('\') + '\'

if (-not $destination.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw '出力先がスターター内の generated-projects の範囲外です。'
}

if (-not (Test-Path -LiteralPath $templateDirectory)) {
    throw "雛形が見つかりません: $templateDirectory"
}

if (Test-Path -LiteralPath $destination) {
    throw "同名の出力先が既に存在します。上書きしません: $destination"
}

New-Item -ItemType Directory -Path $resolvedOutputRoot -Force | Out-Null
Copy-Item -LiteralPath $templateDirectory -Destination $destination -Recurse

$textExtensions = @('.md', '.txt', '.json', '.yaml', '.yml', '.toml', '.env', '.example')
Get-ChildItem -LiteralPath $destination -Recurse -File -Force | ForEach-Object {
    if ($textExtensions -contains $_.Extension -or $_.Name -eq '.gitignore') {
        $content = [System.IO.File]::ReadAllText($_.FullName)
        $content = $content.Replace('__PROJECT_NAME__', $ProjectName)
        $content = $content.Replace('__PROJECT_SLUG__', $ProjectSlug)
        [System.IO.File]::WriteAllText($_.FullName, $content, [System.Text.UTF8Encoding]::new($false))
    }
}

Write-Output $destination
