const TICKET_TYPES = ['A', 'B1', 'B2', 'C1', 'C2', 'D', 'E'];
const HISTORY_HEADERS = ['レコードID', '作業セッションID', 'マニフェスト番号', '票種', '登録日時', '選択した担当者名', 'Googleアカウント', '読み取り方法', 'OCR確信度', '処理時間(ms)', '端末種別', 'ブラウザ種別', '状態', '取消日時', '取消実行者'];
const OPERATOR_HEADERS = ['担当者ID', '表示名', '有効・無効', '表示順'];
const EVENT_HEADERS = ['イベントID', '作業セッションID', '発生日時', '担当者名', 'Googleアカウント', '種別', 'OCR確信度', '処理時間(ms)', '端末・ブラウザ種別', 'エラーコード'];

function doGet() {
  return HtmlService.createTemplateFromFile('client/index').evaluate().setTitle('マニフェスト登録スキャナー');
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

function getAppConfig() {
  const props = PropertiesService.getScriptProperties();
  return { confidenceThreshold: Number(props.getProperty('OCR_CONFIDENCE_THRESHOLD') || 80), spreadsheetConfigured: Boolean(props.getProperty('SPREADSHEET_ID')), ticketTypes: TICKET_TYPES };
}

function getSessionInfo() {
  const email = getActiveUserEmail_();
  return { email: email, authenticated: Boolean(email), domain: email && email.indexOf('@') >= 0 ? email.split('@').pop() : '' };
}

function listOperators() {
  const sheet = getSheet_('担当者一覧');
  if (!sheet) return [];
  return readRows_(sheet).filter(function(row) { return String(row['有効・無効']).toLowerCase() === 'true' || row['有効・無効'] === '有効'; }).sort(function(a, b) { return Number(a['表示順'] || 0) - Number(b['表示順'] || 0); }).map(function(row) { return { id: String(row['担当者ID'] || ''), name: String(row['表示名'] || '') }; });
}

function registerReading(input) {
  const data = validateReading_(input || {});
  const email = getActiveUserEmail_();
  if (!email) throw appError_('AUTH_REQUIRED', 'Googleアカウントを確認できません。');
  const lock = LockService.getScriptLock();
  lock.waitLock(10000);
  try {
    const sheet = getSheet_('読取履歴');
    if (!sheet) throw appError_('SHEET_NOT_READY', '記録先シートが設定されていません。');
    const operatorSheet = getSheet_('担当者一覧');
    if (!operatorSheet || !readRows_(operatorSheet).some(function(row) { return String(row['表示名'] || '') === data.operatorName && (String(row['有効・無効']).toLowerCase() === 'true' || row['有効・無効'] === '有効'); })) {
      throw appError_('INVALID_OPERATOR', '有効な担当者を選択してください。');
    }
    const duplicate = readRows_(sheet).some(function(row) { return String(row['マニフェスト番号']) === data.manifestNumber && String(row['票種']) === data.ticketType && String(row['状態'] || '有効') !== '取消済み'; });
    if (duplicate) return { ok: false, duplicate: true, errorCode: 'DUPLICATE' };
    const recordId = Utilities.getUuid();
    sheet.appendRow([recordId, data.sessionId, data.manifestNumber, data.ticketType, new Date(), data.operatorName, email, data.readingMethod, data.ocrConfidence, data.processingTimeMs, data.deviceType, data.browserType, '有効', '', '']);
    return { ok: true, recordId: recordId, processingTimeMs: Date.now() - data.requestStartedAt };
  } finally {
    lock.releaseLock();
  }
}

/** 管理者がScript PropertiesのSPREADSHEET_ID設定後に一度だけ実行する。 */
function setupSpreadsheet() {
  const spreadsheet = getSpreadsheet_();
  ensureSheet_(spreadsheet, '読取履歴', HISTORY_HEADERS);
  ensureSheet_(spreadsheet, '担当者一覧', OPERATOR_HEADERS);
  ensureSheet_(spreadsheet, '作業イベント', EVENT_HEADERS);
  return { ok: true };
}

function validateReading_(input) {
  const manifestNumber = String(input.manifestNumber || '').replace(/\s/g, '');
  const ticketType = String(input.ticketType || '').toUpperCase();
  const readingMethod = String(input.readingMethod || '');
  const allowedMethods = ['自動認識', '手修正', '手入力'];
  if (!/^\d{11}$/.test(manifestNumber)) throw appError_('INVALID_NUMBER', '番号は11桁の数字で入力してください。');
  if (TICKET_TYPES.indexOf(ticketType) < 0) throw appError_('INVALID_TICKET_TYPE', '票種を選択してください。');
  if (allowedMethods.indexOf(readingMethod) < 0) throw appError_('INVALID_READING_METHOD', '読み取り方法が不正です。');
  const confidence = Number(input.ocrConfidence || 0);
  const processingTimeMs = Number(input.processingTimeMs || 0);
  if (!Number.isFinite(confidence) || confidence < 0 || confidence > 100) throw appError_('INVALID_CONFIDENCE', '確信度が不正です。');
  if (!Number.isFinite(processingTimeMs) || processingTimeMs < 0 || processingTimeMs > 600000) throw appError_('INVALID_PROCESSING_TIME', '処理時間が不正です。');
  return { manifestNumber: manifestNumber, ticketType: ticketType, readingMethod: readingMethod, ocrConfidence: confidence, processingTimeMs: processingTimeMs, sessionId: String(input.sessionId || '').slice(0, 100), operatorName: String(input.operatorName || '').slice(0, 100), deviceType: String(input.deviceType || '').slice(0, 100), browserType: String(input.browserType || '').slice(0, 100), requestStartedAt: Date.now() };
}

function getActiveUserEmail_() {
  try { return Session.getActiveUser().getEmail() || ''; } catch (error) { return ''; }
}

function getSpreadsheet_() {
  const id = PropertiesService.getScriptProperties().getProperty('SPREADSHEET_ID');
  if (!id) throw appError_('SHEET_NOT_CONFIGURED', '管理者が記録先を設定してください。');
  try { return SpreadsheetApp.openById(id); } catch (error) { throw appError_('SHEET_UNAVAILABLE', '記録先シートを開けません。'); }
}

function getSheet_(name) {
  try { return getSpreadsheet_().getSheetByName(name); } catch (error) { return null; }
}

function readRows_(sheet) {
  const values = sheet.getDataRange().getValues();
  if (values.length < 2) return [];
  const headers = values[0].map(String);
  return values.slice(1).map(function(row) { return headers.reduce(function(result, header, index) { result[header] = row[index]; return result; }, {}); });
}

function ensureSheet_(spreadsheet, name, headers) {
  const sheet = spreadsheet.getSheetByName(name) || spreadsheet.insertSheet(name);
  if (sheet.getLastRow() === 0) sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
}

function appError_(code, message) {
  const error = new Error(message);
  error.name = code;
  return error;
}
