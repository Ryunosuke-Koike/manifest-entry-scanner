# クライアント実装先

Goal 1で、次の画面とブラウザ処理を小さく実装します。

- スマートフォン用撮影画面
- 番号・票種の撮影枠
- Canvasによる画像切り出しと補正
- Tesseract.js Workerによる端末内OCR
- 11桁番号と7票種への候補制限
- OCR確信度と処理時間の測定
- Apps Scriptサーバー呼び出し

撮影画像、Blob、Canvas、Data URLをサーバーへ送信してはいけません。Tesseract.jsのバージョンと読み込み先は実装時に固定し、起動時に1回だけWorkerを準備します。

`index.html`、`styles.html`、`app.html`、`ocr-utils.html` がGoal 1の試作画面です。`app.html`はCanvasで取得した画像をTesseract.jsへ渡しますが、Apps Scriptのサーバー関数へ渡すペイロードには画像を含めません。
