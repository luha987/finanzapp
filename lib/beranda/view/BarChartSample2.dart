import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartPP extends StatefulWidget {
  const ChartPP({super.key});

  @override
  State<ChartPP> createState() => _ChartPPState();
}

class _ChartPPState extends State<ChartPP> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference _transactionsRef;
  late TooltipBehavior _tooltipBehavior;
  List<Map<String, dynamic>> transactionList = [];
  List<ChartData> pemasukanData = [];
  List<ChartData> pengeluaranData = [];
  String selectedPeriod = 'Year'; // Default period

  @override
  void initState() {
    super.initState();
    _transactionsRef = _database
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser?.uid ?? '')
        .child('transactions');
    _tooltipBehavior =
        TooltipBehavior(enable: true); // Initialize TooltipBehavior
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    pemasukanData.clear();
    pengeluaranData.clear();
    _transactionsRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map?;
      transactionList.clear();

      if (data != null) {
        data.forEach((key, value) {
          double amount = double.tryParse(value['amount'].toString()) ?? 0.0;
          String dateString =
              value['datetime'] ?? ''; // Assuming you have a datetime field
          String category = value['category'] ?? ''; // Get the category

          try {
            DateTime dateTime =
                DateTime.parse(dateString); // Ensure this is in a valid format
            transactionList.add({
              'date': dateTime,
              'amount': amount,
              'category': category,
            });
          } catch (e) {
            // Handle date parsing error
            print('Error parsing date: $dateString');
          }
        });

        // Sort the transaction list by date
        transactionList.sort((a, b) => a['date'].compareTo(b['date']));
        updateChartData(); // Update chart data after fetching transactions
      }
    });
  }

  void updateChartData() {
    List<Map<String, dynamic>> filteredTransactions =
        filterTransactions(selectedPeriod);

    // Clear previous data
    pemasukanData.clear();
    pengeluaranData.clear();

    if (selectedPeriod == 'Year') {
      Map<String, double> pemasukanBulanan = {};
      Map<String, double> pengeluaranBulanan = {};

      for (var transaction in filteredTransactions) {
        String monthKey = DateFormat('MM/yyyy').format(transaction['date']);
        double amount = transaction['amount'];

        if (transaction['category'] == 'Pemasukan') {
          pemasukanBulanan[monthKey] =
              (pemasukanBulanan[monthKey] ?? 0) + amount;
        } else if (transaction['category'] == 'Pengeluaran') {
          pengeluaranBulanan[monthKey] =
              (pengeluaranBulanan[monthKey] ?? 0) + amount;
        }
      }

      pemasukanBulanan.forEach((month, total) {
        pemasukanData.add(ChartData(month, total, Colors.green));
      });

      pengeluaranBulanan.forEach((month, total) {
        pengeluaranData.add(ChartData(month, total, Colors.red));
      });
    } else if (selectedPeriod == 'Month' ||
        selectedPeriod == 'Week') {
      Map<String, double> pemasukanHarian = {};
      Map<String, double> pengeluaranHarian = {};

      for (var transaction in filteredTransactions) {
        String dayKey = DateFormat('dd/MM').format(transaction['date']);
        double amount = transaction['amount'];

        if (transaction['category'] == 'Pemasukan') {
          pemasukanHarian[dayKey] = (pemasukanHarian[dayKey] ?? 0) + amount;
        } else if (transaction['category'] == 'Pengeluaran') {
          pengeluaranHarian[dayKey] = (pengeluaranHarian[dayKey] ?? 0) + amount;
        }
      }

      pemasukanHarian.forEach((day, total) {
        pemasukanData.add(ChartData(day, total, Colors.green));
      });

      pengeluaranHarian.forEach((day, total) {
        pengeluaranData.add(ChartData(day, total, Colors.red));
      });
    } else if (selectedPeriod == 'Day') {
      Map<String, double> pemasukanHarian = {};
      Map<String, double> pengeluaranHarian = {};

      for (var transaction in filteredTransactions) {
        String timeKey = DateFormat('HH:mm').format(transaction['date']); // Use HH:mm for daily transactions
        double amount = transaction['amount'];

        if (transaction['category'] == 'Pemasukan') {
          pemasukanHarian[timeKey] = (pemasukanHarian[timeKey] ?? 0) + amount;
        } else if (transaction['category'] == 'Pengeluaran') {
          pengeluaranHarian[timeKey] = (pengeluaranHarian [timeKey] ?? 0) + amount;
        }
      }

      pemasukanHarian.forEach((time, total) {
        pemasukanData.add(ChartData(time, total, Colors.green));
      });

      pengeluaranHarian.forEach((time, total) {
        pengeluaranData.add(ChartData(time, total, Colors.red));
      });
    }
    setState(() {}); // Refresh the UI
  }

  List<Map<String, dynamic>> filterTransactions(String period) {
    DateTime now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 'Day':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59); // Akhir hari yang sama
        break;
      case 'Week':
        startDate = now.subtract(Duration(days: now.weekday - 0));
        endDate = startDate.add(Duration(days: 7)).subtract(Duration(seconds: 1));
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month, 0);
        endDate = DateTime(now.year, now.month + 1, 1).subtract(Duration(seconds: 1));
        break;
      case 'Year':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1).subtract(Duration(seconds: 1));
        break;
      default:
        startDate = DateTime(1970);
        endDate = DateTime.now();
    }

    return transactionList.where((transaction) {
      DateTime transactionDate = transaction['date'];
      return transactionDate.isAfter(startDate) &&
          transactionDate.isBefore(endDate);
    }).toList();
  }

  String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date); // Format to time only
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date); // Format to date
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        actions: [
          ToggleButtons(
            isSelected: [
              selectedPeriod == 'Day',
              selectedPeriod == 'Week',
              selectedPeriod == 'Month',
              selectedPeriod == 'Year',
            ],
            onPressed: (int index) {
              setState(() {
                switch (index) {
                  case 0:
                    selectedPeriod = 'Day';
                    break;
                  case 1:
                    selectedPeriod = 'Week';
                    break;
                  case 2:
                    selectedPeriod = 'Month';
                    break;
                  case 3:
                    selectedPeriod = 'Year';
                    break;
                }
                updateChartData();
              });
            },
            fillColor: Colors.blue,
            selectedColor: Colors.white,
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            children: const [
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Harian')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Mingguan')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Bulanan')),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Tahunan')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                fetchTransactions();
              });
            },
          ),
        ],
      ),
      body: Container(
        height: 500,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: pemasukanData.isEmpty && pengeluaranData.isEmpty
              ? CircularProgressIndicator()
              : SfCartesianChart(
                  tooltipBehavior: _tooltipBehavior,
                  primaryXAxis: CategoryAxis(),
                  series: <CartesianSeries>[
                    LineSeries<ChartData, String>(
                      dataSource: pemasukanData,
                      pointColorMapper: (ChartData data, _) => data.color,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                      dataLabelSettings: DataLabelSettings(isVisible: true),
                      name: 'Pemasukan', // Name for the legend
                    ),
                    LineSeries<ChartData, String>(
                      dataSource: pengeluaranData,
                      pointColorMapper: (ChartData data, _) => data.color,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                      dataLabelSettings: DataLabelSettings(isVisible: true),
                      name: 'Pengeluaran', // Name for the legend
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class ChartData {
  final String x;
  final double y;
  final Color color;

  ChartData(this.x, this.y, this.color);
}
