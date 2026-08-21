---
name: reset-project-state
description: 完了した案件の生成物をコピー後、スターターの機能・運用ルール・学習ログを維持したまま案件固有状態だけを安全に初期化する。「初期状態に戻す」「案件初期化」などの独立した指示で使用し、説明や質問だけでは実行しない。
---

# Reset Project State

## 目的

完了した案件をGit履歴とコピー先へ残し、次の「開発スタート」を受け付けられる状態へ戻す。履歴を書き換える `git reset` や生成物の直接削除は行わない。

## 起動条件

次の語が、初期化を実行する独立した指示として入力された場合に使用する。

- `初期状態に戻す`
- `案件初期化`
- `次の開発準備`
- `/reset-project-state`

語を含む質問、仕様確認、説明依頼では起動しない。

## 維持するもの

- `.codex/skills/`、`agents/`、`scripts/`、`docs/`
- Git・Issue・ブランチ・PRの運用ルール
- `logs/DEVELOPMENT_LOG.md` と過去の改善記録
- `decisions/DECISION_LOG.md` のスターター共通判断
- Git履歴とリモート上の過去PR

## 初期化するもの

- `PROJECT_BRIEF.md`
- `plans/MASTER_PLAN.md`
- `tasks/TASKS.md`
- `decisions/DECISION_LOG.md` の「現在の案件に関する判断」
- 指定した `generated-projects/<project-slug>/`

生成物は削除せず、Git管理対象外の `archives/generated-projects/` へ移動する。

## 実行手順

1. `AGENTS.md`、`docs/GIT_WORKFLOW.md`、`logs/DEVELOPMENT_LOG.md` を読む。
2. 現在案件のPRが人のレビューを経てマージ済みであることを確認する。
3. 最新の既定ブランチから初期化用Issueと作業ブランチを作る。
4. 人が別の場所へコピーした実装用プロジェクトのパスを確認する。
5. 次のコマンドを `-Apply` なしで実行し、事前検査結果を人へ示す。

```powershell
& .\.codex\skills\reset-project-state\scripts\reset-project-state.ps1 `
  -ProjectSlug '<project-slug>' `
  -CopiedProjectPath '<コピー先のパス>'
```

6. 検査合格後、初期化対象と確認文字列 `RESET:<project-slug>` を人へ示し、明示的な実行確認を得る。
7. 確認後だけ次を実行する。

```powershell
& .\.codex\skills\reset-project-state\scripts\reset-project-state.ps1 `
  -ProjectSlug '<project-slug>' `
  -CopiedProjectPath '<コピー先のパス>' `
  -Confirmation 'RESET:<project-slug>' `
  -Apply
```

8. 差分と退避先を確認し、テスト、二種類のレビュー、統括レビューを行う。
9. 日本語でコミット・プッシュし、Issueに対応するドラフトPRを作る。マージは人が行う。

## 停止条件

次の場合は一切変更せず停止し、解消方法を人へ説明する。

- 未コミット変更がある
- 既定ブランチ上にいる
- upstreamがない、またはローカルとupstreamが一致しない
- 生成元またはコピー先が見つからない
- コピー先に生成元の全ファイルが同じ内容で揃っていない
- コピー先がスターター内部にある
- 確認文字列が一致しない
- 現在案件のPRが未マージ

スクリプトが確認できないGitHub上のPR状態は、実行前に統括役が確認する。
