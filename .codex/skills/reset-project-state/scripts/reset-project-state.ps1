[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9]+(?:-[a-z0-9]+)*$')]
    [string]$ProjectSlug,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$CopiedProjectPath,

    [string]$Confirmation = '',

    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

function Get-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Test-IsWithin {
    param(
        [Parameter(Mandatory = $true)][string]$Candidate,
        [Parameter(Mandatory = $true)][string]$Parent
    )

    $candidateFull = Get-FullPath $Candidate
    $parentFull = Get-FullPath $Parent
    $prefix = $parentFull + [System.IO.Path]::DirectorySeparatorChar
    return $candidateFull.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string[]]$GitArguments
    )

    $output = & git -C $Repository @GitArguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Git確認に失敗しました: git $($GitArguments -join ' ')`n$($output -join "`n")"
    }
    return (($output | Out-String).Trim())
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

$skillDirectory = Split-Path -Parent $PSScriptRoot
$starterRoot = Get-FullPath (Join-Path $skillDirectory '..\..\..')
$templateRoot = Get-FullPath (Join-Path $skillDirectory 'assets\initial-state')
$generatedRoot = Get-FullPath (Join-Path $starterRoot 'generated-projects')
$generatedProject = Get-FullPath (Join-Path $generatedRoot $ProjectSlug)
$copiedProject = Get-FullPath $CopiedProjectPath
$archiveRoot = Get-FullPath (Join-Path $starterRoot 'archives\generated-projects')

