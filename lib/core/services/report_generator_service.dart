import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../model/transaction_model.dart';

class ReportGeneratorService {
  Future<File> generatePdfReport({
    required List<TransactionModel> transactions,
    required String reportType,
    required double totalIncome,
    required double totalExpense,
    required double netWorth,
    required Map<String, double> categoryTotals,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');

    // পারমিশন ঝামেলা এড়াতে Temporary directory ব্যবহার করা হচ্ছে
    final directory = await getTemporaryDirectory();
    final fileName = 'Hisab_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Financial Report - Hisab App')),
          pw.Paragraph(text: 'Type: $reportType'),
          pw.Paragraph(text: 'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: 'Total Income: BDT ${currencyFormat.format(totalIncome)}'),
          pw.Bullet(text: 'Total Expense: BDT ${currencyFormat.format(totalExpense)}'),
          pw.Bullet(text: 'Net Balance: BDT ${currencyFormat.format(netWorth)}'),
          pw.SizedBox(height: 20),
          pw.Text('Transactions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Category', 'Type', 'Amount'],
            data: transactions.map((t) => [
              DateFormat('yyyy-MM-dd').format(t.transactionDate),
              t.category ?? '',
              t.type == 'income' ? 'Income' : 'Expense',
              currencyFormat.format(t.amount)
            ]).toList(),
          ),
        ],
      ),
    );

    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
