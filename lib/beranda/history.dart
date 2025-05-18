import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference _transactionsRef;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = "Semua"; // Variabel untuk dropdown
  DateTime now = DateTime.now();
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _transactionsRef = _database
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser?.uid ?? '')
        .child('transactions');

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _filterTransaction(DateTime transactionDate) {
    if (_selectedFilter == "Bulan ini") {
      return transactionDate.month == now.month &&
          transactionDate.year == now.year;
    } else if (_selectedFilter == "Bulan lalu") {
      DateTime lastMonth = DateTime(now.year, now.month - 1);
      return transactionDate.month == lastMonth.month &&
          transactionDate.year == lastMonth.year;
    } else if (_selectedFilter == "Costum Tanggal" &&
        _customStartDate != null &&
        _customEndDate != null) {
      return transactionDate.isAfter(_customStartDate!) &&
          transactionDate.isBefore(_customEndDate!);
    }
    return true;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            items: ["Semua", "Bulan ini", "Bulan lalu", "Costum Tanggal"]
                .map((filter) {
              return DropdownMenuItem(
                value: filter,
                child: Text(filter),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFilter = value;
                });
                if (value == "Costum Tanggal") {
                  _selectDateRange(context);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Pencarian",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _transactionsRef.orderByChild('datetime').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("Data Masih Kosong"));
                }

                final data = snapshot.data!.snapshot.value as Map?;
                if (data == null)
                  return const Center(child: Text("Tidak ada transaksi"));

                List<Map> transactionList = [];
                data.forEach((key, value) {
                  transactionList.add(Map.from(value));
                });

                transactionList.sort((a, b) {
                  DateTime dateA = DateTime.parse(a['datetime']);
                  DateTime dateB = DateTime.parse(b['datetime']);
                  return dateB.compareTo(dateA);
                });

                List<Map> filteredTransactions =
                    transactionList.where((transaction) {
                  DateTime transactionDate =
                      DateTime.parse(transaction['datetime']);
                  return _filterTransaction(transactionDate) &&
                      (transaction['name']
                              .toString()
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          transaction['description']
                              .toString()
                              .toLowerCase()
                              .contains(_searchQuery));
                }).toList();

                return ListView.builder(
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    DateTime date = DateTime.parse(transaction['datetime']);
                    return ListTile(
                      title: Text(transaction['name']),
                      subtitle: Text(
                        '${transaction['description']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: Text(
                        'Rp. ${NumberFormat('#,##0', 'id_ID').format(int.parse(transaction['amount'].toString()))}\n${date.day}/${date.month}/${date.year}',
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.asset('gambar/${transaction['name']}.png'),
                      ),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
