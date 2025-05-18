import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart'; // Import the csv package
import 'package:finanzapp/auth/authentication.dart';
import 'package:finanzapp/beranda/export/csv.dart';
import 'package:finanzapp/beranda/export/pdf.dart';
import 'package:finanzapp/beranda/history.dart';
import 'package:finanzapp/login/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class HalamanProfile extends StatefulWidget {
  const HalamanProfile({super.key});

  @override
  State<HalamanProfile> createState() => _HalamanProfileState();
}

class _HalamanProfileState extends State<HalamanProfile> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference _transactionsRef;

  String nama = '';
  String email = '';
  String imageUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchUser(); // Ambil nama, email, dan gambar saat widget pertama kali dibuat
    _transactionsRef = _database
        .ref()
        .child('users')
        .child(FirebaseAuth.instance.currentUser?.uid ?? '')
        .child('transactions'); // Initialize the reference
  }

  Future<void> _fetchUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Harap Masuk Terlebih Dahulu!');
        return;
      }

      // Ambil data pengguna dari Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        setState(() {
          nama = userDoc['nama'] ?? 'No Name'; // Tampilkan nama jika ada
          email = userDoc['email'] ?? 'No Email'; // Tampilkan email jika ada
          imageUrl = userDoc['imageUrl'] ?? ''; // Tampilkan gambar jika ada
        });
      } else {
        setState(() {
          nama = userDoc['nama'] ?? 'No Name'; // Tampilkan nama jika ada
          email = userDoc['email'] ?? 'No Email'; // Tampilkan email jika ada
        });
      }
    } catch (e) {
      print("Terjadi kesalahan saat mengambil data pengguna: $e");
    }
  }

  Future<void> _uploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      File originalImage = File(pickedFile.path);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("User  belum login.");
        return;
      }

      // Kompres dan ubah ukuran gambar
      img.Image? image = img.decodeImage(originalImage.readAsBytesSync());
      if (image != null) {
        img.Image resizedImage =
            img.copyResize(image, width: 300); // Resize ke lebar 300px
        File compressedImage = File(pickedFile.path)
          ..writeAsBytesSync(img.encodeJpg(resizedImage,
              quality: 85)); // Simpan dengan kualitas 85%

        // Upload ke Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}.jpg');
        final uploadTask = await storageRef.putFile(compressedImage);

        // Ambil URL unduhan
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        // Simpan URL ke Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'imageUrl': downloadUrl,
        });

        setState(() {
          imageUrl = downloadUrl; // Perbarui gambar di UI
        });

        print("Gambar berhasil diupload.");
      } else {
        print("Gambar tidak valid.");
      }
    } catch (e) {
      print("Terjadi kesalahan saat mengunggah gambar: $e");
    }
  }

  Future<void> _deleteImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User belum login.");
        return;
      }

      bool confirmDelete = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Konfirmasi"),
            content: Text("Menghapus foto profil ?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Hapus"),
              ),
            ],
          );
        },
      );

      if (!confirmDelete) return;

      // Hapus dari Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');
      await storageRef.delete();

      // Hapus URL dari Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'imageUrl': '',
      });

      setState(() {
        imageUrl = ''; // Kembalikan ke default
      });

      print("Gambar berhasil dihapus.");
    } catch (e) {
      print("Terjadi kesalahan saat menghapus gambar: $e");
    }
  }


  Future<void> exportToCSV(BuildContext context) async {
    try {
      final dataSnapshot = await _transactionsRef.once();
      final data = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null || data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tidak ada transaksi untuk diekspor.")),
        );
        return;
      }

      List<Map<String, dynamic>> transactions = data.entries.map((entry) {
        return Map<String, dynamic>.from(entry.value);
      }).toList();

      // Urutkan transaksi berdasarkan tanggal (terlama ke terbaru)
      transactions.sort((a, b) => DateTime.parse(a['datetime']).compareTo(DateTime.parse(b['datetime'])));

      List<List<dynamic>> csvData = [];
      csvData.add(['Kategori', 'Nama', 'Deskripsi', 'Tanggal', 'Jumlah']); // Header

      transactions.forEach((transaction) {
        final dateTime = DateTime.parse(transaction['datetime']);
        csvData.add([
          transaction['category'],
          transaction['name'],
          transaction['description'],
          DateFormat('dd/MM/yyyy').format(dateTime),
          formatCurrency(double.parse(transaction['amount'].toString())),
        ]);
      });

      String csv = const ListToCsvConverter().convert(csvData);

      final appDirectory = Directory("sdcard/FinanzApp");
      if (!await appDirectory.exists()) {
        await appDirectory.create(recursive: true);
      }

      final file = File("sdcard/FinanzApp/transactions.csv");
      await file.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("CSV berhasil disimpan di ${file.path}")),
      );
    } catch (e) {
      print("Terjadi kesalahan saat mengekspor CSV: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal Export CSV! Berikan Izin Penyimpanan.")),
      );
    }
  }

  String formatCurrency(double value) {
    return 'Rp. ${NumberFormat('#,##0', 'id_ID').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext bc) {
                      return Wrap(
                        children: <Widget>[
                          ListTile(
                            leading: Icon(Icons.upload),
                            title: Text('Unggah Foto'),
                            onTap: () {
                              Navigator.pop(context);
                              _uploadImage();
                            },
                          ),
                          if (imageUrl.isNotEmpty)
                            ListTile(
                              leading: Icon(Icons.delete),
                              title: Text('Hapus Foto'),
                              onTap: () {
                                Navigator.pop(context);
                                _deleteImage();
                              },
                            ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl.isEmpty
                      ? Image.asset(
                          'gambar/user.png',
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 10),
              Center(
                child: Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Center(
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
              SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                },
                child: const Text("Riwayat Transaksi"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExportPDF()),
                  ); // Call the PDF export function
                },
                child: const Text("Export PDF"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExportCSV()),
                  ); // Call the CSV export function
                },
                child: const Text("Export CSV"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await AuthService().signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text("Keluar"),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