if (-not (Test-IsWithin -Candidate $generatedProject -Parent $generatedRoot)) {
    throw '初期化対象が generated-projects の範囲外です。'
}
if (-not (Test-Path -LiteralPath $generatedProject -PathType Container)) {
    throw "生成元プロジェクトが見つかりません: generated-projects/$ProjectSlug"
}
if (-not (Test-Path -LiteralPath $copiedProject -PathType Container)) {
    throw 'コピー先プロジェクトが見つかりません。'
}
if ($copiedProject.Equals($starterRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
    (Test-IsWithin -Candidate $copiedProject -Parent $starterRoot)) {
    throw 'コピー先はスターターの外部にあるディレクトリを指定してください。'
}

$gitRoot = Get-FullPath (Invoke-Git -Repository $starterRoot -GitArguments @('rev-parse', '--show-toplevel'))
if (-not $gitRoot.Equals($starterRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'スクリプトの配置先とGitリポジトリのルートが一致しません。'
}

$status = Invoke-Git -Repository $starterRoot -GitArguments @('status', '--porcelain')
if ($status) {
    throw '未コミット変更があります。初期化前に内容を整理し、コミット・プッシュしてください。'
}

$branch = Invoke-Git -Repository $starterRoot -GitArguments @('branch', '--show-current')
if (-not $branch -or $branch -in @('main', 'master')) {
    throw '既定ブランチ上では初期化できません。Issueに対応する作業ブランチを使用してください。'
}

$upstream = Invoke-Git -Repository $starterRoot -GitArguments @('rev-parse', '--abbrev-ref', '@{upstream}')
$syncCounts = Invoke-Git -Repository $starterRoot -GitArguments @('rev-list', '--left-right', '--count', 'HEAD...@{upstream}')
$counts = $syncCounts -split '\s+'
if ($counts.Count -ne 2 -or $counts[0] -ne '0' -or $counts[1] -ne '0') {
    throw "ローカルブランチとupstreamが一致しません: $syncCounts"
}

$templateMappings = [ordered]@{
    'PROJECT_BRIEF.md'       = 'PROJECT_BRIEF.md'
    'plans/MASTER_PLAN.md'   = 'plans/MASTER_PLAN.md'
    'tasks/TASKS.md'         = 'tasks/TASKS.md'
}
foreach ($relativePath in $templateMappings.Keys) {
    $templatePath = Join-Path $templateRoot $templateMappings[$relativePath]
    if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
        throw "初期状態テンプレートが見つかりません: $relativePath"
    }
}

$decisionPath = Join-Path $starterRoot 'decisions\DECISION_LOG.md'
$decisionContent = [System.IO.File]::ReadAllText($decisionPath)
$decisionPattern = '(?s)(<!-- CURRENT_PROJECT_DECISIONS_START -->).*?(<!-- CURRENT_PROJECT_DECISIONS_END -->)'
if (-not [System.Text.RegularExpressions.Regex]::IsMatch($decisionContent, $decisionPattern)) {
    throw 'DECISION_LOGに案件判断の初期化範囲がありません。'
}

$sourceFiles = Get-ChildItem -LiteralPath $generatedProject -Recurse -File -Force
if ($sourceFiles.Count -eq 0) {
    throw '生成元プロジェクトに検証対象ファイルがありません。'
}

$copyErrors = [System.Collections.Generic.List[string]]::new()
foreach ($sourceFile in $sourceFiles) {
    $relativePath = [System.IO.Path]::GetRelativePath($generatedProject, $sourceFile.FullName)
    $copiedFile = Join-Path $copiedProject $relativePath
    if (-not (Test-Path -LiteralPath $copiedFile -PathType Leaf)) {
        $copyErrors.Add("不足: $relativePath")
        continue
    }
    $sourceHash = (Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm SHA256).Hash
    $copiedHash = (Get-FileHash -LiteralPath $copiedFile -Algorithm SHA256).Hash
    if ($sourceHash -ne $copiedHash) {
        $copyErrors.Add("内容不一致: $relativePath")
    }
}
if ($copyErrors.Count -gt 0) {
    $preview = ($copyErrors | Select-Object -First 10) -join "`n"
    throw "コピー先の完全性確認に失敗しました。変更は行っていません。`n$preview"
}

Write-Output '事前検査に合格しました。'
Write-Output "- 作業ブランチ: $branch"
Write-Output "- upstream: $upstream（同期済み）"
Write-Output "- 生成元: generated-projects/$ProjectSlug"
Write-Output "- コピー確認: $($sourceFiles.Count)ファイル一致"
Write-Output '- 維持: スキル、運用文書、開発ログ、スターター共通判断、Git履歴'
Write-Output '- 初期化: PROJECT_BRIEF、MASTER_PLAN、TASKS、現在案件の判断、生成元ディレクトリ'

if (-not $Apply) {
    Write-Output "変更は行っていません。実行時の確認文字列: RESET:$ProjectSlug"
    return
}

$expectedConfirmation = "RESET:$ProjectSlug"
if ($Confirmation -cne $expectedConfirmation) {
    throw "確認文字列が一致しません。必要な文字列: $expectedConfirmation"
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archiveDirectory = Get-FullPath (Join-Path $archiveRoot "$ProjectSlug-$timestamp")
if (-not (Test-IsWithin -Candidate $archiveDirectory -Parent $archiveRoot)) {
    throw '退避先が archives/generated-projects の範囲外です。'
}
if (Test-Path -LiteralPath $archiveDirectory) {
    throw '同名の退避先が既に存在します。時間を置いて再実行してください。'
}

$snapshotDirectory = Join-Path $archiveDirectory 'starter-state'
$archivedProject = Join-Path $archiveDirectory 'generated-project'
$stateFiles = @(
    'PROJECT_BRIEF.md',
    'plans/MASTER_PLAN.md',
    'tasks/TASKS.md',
    'decisions/DECISION_LOG.md',
    'logs/DEVELOPMENT_LOG.md'
)
$projectMoved = $false

try {
    New-Item -ItemType Directory -Path $snapshotDirectory -Force | Out-Null
    foreach ($relativePath in $stateFiles) {
        $sourcePath = Join-Path $starterRoot $relativePath
        $snapshotPath = Join-Path $snapshotDirectory $relativePath
        $snapshotParent = Split-Path -Parent $snapshotPath
        New-Item -ItemType Directory -Path $snapshotParent -Force | Out-Null
        Copy-Item -LiteralPath $sourcePath -Destination $snapshotPath
    }

    Move-Item -LiteralPath $generatedProject -Destination $archivedProject
    $projectMoved = $true

    foreach ($relativePath in $templateMappings.Keys) {
        $templatePath = Join-Path $templateRoot $templateMappings[$relativePath]
        $destinationPath = Join-Path $starterRoot $relativePath
        Write-Utf8File -Path $destinationPath -Content ([System.IO.File]::ReadAllText($templatePath))
    }

    $clearedDecisionContent = [System.Text.RegularExpressions.Regex]::Replace(
        $decisionContent,
        $decisionPattern,
        { param($match)
            $match.Groups[1].Value + "`r`n`r`n| 日付 | 判断 | 理由 | 他の候補 | 影響 |`r`n|---|---|---|---|---|`r`n| - | 次の開発開始時に記録 | - | - | - |`r`n`r`n" + $match.Groups[2].Value
        }
    )
    Write-Utf8File -Path $decisionPath -Content $clearedDecisionContent

    $logPath = Join-Path $starterRoot 'logs\DEVELOPMENT_LOG.md'
    $copyName = Split-Path -Leaf $copiedProject
    $archiveRelative = [System.IO.Path]::GetRelativePath($starterRoot, $archiveDirectory).Replace('\', '/')
    $logEntry = "`r`n`r`n## $(Get-Date -Format 'yyyy-MM-dd'): 案件状態を初期化`r`n`r`n- 対象案件: $ProjectSlug`r`n- コピー確認: スターター外の $copyName に $($sourceFiles.Count)ファイルが一致`r`n- 実施内容: 案件固有の要件、計画、タスク、判断を初期状態へ戻し、生成元を $archiveRelative へ復旧可能な形で退避`r`n- 維持内容: スキル、運用文書、過去の開発ログ、スターター共通判断、Git履歴`r`n- 次の操作: 差分を確認してコミット・プッシュし、人のレビュー用PRを作成`r`n"
    [System.IO.File]::AppendAllText($logPath, $logEntry, [System.Text.UTF8Encoding]::new($false))
}
catch {
    foreach ($relativePath in $stateFiles) {
        $snapshotPath = Join-Path $snapshotDirectory $relativePath
        if (Test-Path -LiteralPath $snapshotPath -PathType Leaf) {
            Copy-Item -LiteralPath $snapshotPath -Destination (Join-Path $starterRoot $relativePath) -Force
        }
    }
    if ($projectMoved -and (Test-Path -LiteralPath $archivedProject) -and -not (Test-Path -LiteralPath $generatedProject)) {
        Move-Item -LiteralPath $archivedProject -Destination $generatedProject
    }
    throw "初期化中に失敗したため、案件状態を復元しました。退避データは確認用に残しています。`n$($_.Exception.Message)"
}

Write-Output '案件状態を初期化しました。'
Write-Output "- 退避先: $([System.IO.Path]::GetRelativePath($starterRoot, $archiveDirectory).Replace('\', '/'))"
Write-Output '- 次の操作: git diffを確認し、テスト後にコミット・プッシュしてください。'
