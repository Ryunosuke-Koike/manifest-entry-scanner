# 慎重派レビュー

## 対象

Issue #3のGoal 1初期実装（G1-005〜G1-008）。Apps Scriptサーバー、カメラ画面、端末内OCR、設定・デプロイ手順、自動テストを確認した。

## 結論

コードを実機へ出す前に、Apps ScriptのHTML Service、カメラ権限、Googleアカウント取得、スプレッドシート設定を実環境で確認する必要がある。画像をサーバーへ渡さない境界とサーバー側入力検証は実装されているため、次の段階へ進めるが、実機確認完了まではGoal 1完了とはしない。

## 指摘と判断

### 対応済み

1. クライアントからの担当者名を信頼すると、任意の名前を記録できる
   - 対応: `registerReading`で「担当者一覧」の有効な表示名と照合する。
2. OCR候補がないと票種Aを誤って登録する可能性がある
   - 対応: 候補なしは空欄にして、手動選択を必須にした。
3. OCR文字列「MANIFEST」のAを票種と誤認する可能性がある
   - 対応: 票種候補をトークン境界付きの7種類に限定し、回帰テストを追加した。

### 実機確認待ち

1. `createTemplateFromFile('client/index')`と`include`のパスがApps Scriptへ反映後も解決するか未確認。
2. iPhone/Safari、Android/ChromeのHTML Service内カメラ権限と`facingMode`動作は未確認。
3. Tesseract.jsのCDN読み込み、初回Worker準備時間、見本画像での番号・票種精度は未測定。
4. `Session.getActiveUser().getEmail()`が同一Workspaceの公開設定で空にならないか未確認。
5. 実画像を含むネットワーク記録で、Apps Scriptへ画像・Blob・Data URLが渡らないことを確認する必要がある。

## テスト結果

- `node --test tests/unit/ocr-utils.test.js`: 成功（1件）
- Apps Scriptデプロイ、実験用シート、実機テスト: 未実施（外部設定・実機待ち）

## 判定

実装レビューは条件付き採用。実機と見本画像を受領し、上記5点を確認してからG1-007、G1-008を完了判定する。
