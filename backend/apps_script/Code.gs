/**
 * Google Apps Script - Partner Ledger Pro API
 *
 * SETUP INSTRUCTIONS:
 * 1. Create a new Google Spreadsheet
 * 2. Create these sheet tabs: users, businesses, partners, transactions, ledger_entries, notifications
 * 3. Add column headers in row 1 for each sheet (see SHEET_COLUMNS below)
 * 4. Go to Extensions > Apps Script
 * 5. Paste this entire script
 * 6. Deploy > New deployment > Web app
 *    - Execute as: Me
 *    - Who has access: Anyone (or Anyone with Google account)
 * 7. Copy the deployment URL and paste it into lib/core/config/sheets_config.dart
 */

// ── Sheet column definitions ────────────────────────────────────────────────

const SHEET_COLUMNS = {
  'users': ['id', 'email', 'name', 'phone', 'photo', 'role', 'businessId', 'createdAt', 'updatedAt', 'isActive'],
  'businesses': ['id', 'name', 'description', 'logo', 'ownerEmail', 'address', 'phone', 'email', 'website', 'currency', 'taxId', 'createdAt', 'updatedAt', 'isActive'],
  'partners': ['id', 'businessId', 'name', 'email', 'phone', 'photo', 'capital', 'ownershipPercentage', 'joiningDate', 'status', 'description', 'createdAt', 'updatedAt', 'isActive'],
  'transactions': ['id', 'businessId', 'partnerId', 'type', 'amount', 'category', 'description', 'date', 'time', 'attachmentPath', 'createdBy', 'updatedBy', 'createdAt', 'updatedAt', 'isSynced', 'syncStatus'],
  'ledger_entries': ['id', 'partnerId', 'businessId', 'transactionId', 'type', 'amount', 'balance', 'description', 'date', 'createdAt'],
  'notifications': ['id', 'userId', 'title', 'message', 'type', 'isRead', 'data', 'createdAt'],
};

// ── Web App Entry Points ────────────────────────────────────────────────────

