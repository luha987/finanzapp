import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finanzapp/data/model/add_date.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Stream<DatabaseEvent> _transactionStream;
  final box = Hive.box<Add_data>('data');
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference _transactionsRef;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String nama = '...';
  String email = '...';
  String _selectedFilter = "Semua";

  double totalPemasukan = 0.0;
  double totalPengeluaran = 0.0;
  double totalSaldo = 0.0;

  @override
  void initState() {
    super.initState();
    _transactionsRef = _database.ref().child('users').child(FirebaseAuth.instance.currentUser ?.uid ?? '').child('transactions');
    _transactionStream = _transactionsRef.onValue;
    _fetchUser ();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _fetchUser () async {
    try {
      final user = FirebaseAuth.instance.currentUser ;
      if (user == null) {
        print('Harap Masuk Terlebih Dahulu !');
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          nama = userDoc['nama'] ?? 'No Name';
          email = userDoc['email'] ?? 'No Email';
        });
      } else {
        print("Data Terjadi Error !");
      }
    } catch (e) {
      print("Terjadi kesalahan saat mengambil data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: _transactionStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return Center(child: Text("Harap masukkan data terlebih dahulu"));
            }

            DateTime now = DateTime.now();
            DateTime startOfMonth = DateTime(now.year, now.month, 1); // Awal bulan ini
            DateTime startOfLastMonth = DateTime(now.year, now.month - 1, 1); // Awal bulan lalu
            DateTime endOfLastMonth = DateTime(now.year, now.month, 0); // Akhir bulan lalu

            final data = snapshot.data!.snapshot.value as Map?;
            if (data == null) return Center(child: Text("Transaksi masih kosong !"));

            List<Map<String, dynamic>> transactionList = [];
            
            data.forEach((key, value) {
              if (value is Map) {
                transactionList.add(Map.from(value));
              }
            });

            List<Map<String, dynamic>> filteredTransactions = transactionList.where((transaction) {
              String name = transaction['name'].toString().toLowerCase();
              String description = transaction['description'].toString().toLowerCase();
              DateTime transactionDate = DateTime.parse(transaction['datetime']);

              bool matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || description.contains(_searchQuery);
              
              bool matchesFilter = _selectedFilter == "Semua" ||
                  (_selectedFilter == "Bulan ini" && transactionDate.isAfter(startOfMonth.subtract(Duration(days: 1)))) ||
                  (_selectedFilter == "Bulan lalu" &&
                      transactionDate.isAfter(startOfLastMonth.subtract(Duration(days: 1))) &&
                      transactionDate.isBefore(endOfLastMonth.add(Duration(days: 1))));

              return matchesSearch && matchesFilter;
            }).toList();

            // Reverse the order of transactions to show the latest first
            filteredTransactions.sort((a, b) {
              DateTime dateA = DateTime.parse(a['datetime']);
              DateTime dateB = DateTime.parse(b['datetime']);
              return dateB.compareTo(dateA);
            });

            // Calculate totals for Pemasukan, Pengeluaran, and Saldo
            totalPemasukan = 0.0;
            totalPengeluaran = 0.0;
            transactionList.forEach((transaction) {
              double amount = double.tryParse(transaction['amount'].toString()) ?? 0.0; // Ensure conversion
              if (transaction['category'] == 'Pemasukan') {
                totalPemasukan += amount;
              } else if (transaction['category'] == 'Pengeluaran') {
                totalPengeluaran += amount;
              }
            });
            totalSaldo = totalPemasukan - totalPengeluaran;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: 300, child: _buildHeader()),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Untuk membuat sejajar kiri-kanan
                          children: [
                            Text(
                              'Riwayat Transaksi',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 19,
                                color: Colors.black,
                              ),
                            ),
                            // DropdownButton<String>(
                            //   value: _selectedFilter,
                            //   items: ["Semua", "Bulan ini", "Bulan lalu"].map((filter) {
                            //     return DropdownMenuItem(
                            //       value: filter,
                            //       child: Text(filter),
                            //     );
                            //   }).toList(),
                            //   onChanged: (value) {
                            //     if (value != null) {
                            //       setState(() {
                            //         _selectedFilter = value; // Pastikan nilai diperbarui
                            //       });
                            //     }
                            //   },
                            // ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: "Pencarian",
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: Colors.black45,
                              ),
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15), // Mengatur radius border
                                borderSide: BorderSide(
                                  color: Colors.red, // Warna border
                                  width: 2.0, // Ketebalan border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.blue, // Warna border saat fokus
                                  width: 2, // Ketebalan border saat fokus
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < 0 || index >= filteredTransactions.length) {
                        return SizedBox(); // Hindari akses indeks di luar batas
                      }
                      final transaction = filteredTransactions[index];
                      DateTime date = DateTime.parse(transaction['datetime']);
                      return ListTile(
                        title: Text(transaction['name']),
                        subtitle: Text(
                          '${date.day}/${date.month}/${date.year}\n${transaction['description']}',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: Text('Rp. ${NumberFormat('#,##0', 'id_ID').format(double.tryParse(transaction['amount'].toString()) ?? 0.0)}'),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.asset('gambar/${transaction['name']}.png'),
                        ),
                        isThreeLine: true,
                      );
                    },
                    childCount: filteredTransactions.length, // Pastikan nilainya benar
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 35, left: 10, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $nama',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Color.fromARGB(255, 224, 223, 223),
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment(0, 0.4), // Posisi vertikal lebih ke bawah
          child: Container(
            height: 160,
            width: 330,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(31, 84, 162, 0.717),
                  offset: Offset(0, 6),
                  blurRadius: 12,
                  spreadRadius: 6,
                ),
              ],
              color: Colors.blue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Keuangan',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Rp. ${NumberFormat('#,##0', 'id_ID').format(totalSaldo)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: totalSaldo >= 0 ? Colors.greenAccent : Colors.redAccent,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 8.0,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: Color.fromARGB(255, 53, 143, 85),
                              child: Icon(
                                Icons.arrow_upward,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Color.fromARGB(255, 216, 216, 216),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: Color.fromARGB(220, 240, 3, 3),
                              child: Icon(
                                Icons.arrow_downward,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Color.fromARGB(255, 216, 216, 216),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rp. ${NumberFormat('#,##0', 'id_ID').format(totalPemasukan)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.greenAccent,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 8.0,
                              )
                            ],
                          ),
                        ),
                        Text(
                          'Rp. -${NumberFormat('#,##0', 'id_ID').format(totalPengeluaran)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.redAccent,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 8.0,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}