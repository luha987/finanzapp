import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportPDF extends StatefulWidget {
  const ExportPDF({Key? key}) : super(key: key);

  @override
  _ExportPDFState createState() => _ExportPDFState();
}

class _ExportPDFState extends State<ExportPDF> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference _transactionsRef;
  String _selectedFilter = "Semua";
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _transactionsRef = _database
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser?.uid ?? '')
        .child('transactions');
  }

  Future<void> _generatePDF() async {
    try {
      final dataSnapshot = await _transactionsRef.once();
      final data = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null || data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak ada transaksi untuk diekspor.")),
        );
        return;
      }

      List<Map<String, dynamic>> transactions = data.entries.map((entry) {
        return Map<String, dynamic>.from(entry.value);
      }).toList();

      transactions.sort((a, b) => DateTime.parse(a['datetime'])
          .compareTo(DateTime.parse(b['datetime'])));
      transactions = _filterTransactions(transactions);

      final pemasukan =
          transactions.where((t) => t['category'] == 'Pemasukan').toList();
      final pengeluaran =
          transactions.where((t) => t['category'] == 'Pengeluaran').toList();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            if (pemasukan.isNotEmpty) ...[
              pw.Text('Laporan Pemasukan',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  '${DateFormat('dd/MM/yyyy').format(pemasukan.firstWhere((e) => e['datetime'] != null)['datetime'] != null ? DateTime.parse(pemasukan.firstWhere((e) => e['datetime'] != null)['datetime']) : DateTime.now())} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(pemasukan.lastWhere((e) => e['datetime'] != null)['datetime']))}',
                  style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(2.5),
                  3: pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nama')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Deskripsi')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Tanggal')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Jumlah')),
                    ],
                  ),
                  ...pemasukan.map((transaction) {
                    final dateTime = DateTime.parse(transaction['datetime']);
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(transaction['name'] ?? '')),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(transaction['description'] ?? '')),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd/MM/yyyy').format(dateTime))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(double.tryParse(transaction['amount'].toString()) ?? 0))),
                      ],
                    );
                  }),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.SizedBox(),
                      pw.SizedBox(),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          _formatCurrency(pemasukan.fold(0, (sum, t) => sum + (double.tryParse(t['amount'].toString()) ?? 0))),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              pw.SizedBox(height: 30),
            ],
            if (pengeluaran.isNotEmpty) ...[
              pw.Text('Laporan Pengeluaran',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  '${DateFormat('dd/MM/yyyy').format(pengeluaran.firstWhere((e) => e['datetime'] != null)['datetime'] != null ? DateTime.parse(pengeluaran.firstWhere((e) => e['datetime'] != null)['datetime']) : DateTime.now())} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(pengeluaran.lastWhere((e) => e['datetime'] != null)['datetime']))}',
                  style: pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(2.5),
                  3: pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nama')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Deskripsi')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Tanggal')),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Jumlah')),
                    ],
                  ),
                  ...pengeluaran.map((transaction) {
                    final dateTime = DateTime.parse(transaction['datetime']);
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(transaction['name'] ?? '')),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(transaction['description'] ?? '')),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd/MM/yyyy').format(dateTime))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(_formatCurrency(double.tryParse(transaction['amount'].toString()) ?? 0))),
                      ],
                    );
                  }),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.SizedBox(),
                      pw.SizedBox(),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          _formatCurrency(pengeluaran.fold(0, (sum, t) => sum + (double.tryParse(t['amount'].toString()) ?? 0))),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ],
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final file = File("${output.path}/Laporan_Keuangan.pdf");
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF berhasil disimpan di ${file.path}")),
      );
    } catch (e) {
      print("Terjadi kesalahan saat mengekspor PDF: $e");
    }
  }

  List<Map<String, dynamic>> _filterTransactions(
      List<Map<String, dynamic>> transactions) {
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    DateTime firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
    DateTime lastDayOfLastMonth = DateTime(now.year, now.month, 0);

    if (_selectedFilter == "Bulan ini") {
      return transactions.where((t) {
        DateTime date = DateTime.parse(t['datetime']);
        return date.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
            date.isBefore(now.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedFilter == "Bulan lalu") {
      return transactions.where((t) {
        DateTime date = DateTime.parse(t['datetime']);
        return date
                .isAfter(firstDayOfLastMonth.subtract(const Duration(days: 1))) &&
            date.isBefore(lastDayOfLastMonth.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedFilter == "Atur Tanggal" &&
        _startDate != null &&
        _endDate != null) {
      return transactions.where((t) {
        DateTime date = DateTime.parse(t['datetime']);
        return date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            date.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }
    return transactions;
  }

  String _formatCurrency(double value) {
    return 'Rp. ${NumberFormat('#,##0', 'id_ID').format(value)}';
  }

  Future<void> _sharePDF() async {
    final output = await getApplicationDocumentsDirectory();
    final file = File("${output.path}/Laporan_Keuangan.pdf");

    if (await file.exists()) {
      Share.shareXFiles([XFile(file.path)], text: "Laporan transaksi saya 📄");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File PDF belum ditemukan.")),
      );
    }
  }

  void _showFilterDialog(BuildContext context, {Function? afterGenerate}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Pilih Laporan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption(context, "Semua", afterGenerate: afterGenerate),
              _buildFilterOption(context, "Bulan ini", afterGenerate: afterGenerate),
              _buildFilterOption(context, "Bulan lalu", afterGenerate: afterGenerate),
              _buildFilterOption(context, "Atur Tanggal", afterGenerate: afterGenerate),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(BuildContext context, String filter, {Function? afterGenerate}) {
    return ListTile(
      title: Text(filter),
      onTap: () async {
        if (filter == "Atur Tanggal") {
          DateTimeRange? picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );

          if (picked != null) {
            setState(() {
              _selectedFilter = filter;
              _startDate = picked.start;
              _endDate = picked.end;
            });
          } else {
            return;
          }
        } else {
          setState(() {
            _selectedFilter = filter;
          });
        }

        if (context.mounted) {
          Navigator.of(context).pop();
        }

        await Future.delayed(const Duration(milliseconds: 300));
        await _generatePDF();
        if (afterGenerate != null) afterGenerate(); // Kirim setelah selesai generate
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export to PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = "Semua";
                  });
                  _generatePDF();
                },
                child: const Text("Semua"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = "Bulan ini";
                  });
                  _generatePDF();
                },
                child: const Text("Bulan ini"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = "Bulan lalu";
                  });
                  _generatePDF();
                },
                child: const Text("Bulan lalu"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );

                  if (picked != null) {
                    setState(() {
                      _selectedFilter = "Atur Tanggal";
                      _startDate = picked.start;
                      _endDate = picked.end;
                    });
                    _generatePDF();
                  }
                },
                child: const Text("Atur Tanggal"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _showFilterDialog(context, afterGenerate: _sharePDF); // setelah pilih filter, langsung kirim
                },
                child: const Text("Kirim File"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
