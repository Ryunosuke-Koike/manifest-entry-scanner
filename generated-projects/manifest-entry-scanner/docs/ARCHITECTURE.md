# 技術構成

## 結論

Google Apps ScriptのWebアプリ上でスマートフォン向け画面を提供し、ブラウザ内のTesseract.jsでOCRを行う。認識結果だけをApps Scriptへ渡し、Googleスプレッドシートへ登録する。

## 構成

```text
スマートフォンのSafari / Chrome
  ├─ カメラ映像・撮影
  ├─ 画像切り出し・補正
  ├─ Tesseract.jsによる端末内OCR
  └─ 番号・票種・確信度・処理時間だけを送信
                ↓
Google Apps Script Webアプリ
  ├─ Google Workspaceドメイン制限
  ├─ 入力検証
  ├─ LockServiceによる排他制御
  ├─ 重複確認・登録・取消
  └─ セッション・イベント取得
                ↓
Googleスプレッドシート
  ├─ 読取履歴
  ├─ 担当者一覧
  └─ 作業イベント
```

撮影画像と画像データは矢印の先へ送らない。

## 採用技術

### Google Apps Script

- 何をするものか: Google Workspace上で動くサーバー処理とWeb画面
- 役割: 社内公開、利用者確認、スプレッドシート操作、重複・取消・セッション処理
- 採用理由: 既存Workspace内で追加費用を抑え、Googleスプレッドシートと連携しやすい
- 代替案: 別のWebホスティングとGoogle Sheets API、Cloud Run、Firebase
- 費用: 既存契約内を想定。利用上限は変わる可能性がある
- 注意: HTML Serviceはiframe内で動くため、カメラ動作をGoal 1で実機確認する

Webアプリは同一ドメインだけに公開し、スプレッドシートを利用者へ直接共有しないため、実行者はデプロイ担当者を基本候補とする。利用者メール取得は実行条件で変わるため、実機検証で空文字にならないことを確認してから確定する。

### Tesseract.js

- 何をするものか: JavaScriptとWebAssemblyでブラウザ内OCRを行うライブラリ
- 役割: 固定範囲の11桁番号と票種を端末内で認識
- 採用理由: 撮影画像を外部OCRへ送らずWebアプリで動かせる
- 代替案: クラウドOCR、ネイティブアプリの端末内OCR
- 費用: 無料、Apache-2.0
- 注意: 初回にWorker、WebAssembly、OCRモデルの読み込みが必要。バージョンと配信元を固定し、読み込み失敗を表示する

OCRは英数字だけを対象にし、番号範囲では数字11桁、票種範囲では `A B C D E 1 2` に候補を限定する。確信度の閾値は70枚の結果から決める。

### Googleスプレッドシート

- 役割: 読取履歴、担当者、作業イベントを保存
- 採用理由: 管理担当者が既存の方法で確認・修正できる
- 代替案: データベース
- 費用: 既存契約内
- 注意: 行数増加時の性能と会社の保存期間ルールを確認する

### HTML・CSS・JavaScript

- 役割: スマートフォン画面、カメラ、画像補正、OCR、音・振動設定
- 採用理由: 小規模実験のためフレームワークを増やさず、Apps Scriptへ配置しやすい
- 代替案: Reactなどのフロントエンドフレームワーク
- 費用: 無料
- 注意: iPhone/SafariとAndroid/Chromeの差を実機確認する

## セキュリティ境界

- ブラウザ外へ送るのは文字列、確信度、処理時間、端末・ブラウザ種別だけ
- 画像、Canvas、Blob、Data URLをApps Script呼び出しへ渡さない
- スプレッドシートIDはScript Propertiesなどの安全な設定で管理する
- 実際のAPIキー、OAuthトークン、スプレッドシートIDをGitへ保存しない
- Apps ScriptのOAuthトークンをブラウザへ渡さない
- エラーログへ番号全体や画像を出力しない

## 同時登録

Apps ScriptのScript Lock取得後に、同じ「番号＋票種」で状態が有効な行を確認し、存在しない場合だけ追加する。重複確認と追加の間にロックを解放しない。

## 初期ファイルツリー

```text
src/
├─ appsscript.json
├─ client/
│  └─ README.md
└─ server/
   └─ README.md
config/
└─ SPREADSHEET_SCHEMA.md
samples/
└─ README.md
tests/
├─ unit/
│  └─ README.md
└─ manual/
   └─ DEVICE_MATRIX.md
```

実装開始後、Goal 1のIssueでクライアント・サーバーの実ファイルと自動テスト設定を追加する。

## 公式資料

- Google Apps Script Web Apps: https://developers.google.com/apps-script/guides/web
- HTML Serviceの制限: https://developers.google.com/apps-script/guides/html/restrictions
- Sessionと利用者メール: https://developers.google.com/apps-script/reference/base/session
- Lock Service: https://developers.google.com/apps-script/reference/lock
- Apps Scriptの利用上限: https://developers.google.com/apps-script/guides/services/quotas
- Tesseract.js: https://github.com/naptha/tesseract.js/
