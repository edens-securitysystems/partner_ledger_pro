import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import 'export_file_helper_export.dart';

import '../models/dto/report_dto.dart';
import '../models/entities/ledger_entry.dart';
import '../models/entities/partner.dart';
import '../models/entities/transaction.dart';

class ExportResult {
  final String filePath;
  final String fileName;
  final int fileSize;

  const ExportResult({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
  });
}

class ExportService {
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF1A237E);
  static const PdfColor _accentColor = PdfColor.fromInt(0xFF3949AB);
  static const PdfColor _lightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor _textColor = PdfColor.fromInt(0xFF212121);

  Future<ExportResult> generatePartnerLedgerPdf({
    required Partner partner,
    required List<LedgerEntry> entries,
    required DateTime startDate,
    required DateTime endDate,
    required String currency,
  }) async {
    final pdf = pw.Document();
    final format = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Partner Ledger Report'),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow('Partner', partner.name),
              _buildInfoRow('Period',
                  '${DateFormat.yMMMd().format(startDate)} - ${DateFormat.yMMMd().format(endDate)}'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow('Capital', format.format(partner.capital)),
              _buildInfoRow('Ownership', '${partner.ownershipPercentage}%'),
            ],
          ),
          pw.SizedBox(height: 20),
          _buildTableHeader(['Date', 'Description', 'Type', 'Amount', 'Balance']),
          ...entries.map((e) => _buildTableRow(
                [
                  DateFormat.yMMMd().format(e.date),
                  e.description ?? '-',
                  e.typeDisplay,
                  format.format(e.amount),
                  format.format(e.balance),
                ],
                entries.indexOf(e).isEven,
              )),
          pw.SizedBox(height: 20),
          _buildSummaryRow(
            'Closing Balance',
            format.format(entries.isNotEmpty ? entries.last.balance : 0.0),
          ),
        ],
      ),
    );

    return _savePdf(pdf, 'partner_ledger_${partner.name.replaceAll(' ', '_')}');
  }

  Future<ExportResult> generateTransactionReportPdf({
    required List<Transaction> transactions,
    required DateTime startDate,
    required DateTime endDate,
    required String currency,
  }) async {
    final pdf = pw.Document();
    final format = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Transaction Report'),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow('Period',
                  '${DateFormat.yMMMd().format(startDate)} - ${DateFormat.yMMMd().format(endDate)}'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow('Total Income', format.format(totalIncome)),
              _buildInfoRow('Total Expenses', format.format(totalExpense)),
              _buildInfoRow('Net', format.format(totalIncome - totalExpense)),
            ],
          ),
          pw.SizedBox(height: 20),
          _buildTableHeader(['Date', 'Partner', 'Type', 'Category', 'Amount']),
          ...transactions.map((t) => _buildTableRow(
                [
                  DateFormat.yMMMd().format(t.date),
                  t.partnerId,
                  t.typeDisplay,
                  t.category ?? '-',
                  format.format(t.signedAmount),
                ],
                transactions.indexOf(t).isEven,
              )),
          pw.SizedBox(height: 20),
          _buildSummaryRow('Total Income', format.format(totalIncome)),
          _buildSummaryRow('Total Expense', format.format(totalExpense)),
          _buildSummaryRow('Net Profit', format.format(totalIncome - totalExpense),
              isBold: true),
        ],
      ),
    );

    return _savePdf(pdf, 'transaction_report');
  }

  Future<ExportResult> generateProfitReportPdf({
    required double totalIncome,
    required double totalExpense,
    required List<Partner> partners,
    required Map<String, double> partnerProfits,
    required DateTime startDate,
    required DateTime endDate,
    required String currency,
  }) async {
    final pdf = pw.Document();
    final format = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    final netProfit = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Profit Distribution Report'),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoRow('Period',
                  '${DateFormat.yMMMd().format(startDate)} - ${DateFormat.yMMMd().format(endDate)}'),
            ],
          ),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Profit Summary'),
          pw.SizedBox(height: 10),
          _buildSummaryRow('Total Income', format.format(totalIncome)),
          _buildSummaryRow('Total Expenses', format.format(totalExpense)),
          _buildSummaryRow('Net Profit', format.format(netProfit), isBold: true),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Partner Distribution'),
          pw.SizedBox(height: 10),
          _buildTableHeader(['Partner', 'Ownership %', 'Share Amount']),
          ...partners.map((p) => _buildTableRow(
                [
                  p.name,
                  '${p.ownershipPercentage.toStringAsFixed(1)}%',
                  format.format(partnerProfits[p.id] ?? 0.0),
                ],
                partners.indexOf(p).isEven,
              )),
          pw.SizedBox(height: 20),
          _buildSummaryRow('Total Distributed', format.format(netProfit)),
        ],
      ),
    );

    return _savePdf(pdf, 'profit_report');
  }

  Future<ExportResult> generateBalanceSheetPdf({
    required double totalAssets,
    required double totalLiabilities,
    required double totalEquity,
    required List<Map<String, dynamic>> assetItems,
    required List<Map<String, dynamic>> liabilityItems,
    required List<Map<String, dynamic>> equityItems,
    required String currency,
  }) async {
    final pdf = pw.Document();
    final format = NumberFormat.currency(symbol: currency, decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader('Balance Sheet'),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Assets'),
          pw.SizedBox(height: 10),
          _buildTableHeader(['Item', 'Amount']),
          ...assetItems.map((item) => _buildTableRow(
                [
                  item['name'] as String? ?? '',
                  format.format((item['amount'] as num?)?.toDouble() ?? 0.0),
                ],
                assetItems.indexOf(item).isEven,
              )),
          pw.SizedBox(height: 5),
          _buildSummaryRow('Total Assets', format.format(totalAssets), isBold: true),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Liabilities'),
          pw.SizedBox(height: 10),
          _buildTableHeader(['Item', 'Amount']),
          ...liabilityItems.map((item) => _buildTableRow(
                [
                  item['name'] as String? ?? '',
                  format.format((item['amount'] as num?)?.toDouble() ?? 0.0),
                ],
                liabilityItems.indexOf(item).isEven,
              )),
          pw.SizedBox(height: 5),
          _buildSummaryRow('Total Liabilities', format.format(totalLiabilities),
              isBold: true),
          pw.SizedBox(height: 20),
          _buildSectionTitle("Owner's Equity"),
          pw.SizedBox(height: 10),
          _buildTableHeader(['Item', 'Amount']),
          ...equityItems.map((item) => _buildTableRow(
                [
                  item['name'] as String? ?? '',
                  format.format((item['amount'] as num?)?.toDouble() ?? 0.0),
                ],
                equityItems.indexOf(item).isEven,
              )),
          pw.SizedBox(height: 5),
          _buildSummaryRow('Total Equity', format.format(totalEquity), isBold: true),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 10),
          _buildSummaryRow('Total Liabilities + Equity',
              format.format(totalLiabilities + totalEquity),
              isBold: true),
        ],
      ),
    );

    return _savePdf(pdf, 'balance_sheet');
  }

  // ── Excel Export ─────────────────────────────────────────────────────────

  Future<ExportResult> exportToExcel({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String sheetName,
  }) async {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = sheetName;

    final headerStyle = sheet.getRangeByIndex(1, 1, 1, headers.length);
    headerStyle.cellStyle.backColor = '#1A237E';
    headerStyle.cellStyle.fontColor = '#FFFFFF';
    headerStyle.cellStyle.bold = true;
    headerStyle.cellStyle.hAlign = HAlignType.center;

    for (var i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(1, i + 1).setText(headers[i]);
    }

    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        final cell = sheet.getRangeByIndex(r + 2, c + 1);
        final value = rows[r][c];
        if (value is double || value is int) {
          cell.setNumber(value.toDouble());
          cell.numberFormat = '#,##0.00';
        } else {
          cell.setText(value?.toString() ?? '');
        }
      }
    }

    final range = sheet.getRangeByIndex(1, 1, rows.length + 1, headers.length);
    range.autoFitColumns();

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    return _saveBytes(Uint8List.fromList(bytes), '$title.xlsx');
  }

  // ── Shared Export Methods ────────────────────────────────────────────────

  Future<ExportResult> exportReport(ReportResponse report, ReportFormat format,
      String currency) async {
    switch (format) {
      case ReportFormat.pdf:
        return generateTransactionReportPdf(
          transactions: [],
          startDate: report.request.startDate,
          endDate: report.request.endDate,
          currency: currency,
        );
      case ReportFormat.excel:
        return exportToExcel(
          title: 'report_${report.request.startDate.toIso8601String()}',
          headers: ['Month', 'Income', 'Expense', 'Profit', 'Transactions'],
          rows: report.monthlyReports
              .map((m) => [
                    m.monthName,
                    m.income,
                    m.expense,
                    m.profit,
                    m.transactionCount,
                  ])
              .toList(),
          sheetName: 'Report',
        );
      case ReportFormat.csv:
        return exportToExcel(
          title: 'report_${report.request.startDate.toIso8601String()}',
          headers: ['Month', 'Income', 'Expense', 'Profit', 'Transactions'],
          rows: report.monthlyReports
              .map((m) => [
                    m.monthName,
                    m.income,
                    m.expense,
                    m.profit,
                    m.transactionCount,
                  ])
              .toList(),
          sheetName: 'Report',
        );
    }
  }

  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }

  Future<void> openFile(String filePath) async {
    // Platform-specific file opening handled by the UI layer
  }

  // ── Private Helpers ──────────────────────────────────────────────────────

  pw.Widget _buildHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: pw.BoxDecoration(
            color: _primaryColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Partner Ledger Pro',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Generated: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}',
          style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: _accentColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
            color: _textColor,
          ),
        ),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildTableHeader(List<String> headers) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(4),
          topRight: pw.Radius.circular(4),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: pw.Row(
        children: headers
            .map((h) => pw.Expanded(
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  pw.Widget _buildTableRow(List<String> cells, bool isEven) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: isEven ? _lightGray : PdfColors.white,
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Row(
        children: cells
            .map((c) => pw.Expanded(
                  child: pw.Text(
                    c,
                    style: const pw.TextStyle(fontSize: 9, color: _textColor),
                  ),
                ))
            .toList(),
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Future<ExportResult> _savePdf(pw.Document pdf, String fileName) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fullName = '${fileName}_$timestamp.pdf';
    final bytes = await pdf.save();

    if (kIsWeb) {
      return ExportResult(
        filePath: fullName,
        fileName: fullName,
        fileSize: bytes.length,
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$fullName';
    await ExportFileHelper.writeBytes(filePath, bytes);
    final size = await ExportFileHelper.getFileSize(filePath);

    return ExportResult(
      filePath: filePath,
      fileName: fullName,
      fileSize: size,
    );
  }

  Future<ExportResult> _saveBytes(List<int> bytes, String fileName) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fullName = '${fileName.replaceAll('.xlsx', '')}_$timestamp.xlsx';

    if (kIsWeb) {
      return ExportResult(
        filePath: fullName,
        fileName: fullName,
        fileSize: bytes.length,
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$fullName';
    await ExportFileHelper.writeBytes(filePath, bytes);
    final size = await ExportFileHelper.getFileSize(filePath);

    return ExportResult(
      filePath: filePath,
      fileName: fullName,
      fileSize: size,
    );
  }
}
