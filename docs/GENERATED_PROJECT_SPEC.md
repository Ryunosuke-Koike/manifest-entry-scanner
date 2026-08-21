# 実装用プロジェクト生成仕様

## 出力先

要件確定後、スターター直下の `generated-projects/<project-slug>/` に1アプリ1ディレクトリで生成する。`project-slug` は半角英小文字、数字、ハイフンを使用する。同名ディレクトリがある場合は上書きせず、人へ確認する。

## 自己完結の条件

生成ディレクトリは、別の場所へ単独でコピーして利用できなければならない。

- 親スターターのファイルや絶対パスを参照しない
- 要件、計画、タスク、判断、レビュー、ログ、Git運用、役割、起動スキルを内部に持つ
- 採用技術に必要なソース、テスト、設定、環境変数の見本を内部に持つ
- 秘密情報や実際のAPIキーを含めない
- コピー直後の起動方法を `README.md` に記載する
- `PROJECT_ROOT.md` に、コピー後は同ファイルと `AGENTS.md` がある現在のディレクトリを新しいプロジェクトルートとして扱う旨を記載する。端末固有の絶対パスは保存しない

## 標準ファイルツリー

```text
<project-slug>/
├─ .codex/
│  └─ skills/
│     └─ start-implementation/
│        └─ SKILL.md
├─ agents/
├─ decisions/
│  └─ DECISION_LOG.md
├─ docs/
│  ├─ DEVELOPMENT_WORKFLOW.md
│  ├─ GIT_WORKFLOW.md
│  ├─ REQUIREMENTS.md
│  ├─ ARCHITECTURE.md
│  └─ TESTING.md
├─ logs/
│  └─ DEVELOPMENT_LOG.md
├─ plans/
│  └─ MASTER_PLAN.md
├─ reviews/
│  ├─ REVIEW_CONSERVATIVE.md
│  ├─ REVIEW_PRAGMATIC.md
│  └─ REVIEW_LEAD.md
├─ tasks/
│  └─ TASKS.md
├─ <採用技術に応じたソースディレクトリ>
├─ <採用技術に応じたテストディレクトリ>
├─ .gitignore
├─ AGENTS.md
├─ PROJECT_BRIEF.md
├─ PROJECT_ROOT.md
└─ README.md
```

## 生成時に具体化する内容

- 質問結果を `PROJECT_BRIEF.md` と `docs/REQUIREMENTS.md` に記入する
- Goalと完了条件を `plans/MASTER_PLAN.md` に記入する
- 実装順を `tasks/TASKS.md` に記入する
- 技術選定と理由を `decisions/DECISION_LOG.md` と `docs/ARCHITECTURE.md` に記入する
- 選択した技術に適したソース・テスト・設定ファイルのツリーを作る
- 実際に使用できるコマンドだけを `README.md` と `docs/TESTING.md` に記入する
- 実装前なので、動作未確認の機能を完成済みと記載しない

## 引き渡し前の検証

1. 必須ファイルがすべて存在する
2. 内部リンクと参照先が生成ディレクトリ内に存在する
3. 親スターターへの相対参照や絶対パスがない
4. 実装起動スキルにYAMLメタ情報がある
5. `AGENTS.md` に実装起動語、ディレクトリ固定、Git・レビュー運用がある
6. 秘密情報が含まれていない
7. コピー後の最初の操作がREADMEに明記されている
