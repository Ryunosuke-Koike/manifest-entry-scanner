$ErrorActionPreference = 'Stop'

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $Condition) {
        throw "テスト失敗: $Message"
    }
}

function Write-TestFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )
    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-TestGit {
    param(
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )
    $output = & git -C $Repository @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "テスト用Git操作に失敗しました: git $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return $output
}

function Assert-Throws {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [Parameter(Mandatory = $true)][string]$ExpectedText
    )
    try {
        & $Action
    }
    catch {
        Assert-True -Condition ($_.Exception.Message -like "*$ExpectedText*") -Message "想定した停止理由ではありません: $($_.Exception.Message)"
        return
    }
    throw "テスト失敗: 例外が必要でした: $ExpectedText"
}

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sourceSkill = Join-Path $repositoryRoot '.codex\skills\reset-project-state'
$temporaryParent = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\', '/')
$testRoot = Join-Path $temporaryParent ("codex-reset-project-state-test-" + [guid]::NewGuid().ToString('N'))
$fixtureRepository = Join-Path $testRoot 'starter'
$copiedProject = Join-Path $testRoot 'copied\sample-app'
$bareRemote = Join-Path $testRoot 'remote.git'

try {
    New-Item -ItemType Directory -Path $fixtureRepository -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $fixtureRepository '.codex\skills') -Force | Out-Null
    Copy-Item -LiteralPath $sourceSkill -Destination (Join-Path $fixtureRepository '.codex\skills\reset-project-state') -Recurse

    Write-TestFile -Path (Join-Path $fixtureRepository 'AGENTS.md') -Content '# テスト用スターター'
    Write-TestFile -Path (Join-Path $fixtureRepository '.gitignore') -Content "/archives/generated-projects/`n"
    Write-TestFile -Path (Join-Path $fixtureRepository 'PROJECT_BRIEF.md') -Content "# 案件固有要件`n"
    Write-TestFile -Path (Join-Path $fixtureRepository 'plans\MASTER_PLAN.md') -Content "# 案件固有計画`n"
    Write-TestFile -Path (Join-Path $fixtureRepository 'tasks\TASKS.md') -Content "# 案件固有タスク`n"
    Write-TestFile -Path (Join-Path $fixtureRepository 'decisions\DECISION_LOG.md') -Content "# 判断`n`n## 共通`n`n維持する判断`n`n<!-- CURRENT_PROJECT_DECISIONS_START -->`n`n消去する判断`n`n<!-- CURRENT_PROJECT_DECISIONS_END -->`n"
    Write-TestFile -Path (Join-Path $fixtureRepository 'logs\DEVELOPMENT_LOG.md') -Content "# 開発ログ`n`n維持する過去ログ`n"
    Write-TestFile -Path (Join-Path $fixtureRepository 'generated-projects\sample-app\PROJECT_ROOT.md') -Content "# ルート`n"
    Write-TestFile -Path (Join-Path $fixtureRepository 'generated-projects\sample-app\.gitignore') -Content ".env`n"
    Write-TestFile -Path (Join-Path $fixtureRepository 'generated-projects\sample-app\src\app.txt') -Content "成果物`n"
    New-Item -ItemType Directory -Path (Split-Path -Parent $copiedProject) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $fixtureRepository 'generated-projects\sample-app') -Destination $copiedProject -Recurse

    & git init --bare $bareRemote | Out-Null
    & git init -b main $fixtureRepository | Out-Null
    Invoke-TestGit -Repository $fixtureRepository -Arguments @('config', 'user.name', 'Codex Test') | Out-Null
    Invoke-TestGit -Repository $fixtureRepository -Arguments @('config', 'user.email', 'codex-test@example.invalid') | Out-Null
    Invoke-TestGit -Repository $fixtureRepository -Arguments @('add', '--', 'AGENTS.md', '.gitignore', 'PROJECT_BRIEF.md', 'plans/MASTER_PLAN.md', 'tasks/TASKS.md', 'decisions/DECISION_LOG.md', 'logs/DEVELOPMENT_LOG.md', 'generated-projects/sample-app', '.codex/skills/reset-project-state') | Out-Null
    Invoke-TestGit -Repository $fixtureRepository -Arguments @('commit', '-m', 'テスト基準点') | Out-Null
    Invoke-TestGit -Repository $fixtureRepository -Arguments @('remote', 'add', 'origin', $bareRemote) | Out-Null
    Invoke-TestGit -Repository $fixtureRepository -Arguments @('push', '-u', 'origin', 'main') | Out-Null

    $scriptPath = Join-Path $fixtureRepository '.codex\skills\reset-project-state\scripts\reset-project-state.ps1'
    Assert-Throws -ExpectedText '既定ブランチ上では初期化できません' -Action {
        & $scriptPath -ProjectSlug 'sample-app' -CopiedProjectPath $copiedProject | Out-Null
    }

    Invoke-TestGit -Repository $fixtureRepository -Arguments @('switch', '-c', 'feature/test-reset') | Out-Null
    Invoke-TestGit -Repository $fixtureRepository -Arguments @('push', '-u', 'origin', 'feature/test-reset') | Out-Null

    Invoke-TestGit -Repository $fixtureRepository -Arguments @('commit', '--allow-empty', '-m', '同期ずれを作る') | Out-Null
    Assert-Throws -ExpectedText 'ローカルブランチとupstreamが一致しません' -Action {
        & $scriptPath -ProjectSlug 'sample-app' -CopiedProjectPath $copiedProject | Out-Null
    }
    Invoke-TestGit -Repository $fixtureRepository -Arguments @('push') | Out-Null

    $preflight = & $scriptPath -ProjectSlug 'sample-app' -CopiedProjectPath $copiedProject
    Assert-True -Condition (($preflight -join "`n") -like '*事前検査に合格しました*') -Message '事前検査が合格しませんでした'
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $fixtureRepository 'generated-projects\sample-app')) -Message '事前検査で生成物が変更されました'

    Assert-Throws -ExpectedText '確認文字列が一致しません' -Action {
        & $scriptPath -ProjectSlug 'sample-app' -CopiedProjectPath $copiedProject -Confirmation 'RESET:wrong' -Apply | Out-Null
    }

    Write-TestFile -Path (Join-Path $copiedProject 'src\app.txt') -Content "変更されたコピー`n"
    Assert-Throws -ExpectedText 'コピー先の完全性確認に失敗しました' -Action {
        & $scriptPath -ProjectSlug 'sample-app' -CopiedProjectPath $copiedProject | Out-Null
    }
    Copy-Item -LiteralPath (Join-Path $fixtureRepository 'generated-projects\sample-app\src\app.txt') -Destination (Join-Path $copiedProject 'src\app.txt') -Force

    Write-TestFile -Path (Join-Path $fixtureRepository 'AGENTS.md') -Content "# 未コミット変更`n"
    Assert-Throws -ExpectedText '未コミット変更があります' -Action {
        & $scriptPath -ProjectSlug 'sample-app' -CopiedProjectPath $copiedProject | Out-Null
    }
    Invoke-TestGit -Repository $fixtureRepository -Arguments @('restore', '--', 'AGENTS.md') | Out-Null

    $applyOutput = & $scriptPath -ProjectSlug 'sample-app' -CopiedProjectPath $copiedProject -Confirmation 'RESET:sample-app' -Apply
    Assert-True -Condition (($applyOutput -join "`n") -like '*案件状態を初期化しました*') -Message '初期化完了が報告されませんでした'
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $fixtureRepository 'generated-projects\sample-app'))) -Message '生成元が退避されていません'
    Assert-True -Condition ((Get-Content -Raw -LiteralPath (Join-Path $fixtureRepository 'PROJECT_BRIEF.md')) -like '*STARTER_STATE: READY*') -Message 'PROJECT_BRIEFが初期状態ではありません'
    Assert-True -Condition ((Get-Content -Raw -LiteralPath (Join-Path $fixtureRepository 'decisions\DECISION_LOG.md')) -like '*維持する判断*') -Message 'スターター共通判断が失われました'
    Assert-True -Condition ((Get-Content -Raw -LiteralPath (Join-Path $fixtureRepository 'decisions\DECISION_LOG.md')) -notlike '*消去する判断*') -Message '案件固有判断が残っています'
    Assert-True -Condition ((Get-Content -Raw -LiteralPath (Join-Path $fixtureRepository 'logs\DEVELOPMENT_LOG.md')) -like '*維持する過去ログ*') -Message '過去ログが失われました'
    Assert-True -Condition ((Get-Content -Raw -LiteralPath (Join-Path $fixtureRepository 'logs\DEVELOPMENT_LOG.md')) -like '*案件状態を初期化*') -Message '初期化ログが追加されませんでした'
    $archives = Get-ChildItem -LiteralPath (Join-Path $fixtureRepository 'archives\generated-projects') -Directory
    Assert-True -Condition ($archives.Count -eq 1) -Message '復旧用退避が作成されていません'
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $archives[0].FullName 'generated-project\src\app.txt')) -Message '退避した生成物が不足しています'

    Write-Output '案件初期化テスト合格: 既定ブランチ停止、同期ずれ停止、事前検査、確認文字列、コピー不一致、未コミット変更、正常初期化、ログ維持、復旧用退避'
}
finally {
    $resolvedTestRoot = [System.IO.Path]::GetFullPath($testRoot)
    $safePrefix = $temporaryParent + [System.IO.Path]::DirectorySeparatorChar + 'codex-reset-project-state-test-'
    if ((Test-Path -LiteralPath $resolvedTestRoot) -and $resolvedTestRoot.StartsWith($safePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