function doPost(e) {
  try {
    const body = JSON.parse(e.postData.contents);
    const action = body.action;
    const sheet = body.sheet;

    let result;

    switch (action) {
      case 'getAll':
        result = getAllRows(sheet);
        break;
      case 'getById':
        result = getById(sheet, body.id);
        break;
      case 'create':
        result = createRow(sheet, body.data);
        break;
      case 'update':
        result = updateRow(sheet, body.id, body.data);
        break;
      case 'delete':
        result = deleteRow(sheet, body.id);
        break;
      case 'search':
        result = searchRows(sheet, body.search);
        break;
      case 'getByField':
        result = getByField(sheet, body.field, body.value);
        break;
      case 'ping':
        result = { success: true, message: 'pong', timestamp: new Date().toISOString() };
        break;
      default:
        result = { success: false, message: 'Unknown action: ' + action };
    }

    return ContentService
      .createTextOutput(JSON.stringify(result))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (error) {
    return ContentService
      .createTextOutput(JSON.stringify({
        success: false,
        message: error.message || 'Internal error',
        error: error.toString()
      }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  try {
    const action = e.parameter.action;
    const sheet = e.parameter.sheet;

    if (action === 'ping') {
      return ContentService
        .createTextOutput(JSON.stringify({
          success: true,
          message: 'pong',
          timestamp: new Date().toISOString()
        }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    let result;

    switch (action) {
      case 'getAll':
        result = getAllRows(sheet);
        break;
      case 'getById':
        result = getById(sheet, e.parameter.id);
        break;
      case 'search':
        result = searchRows(sheet, e.parameter.search);
        break;
      case 'getByField':
        result = getByField(sheet, e.parameter.field, e.parameter.value);
        break;
      default:
        result = { success: false, message: 'Unknown action: ' + action };
    }

    return ContentService
      .createTextOutput(JSON.stringify(result))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (error) {
    return ContentService
      .createTextOutput(JSON.stringify({
        success: false,
        message: error.message || 'Internal error'
      }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

// ── CRUD Operations ─────────────────────────────────────────────────────────

function getSheet_(sheetName) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(sheetName);

  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
    const columns = SHEET_COLUMNS[sheetName];
    if (columns) {
      sheet.getRange(1, 1, 1, columns.length).setValues([columns]);
    }
  }

  return sheet;
}

function getHeaders_(sheet) {
  const lastCol = sheet.getLastColumn();
  if (lastCol === 0) return [];
  return sheet.getRange(1, 1, 1, lastCol).getValues()[0];
}

function rowToMap_(headers, rowData) {
  const obj = {};
  for (let i = 0; i < headers.length; i++) {
    const value = rowData[i];
    if (value === null || value === undefined || value === '') {
      obj[headers[i]] = null;
    } else if (typeof value === 'object' && value instanceof Date) {
      obj[headers[i]] = value.toISOString();
    } else {
      obj[headers[i]] = value;
    }
  }
  return obj;
}

function mapToRow_(headers, data) {
  return headers.map(h => {
    const val = data[h];
    if (val === undefined || val === null) return '';
    return val;
  });
}

function findRowIndex_(sheet, headers, fieldName, value) {
  const colIndex = headers.indexOf(fieldName);
  if (colIndex === -1) return -1;

  const lastRow = sheet.getLastRow();
  if (lastRow <= 1) return -1;

  const data = sheet.getRange(2, colIndex + 1, lastRow - 1, 1).getValues();

  for (let i = 0; i < data.length; i++) {
    if (String(data[i][0]) === String(value)) {
      return i + 2; // +2 because we start from row 2 and array is 0-indexed
    }
  }

  return -1;
}

// ── getAllRows ───────────────────────────────────────────────────────────────

function getAllRows(sheetName) {
  const sheet = getSheet_(sheetName);
  const lastRow = sheet.getLastRow();
  const lastCol = sheet.getLastColumn();

  if (lastRow <= 1 || lastCol === 0) {
    return { success: true, result: [], rowCount: 0 };
  }

  const headers = getHeaders_(sheet);
  const data = sheet.getRange(2, 1, lastRow - 1, lastCol).getValues();

  const rows = data.map(row => rowToMap_(headers, row));

  return {
    success: true,
    result: rows,
    rowCount: rows.length
  };
}

// ── getById ──────────────────────────────────────────────────────────────────

function getById(sheetName, id) {
  const sheet = getSheet_(sheetName);
  const headers = getHeaders_(sheet);
  const rowIndex = findRowIndex_(sheet, headers, 'id', id);

  if (rowIndex === -1) {
    return { success: false, message: 'Row not found with id: ' + id };
  }

  const lastCol = sheet.getLastColumn();
  const rowData = sheet.getRange(rowIndex, 1, 1, lastCol).getValues()[0];
  const row = rowToMap_(headers, rowData);

  return { success: true, result: row };
}

// ── createRow ────────────────────────────────────────────────────────────────

function createRow(sheetName, data) {
  const sheet = getSheet_(sheetName);
  const headers = getHeaders_(sheet);

  if (!data.id) {
    data.id = Utilities.getUuid();
  }

  if (!data.createdAt) {
    data.createdAt = new Date().toISOString();
  }
  if (!data.updatedAt) {
    data.updatedAt = new Date().toISOString();
  }

  const rowData = mapToRow_(headers, data);
  sheet.appendRow(rowData);

  return {
    success: true,
    result: { id: data.id },
    message: 'Row created successfully'
  };
}

// ── updateRow ────────────────────────────────────────────────────────────────

function updateRow(sheetName, id, data) {
  const sheet = getSheet_(sheetName);
  const headers = getHeaders_(sheet);
  const rowIndex = findRowIndex_(sheet, headers, 'id', id);

  if (rowIndex === -1) {
    return { success: false, message: 'Row not found with id: ' + id };
  }

  data.updatedAt = new Date().toISOString();

  for (const key in data) {
    if (key === 'id') continue;
    const colIndex = headers.indexOf(key);
    if (colIndex !== -1) {
      sheet.getRange(rowIndex, colIndex + 1).setValue(data[key] === null ? '' : data[key]);
    }
  }

  return {
    success: true,
    message: 'Row updated successfully'
  };
}

// ── deleteRow ────────────────────────────────────────────────────────────────

function deleteRow(sheetName, id) {
  const sheet = getSheet_(sheetName);
  const headers = getHeaders_(sheet);
  const rowIndex = findRowIndex_(sheet, headers, 'id', id);

  if (rowIndex === -1) {
    return { success: false, message: 'Row not found with id: ' + id };
  }

  sheet.deleteRow(rowIndex);

  return {
    success: true,
    message: 'Row deleted successfully'
  };
}

// ── searchRows ──────────────────────────────────────────────────────────────

function searchRows(sheetName, query) {
  const sheet = getSheet_(sheetName);
  const lastRow = sheet.getLastRow();
  const lastCol = sheet.getLastColumn();

  if (lastRow <= 1 || lastCol === 0 || !query) {
    return { success: true, result: [], rowCount: 0 };
  }

  const headers = getHeaders_(sheet);
  const data = sheet.getRange(2, 1, lastRow - 1, lastCol).getValues();
  const lowerQuery = String(query).toLowerCase();

  const matches = [];

  for (const row of data) {
    const rowMap = rowToMap_(headers, row);
    const rowStr = JSON.stringify(rowMap).toLowerCase();

    if (rowStr.includes(lowerQuery)) {
      matches.push(rowMap);
    }
  }

  return {
    success: true,
    result: matches,
    rowCount: matches.length
  };
}

// ── getByField ──────────────────────────────────────────────────────────────

function getByField(sheetName, fieldName, value) {
  const sheet = getSheet_(sheetName);
  const lastRow = sheet.getLastRow();
  const lastCol = sheet.getLastColumn();

  if (lastRow <= 1 || lastCol === 0) {
    return { success: true, result: [], rowCount: 0 };
  }

  const headers = getHeaders_(sheet);
  const colIndex = headers.indexOf(fieldName);

  if (colIndex === -1) {
    return { success: false, message: 'Field not found: ' + fieldName };
  }

  const data = sheet.getRange(2, 1, lastRow - 1, lastCol).getValues();
  const matches = [];

  for (const row of data) {
    if (String(row[colIndex]) === String(value)) {
      matches.push(rowToMap_(headers, row));
    }
  }

  return {
    success: true,
    result: matches,
    rowCount: matches.length
  };
}

// ── Initialize Sheets (run once) ────────────────────────────────────────────

function initializeSheets() {
  for (const sheetName in SHEET_COLUMNS) {
    getSheet_(sheetName);
  }
  Logger.log('All sheets initialized successfully!');
}
