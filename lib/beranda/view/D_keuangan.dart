import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class KeuanganScreen extends StatefulWidget {
  const KeuanganScreen({super.key});

  @override
  State<KeuanganScreen> createState() => _KeuanganScreenState();
}

class _KeuanganScreenState extends State<KeuanganScreen> {
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
        .child(FirebaseAuth.instance.currentUser ?.uid ?? '')
        .child('transactions');
  }

  String formatCurrency(double value) {
    return 'Rp. ${NumberFormat('#,##0', 'id_ID').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Keuangan"),
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            items: ["Semua", "Bulan ini", "Bulan lalu", "Atur Tanggal"].map((filter) {
              return DropdownMenuItem(
                value: filter,
                child: Text(filter),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
                if (_selectedFilter == "Atur Tanggal") {
                  _selectDateRange();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _transactionsRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Terjadi Kesalahan: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("Data tidak ada"));
                }

                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final List<Map<String, dynamic>> pemasukanList = [];
                final List<Map<String, dynamic>> pengeluaranList = [];

                double totalPemasukan = 0.0;
                double totalPengeluaran = 0.0;

                DateTime now = DateTime.now();
                DateTime startOfMonth = DateTime(now.year, now.month, 1);
                DateTime startOfLastMonth = DateTime(now.year, now.month - 1, 1);
                DateTime endOfLastMonth = DateTime(now.year, now.month, 0);
                
                if (now.month == 1) {
                  startOfLastMonth = DateTime(now.year - 1, 12, 1);
                  endOfLastMonth = DateTime(now.year, 1, 0); // This will give you December 31 of the previous year
                }

                data.forEach((key, value) {
                  final transaction = Map<String, dynamic>.from(value);
                  transaction['key'] = key;

                  DateTime transactionDate = DateTime.parse(transaction['datetime']);

                  bool isValid = _selectedFilter == "Semua" ||
                    (_selectedFilter == "Bulan ini" && transactionDate.isAfter(startOfMonth.subtract(Duration(days: 1)))) ||
                    (_selectedFilter == "Bulan lalu" &&
                        transactionDate.isAfter(startOfLastMonth.subtract(Duration(days: 1))) &&
                        transactionDate.isBefore(endOfLastMonth.add(Duration(days: 1)))) ||
                    (_selectedFilter == "Atur Tanggal" && _startDate != null && _endDate != null &&
                        transactionDate.isAfter(_startDate!.subtract(Duration(days: 1))) &&
                        transactionDate.isBefore(_endDate!.add(Duration(days: 1))));

                  if (isValid) {
                    if (transaction['category'] == 'Pemasukan') {
                      pemasukanList.add(transaction);
                      totalPemasukan += double.tryParse(transaction['amount'].toString()) ?? 0.0;
                    } else if (transaction['category'] == 'Pengeluaran') {
                      pengeluaranList.add(transaction);
                      totalPengeluaran += double.tryParse(transaction['amount'].toString()) ?? 0.0;
                    }
                  }
                });

                pemasukanList.sort((a, b) => DateTime.parse(b['datetime']).compareTo(DateTime.parse(a['datetime'])));
                pengeluaranList.sort((a, b) => DateTime.parse(b['datetime']).compareTo(DateTime.parse(a['datetime'])));

                final totalSaldo = totalPemasukan - totalPengeluaran;

                return ListView(
                  children: [
                    _buildTransactionSection('Pemasukan', pemasukanList, totalPemasukan),
                    const Divider(),
                    _buildTransactionSection('Pengeluaran', pengeluaranList, totalPengeluaran),
                    const Divider(),
                    ListTile(
                      title: const Text("Sisa Saldo"),
                      subtitle: Text(formatCurrency(totalSaldo)),
                      trailing: Icon(
                        totalSaldo >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: totalSaldo >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection(String title, List<Map<String, dynamic>> transactions, double total) {
    if (transactions.isEmpty) {
      return ListTile(
        title: Text(title),
        subtitle: const Text("Data Masih Kosong!"),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text('Total: ${formatCurrency(total)}'),
        ),
        ...transactions.map((transaction) {
          DateTime date = DateTime.parse(transaction['datetime']);
          return ListTile(
            title: Text(transaction['name']),
            subtitle: Text(transaction['description']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${formatCurrency(double.parse(transaction['amount'].toString()))}\n ${date.day}/${date.month}/${date.year}'),
                const SizedBox(width: 8), // Add some spacing
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditTransactionDialog(transaction),
                ),
              ],
            ),
            leading: Icon(
              title == 'Pemasukan' ? Icons.arrow_upward : Icons.arrow_downward,
              color: title == 'Pemasukan' ? Colors.green : Colors.red,
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showEditTransactionDialog(Map<String, dynamic> transaction) {
    final descriptionController = TextEditingController(text: transaction['description']);
    final amountController = TextEditingController(text: transaction['amount'].toString());
    
    final List<String> categoryOptions = ['Pemasukan', 'Pengeluaran'];
    List<String> nameOptions = [];

    String selectedCategory = transaction['category'];
    String selectedName = transaction['name'];
    DateTime selectedDate = DateTime.tryParse(transaction['datetime'] ?? '') ?? DateTime.now();

    void updateNameOptions() {
      if (selectedCategory == 'Pemasukan') {
        nameOptions = ['Dividen', 'Gaji', 'Investasi', 'Transfer', 'Tunjangan'];
      } else if (selectedCategory == 'Pengeluaran') {
        nameOptions = ['Liburan', 'Kesehatan', 'Makan', 'Pendidikan', 'Perjalanan', 'Tagihan'];
      }
      if (!nameOptions.contains(selectedName)) {
        selectedName = nameOptions.isNotEmpty ? nameOptions.first : '';
      }
    }

    updateNameOptions();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Transaksi"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categoryOptions.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                          updateNameOptions();
                        });
                      },
                      decoration: const InputDecoration(labelText: "Kategori"),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedName,
                      items: nameOptions.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedName = value!;
                        });
                      },
                      decoration: const InputDecoration(labelText: "Nama"),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: "Deskripsi"),
                    ),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: "Jumlah"),
                      keyboardType: TextInputType.number,
                    ),
                    TextButton(
                      onPressed: () async {
                        final newDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (newDate != null) {
                          setState(() {
                            selectedDate = newDate;
                          });
                        }
                      },
                      child: Text(
                        "Tanggal: ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updatedTransaction = {
                      'name': selectedName,
                      'description': descriptionController.text,
                      'amount': double.tryParse(amountController.text) ?? 0.0,
                      'category': selectedCategory,
                      'datetime': selectedDate.toIso8601String(),
                    };

                    _transactionsRef.child(transaction['key']).update(updatedTransaction).then((_) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Transaksi berhasil diperbarui")),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal memperbarui transaksi: \$error")),
                      );
                    });
                  },
                  child: const Text("Simpan"),
                ),
                TextButton(
                  onPressed: () {
                    _transactionsRef.child(transaction['key']).remove().then((_) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Transaksi berhasil dihapus")),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Gagal menghapus transaksi: \$error")),
                      );
                    });
                  },
                  child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
    }
  }
}