---
name: app-dev-orchestrator
description: 要件が曖昧なアプリ開発を、詳細要件確認、段階的計画、コピー可能な実装用プロジェクト生成まで統括する。実装は生成先の専用スキルへ引き渡す。
---

# App Development Orchestrator

## 目的

Codexを統括役として動かし、非エンジニアと対話しながら要件を確定し、別の場所へコピーして実装できる自己完結型プロジェクトを生成する。

## 起動条件

- 新しいアプリ開発を始める
- 要件が曖昧な状態から開発計画を作る
- 実装前のプロジェクト一式を生成する

## 実行手順

### Step 1: 現状確認

以下を読む。

- `AGENTS.md`
- `PROJECT_BRIEF.md`
- `plans/MASTER_PLAN.md`
- `tasks/TASKS.md`
- `decisions/DECISION_LOG.md`
- `docs/GIT_WORKFLOW.md`
- `docs/GENERATED_PROJECT_SPEC.md`
- `logs/DEVELOPMENT_LOG.md`

開発ログから過去の失敗、手戻り、改善策を確認し、今回の計画へ反映する。

### Step 2: 詳細Grill-me

`.codex/skills/start-app-development/references/requirements-interview.md` を読み、質問を1問ずつ行う。各質問に推奨回答と理由を付け、回答による分岐を一つずつ解消する。

要件要約を利用者へ提示し、明示的な確認を得るまで次へ進まない。

### Step 3: 段階的ゴールの提案

最大3段階で提案する。

- Goal 1: 動く最小版
- Goal 2: 実際に試せる版
- Goal 3: 安定運用版

各Goalに以下を付ける。

- 何ができるようになるか
- 今は含めないもの
- 完了条件
- おおよその難易度

### Step 4: 技術選定

技術やサービスごとに以下を説明する。

- 一言で何か
- この開発での役割
- 採用理由
- 費用
- 代替案
- 初心者が注意する点

### Step 5: 計画とタスク作成

- `plans/MASTER_PLAN.md` を更新
- `tasks/TASKS.md` を更新
- 判断事項を `decisions/DECISION_LOG.md` に記録

### Step 6: 実装用プロジェクト生成

`docs/GENERATED_PROJECT_SPEC.md` に従い、`generated-projects/<project-slug>/` に自己完結型プロジェクトを生成する。

- 確定要件、計画、タスク、技術判断を生成物へ書き込む
- Git、Issue、ブランチ、PR、人によるマージ、日本語記録のルールを含める
- `.codex/skills/start-implementation/SKILL.md` を含める
- 採用技術に応じたソース・テスト・設定のツリーを作る
- 親スターターへの依存を残さない
- アプリ機能はまだ実装しない

### Step 7: 生成物検証

必須ファイル、内部参照、自己完結性、秘密情報、起動スキルを検証する。問題があれば引き渡し前に修正する。

### Step 8: 引き渡し

利用者へ次を提示する。

- 生成したディレクトリ
- 主要ファイルツリー
- 別の場所へコピーする方法
- コピー後にそのディレクトリを開く方法
- `実装スタート` などの実装起動語
- 保留事項

### Step 9: 開発ログ更新

質問、判断、生成内容、検証結果、失敗、改善策をスターター側の `logs/DEVELOPMENT_LOG.md` に記録する。

## 出力上の注意

- 専門用語には括弧で説明を付ける
- 長い説明は「結論」「理由」「手順」に分ける
- 利用者の判断が必要な点を明示する
- 実装できていないことを、できたように書かない
