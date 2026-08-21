# Codex App Development Starter

非エンジニアやアプリ開発初心者でも、Codexとの詳細な要件確認を経て、別の場所へコピーできる実装用プロジェクトを作るためのスターターです。

## 基本方針

- 完璧な設計より、まず動く最小版を作る
- 不明点は、推奨回答付きのGrill-me形式で1問ずつ詳しく確認する
- 技術やサービスを採用するときは、用途・理由・費用・注意点を説明する
- 計画、実装、レビュー、修正を分離する
- 性格の異なる複数のレビュー担当が確認する
- 最終判断は統括エージェントが行う
- コピー先で実装を開始したらGitで管理し、人が用意したリモートへ接続する
- 影響の大きい作業はIssue・ブランチ・PRを使い、マージは人が行う
- 開発ログから失敗と手戻りを学び、開発手順を継続的に改善する

## 開始方法

1. Codexでこのスターターディレクトリを開く
2. 次の起動語を入力する

```text
開発スタート
```

3. 推奨回答付きの質問へ1問ずつ答える
4. 要件要約、技術、Goalを確認する
5. `generated-projects/<project-slug>/` に生成されたディレクトリを任意の場所へコピーする
6. Codexでコピー先を開き、次を入力する

```text
実装スタート
```

7. 人が作成したリモートURLを提示し、接続確認後に実装を始める

## 主なファイル

- `AGENTS.md`: リポジトリ全体の作業ルール
- `PROJECT_BRIEF.md`: アプリの目的や希望を書く場所
- `agents/`: 各サブエージェントの役割
- `plans/MASTER_PLAN.md`: 全体計画と段階的ゴール
- `tasks/TASKS.md`: タスクと進行状況
- `docs/DEVELOPMENT_WORKFLOW.md`: 計画から実装までの手順
- `docs/GENERATED_PROJECT_SPEC.md`: コピー可能な実装用プロジェクトの生成仕様
- `docs/GIT_WORKFLOW.md`: Git、Issue、ブランチ、PRの運用
- `logs/DEVELOPMENT_LOG.md`: 作業結果、失敗、改善策の記録
- `docs/TECHNOLOGY_EXPLANATION_TEMPLATE.md`: 技術説明の書式
- `reviews/`: レビュー結果
- `.codex/skills/app-dev-orchestrator/SKILL.md`: 開発統括スキル
- `.codex/skills/grill-me-lite/SKILL.md`: 初心者向け質問スキル
- `.codex/skills/start-app-development/assets/project-template/`: 生成する実装用プロジェクトの共通雛形
- `generated-projects/`: 要件確定後の実装用プロジェクト出力先

## 合言葉で起動する

長い初期プロンプトを入力する必要はありません。Codexで次の一言を入力してください。

```text
開発スタート
```

テーマを続けて指定することもできます。質問や説明の文章内に起動語があるだけでは開始しません。

```text
開発スタート 社内用の見積管理アプリ
```

より明示的なコマンド形式:

```text
/start-app-dev
```

詳しくは `docs/TRIGGER_COMMAND.md` を参照してください。
