import 'dart:io';

import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportCSV extends StatefulWidget {
  const ExportCSV({super.key});

  @override
  State<ExportCSV> createState() => _ExportCSVState();
}

class _ExportCSVState extends State<ExportCSV> {
  final DatabaseReference _transactionsRef = FirebaseDatabase.instance
      .ref()
      .child('users')
      .child(FirebaseAuth.instance.currentUser?.uid ?? '')
      .child('transactions');

  String _selectedFilter = "Semua";
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pilih Laporan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption("Semua"),
            _buildFilterOption("Bulan ini"),
            _buildFilterOption("Bulan lalu"),
            _buildFilterOption("Atur Tanggal"),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String filter) {
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
            _startDate = picked.start;
            _endDate = picked.end;
          } else {
            return;
          }
        }
        _selectedFilter = filter;
        Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 300));
        await exportToCSV();
        _shareCSV();
      },
    );
  }

  Future<void> _shareCSV() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/Laporan_Keuangan.csv");
    if (await file.exists()) {
      Share.shareXFiles([XFile(file.path)], text: "Laporan transaksi saya 📄");
    } else {
      _showMessage("File tidak ditemukan!");
    }
  }

  Future<void> exportToCSV() async {
    try {
      final snapshot = await _transactionsRef.once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null || data.isEmpty) {
        _showMessage("Tidak ada transaksi untuk diekspor.");
        return;
      }

      List<Map<String, dynamic>> transactions = data.entries
          .map((entry) => Map<String, dynamic>.from(entry.value))
          .toList();

      transactions.sort((a, b) =>
          DateTime.parse(a['datetime']).compareTo(DateTime.parse(b['datetime'])));

      transactions = _filterTransactions(transactions);

      final pemasukan = transactions.where((t) => t['category'] == 'Pemasukan');
      final pengeluaran = transactions.where((t) => t['category'] == 'Pengeluaran');

      List<List<dynamic>> csvData = [
        ['Kategori', 'Nama', 'Deskripsi', 'Tanggal', 'Jumlah']
      ];

      for (var t in pemasukan) {
        csvData.add(_mapTransactionToRow(t));
      }

      if (pengeluaran.isNotEmpty) {
        csvData.add(['', '', '', '', '']);
        for (var t in pengeluaran) {
          csvData.add(_mapTransactionToRow(t));
        }
      }

      final csv = const ListToCsvConverter().convert(csvData);
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/Laporan_Keuangan.csv");
      await file.writeAsString(csv);

      _showMessage("CSV berhasil disimpan di ${file.path}");
    } catch (e) {
      _showMessage("Terjadi kesalahan saat mengekspor CSV: $e");
    }
  }

  List<Map<String, dynamic>> _filterTransactions(List<Map<String, dynamic>> txs) {
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    DateTime firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
    DateTime lastDayLastMonth = DateTime(now.year, now.month, 0);

    return txs.where((t) {
      DateTime date = DateTime.parse(t['datetime']);
      if (_selectedFilter == "Bulan ini") {
        return date.isAfter(firstDayOfMonth.subtract(const Duration(days: 1))) &&
            date.isBefore(now.add(const Duration(days: 1)));
      } else if (_selectedFilter == "Bulan lalu") {
        return date.isAfter(firstDayLastMonth.subtract(const Duration(days: 1))) &&
            date.isBefore(lastDayLastMonth.add(const Duration(days: 1)));
      } else if (_selectedFilter == "Atur Tanggal" && _startDate != null && _endDate != null) {
        return date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            date.isBefore(_endDate!.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  List<dynamic> _mapTransactionToRow(Map<String, dynamic> t) {
    final date = DateTime.parse(t['datetime']);
    return [
      t['category'],
      t['name'],
      t['description'],
      DateFormat('dd/MM/yyyy').format(date),
      _formatCurrency(double.parse(t['amount'].toString())),
    ];
  }

  String _formatCurrency(double value) {
    return 'Rp. ${NumberFormat('#,##0', 'id_ID').format(value)}';
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export to CSV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(20),
          shrinkWrap: true,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedFilter = "Semua");
                exportToCSV();
              },
              child: const Text("Semua"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedFilter = "Bulan ini");
                exportToCSV();
              },
              child: const Text("Bulan ini"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() => _selectedFilter = "Bulan lalu");
                exportToCSV();
              },
              child: const Text("Bulan lalu"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
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
                  exportToCSV();
                }
              },
              child: const Text("Atur Tanggal"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _showFilterDialog(context),
              child: const Text("Kirim file"),
            ),
          ],
        ),
      ),
    );
  }
}
