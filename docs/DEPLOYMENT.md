# Goal 1の開発・デプロイ手順

## 初回設定

1. Apps Scriptプロジェクトを管理者が作成し、Script IDを `.clasp.json.example` からコピーしたローカルの `.clasp.json` に設定する。
2. `.clasp.json` は `.gitignore` 対象のため、Gitへ追加しない。
3. Apps Scriptの「プロジェクトの設定」でScript Propertiesへ次を設定する。
   - `SPREADSHEET_ID`: 管理者だけが知る実験用スプレッドシートID
   - `OCR_CONFIDENCE_THRESHOLD`: 初期値 `80`。70枚の測定後に人が見直す
4. Apps Scriptエディタで `setupSpreadsheet()` を管理者が一度だけ実行し、「読取履歴」「担当者一覧」「作業イベント」を作成する。
5. 「担当者一覧」に担当者ID、表示名、有効・無効、表示順を管理者が登録する。

## ローカルからの反映

```text
clasp login
clasp push
clasp deploy --description "Goal 1 技術成立性の確認"
```

Webアプリの公開設定は、同じGoogle Workspaceドメインだけがアクセスできる状態を管理者が確認する。実行ユーザー、OAuth同意画面、スプレッドシート共有権限を変更した場合は、実機確認をやり直す。

## 確認時の注意

- 実画像、スプレッドシートID、OAuthトークンをGitへ保存しない。
- ブラウザからApps Scriptへ送るのは番号、票種、確信度、処理時間などの認識結果だけにする。
- カメラのCanvas画像やData URLをログ、サーバー関数、スプレッドシートへ渡さない。
- `clasp push` 前に `git status` で `.clasp.json` が追跡対象でないことを確認する。
