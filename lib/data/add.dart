import 'package:finanzapp/data/model/add_date.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class Add_Screen extends StatefulWidget {
  const Add_Screen({super.key});

  @override
  State<Add_Screen> createState() => _Add_ScreenState();
}

class _Add_ScreenState extends State<Add_Screen> {
  final box = Hive.box<Add_data>('data');
  final FirebaseDatabase _database = FirebaseDatabase.instance; // Instance Realtime Database
  DateTime date = DateTime.now();
  String? selectedItem;
  String? selectedItemi;
  final TextEditingController explainController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final FocusNode explainFocusNode = FocusNode();
  final FocusNode amountFocusNode = FocusNode();

  final List<String> _itemei = ['Pemasukan', 'Pengeluaran'];

  @override
  void initState() {
    super.initState();
    // Automatically select the first item in the dropdown
    selectedItemi = _itemei[0]; // Set default selection to the first item
    explainFocusNode.addListener(() {
      setState(() {});
    });
    amountFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    explainController.dispose();
    amountController.dispose();
    explainFocusNode.dispose();
    amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      resizeToAvoidBottomInset: true, // Adjusts the view when the keyboard appears
      body: SafeArea(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            _backgroundContainer(context),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15, // Adjusted position based on screen height
              child: _mainContainer(),
            ),
          ],
        ),
      ),
    );
  }

  Container _mainContainer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      height: MediaQuery.of(context).size.height * 0.7, // 70% of the screen height
      width: MediaQuery.of(context).size.width * 0.85, // 85% of the screen width
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 50),
              _howDropdown(),
              SizedBox(height: 30),
              _nameDropdown(),
              SizedBox(height: 30),
              _explainField(),
              SizedBox(height: 30),
              _amountField(),
              SizedBox(height: 30),
              _dateTimePicker(),
              SizedBox(height: 25), // Adjusted spacing
              _saveButton(),
              SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  GestureDetector _saveButton() {
    return GestureDetector(
      onTap: () async {
        if (selectedItemi == null || selectedItem == null || amountController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Harap isi semua kolom')),
          );
          return;
        }

        var add = Add_data(
          selectedItemi!,
          amountController.text,
          date,
          explainController.text,
          selectedItem!,
        );

        // Tampilkan loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        try {
          // Simpan ke Hive
          await box.add(add);

          // Jalankan Firebase save di luar main thread
          await Future.microtask(() => _saveToFirebase(add));
        } finally {
          // Tutup loading dialog
          if (mounted) Navigator.of(context).pop();
        }

        // Kembali ke layar sebelumnya
        if (mounted) Navigator.of(context).pop();
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.blue,
        ),
        width: MediaQuery.of(context).size.width * 0.5,
        height: 50,
        child: Text(
          'Simpan',
          style: TextStyle(
            fontFamily: 'f',
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Future<void> _saveToFirebase(Add_data add) async {
    try {
      User? user = FirebaseAuth.instance.currentUser ;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You must be logged in to save data')),
          );
        }
        return;
      }

      String uid = user.uid;
      DatabaseReference ref = _database.ref('users/$uid/transactions');
      String newKey = ref.push().key!;

      // Ensure amount is parsed correctly
      int amount = int.tryParse(amountController.text.replaceAll('.', '')) ?? 0;

      await ref.child(newKey).set({
        'category': add.IN,
        'amount': amount,
        'datetime': add.datetime.toIso8601String(),
        'description': add.explain,
        'name': add.name,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data Berhasil di Simpan')),
        );
      }
    } catch (e) {
      print("Terjadi Kesalahan Saat Menyimpan Data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal Menyimpan Data')),
        );
      }
    }
  }

  Widget _dateTimePicker() {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(width: 2, color: Color(0xffC5C5C5)),
      ),
      width: MediaQuery.of(context).size.width * 0.6, // 50% of the screen width
      child: TextButton(
        onPressed: () async {
          DateTime? newDate = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (newDate == null) return;
          setState(() {
            date = newDate;
          });
        },
        child: Text(
          'Tanggal: ${date.day}/ ${date.month} / ${date.year}',
          style: TextStyle(
            fontSize: 15,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Padding _howDropdown() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15),
        width: MediaQuery.of(context).size.width * 0.8, // 80% of the screen width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: 2,
            color: Color(0xffC5C5C5),
          ),
        ),
        child: DropdownButton<String>(
          value: selectedItemi,
          onChanged: (value) {
            setState(() {
              selectedItemi = value;
              selectedItem = null; // Reset selectedItem when changing category
            });
          },
          items: _itemei
              .map((e) => DropdownMenuItem(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        e,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    value: e,
                  ))
              .toList(),
          dropdownColor: Colors.white,
          isExpanded: true,
          underline: Container(),
        ),
      ),
    );
  }


  Padding _amountField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        keyboardType: TextInputType.number,
        focusNode: amountFocusNode,
        controller: amountController,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          TextInputFormatter.withFunction((oldValue, newValue) {
            if (newValue.text.isEmpty) {
              return newValue.copyWith(text: '');
            }

            final value = int.tryParse(newValue.text.replaceAll('.', '')) ?? 0;
            final formattedValue = NumberFormat('#,##0', 'id_ID'). format(value);

            return newValue.copyWith(text: formattedValue);
          }),
        ],
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          labelText: 'Nominal',
          labelStyle: TextStyle(fontSize: 17, color: Colors.grey.shade500),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(width: 2, color: Color(0xffC5C5C5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(width: 2, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Padding _explainField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        focusNode: explainFocusNode,
        controller: explainController,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          labelText: 'Penjelasan',
          labelStyle: TextStyle(fontSize: 17, color: Colors.grey.shade500),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(width: 2, color: Color(0xffC5C5C5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(width: 2, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Padding _nameDropdown() {
    List<String> filteredItems = [];
    if (selectedItemi == 'Pemasukan') {
      filteredItems = ['Dividen', 'Gaji', 'Investasi', 'Transfer', 'Tunjangan', 'Lainnya'];
    } else if (selectedItemi == 'Pengeluaran') {
      filteredItems = ['Liburan', 'Kesehatan','Makan', 'Pendidikan', 'Perjalanan', 'Tagihan', 'Lainnya'];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15),
        width: MediaQuery.of(context).size.width * 0.8, // 80% of the screen width
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: 2,
            color: Color(0xffC5C5C5),
          ),
        ),
        child: DropdownButton<String>(
          value: selectedItem,
          onChanged: (value) {
            setState(() {
              selectedItem = value;
            });
          },
          items: filteredItems
              .map((e) => DropdownMenuItem(
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            child: Image.asset('gambar/${e}.png'),
                          ),
                          SizedBox(width: 10),
                          Text(
                            e,
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    value: e,
                  ))
              .toList(),
          hint: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              'Nama',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          dropdownColor: Colors.white,
          isExpanded: true,
          underline: Container(),
        ),
      ),
    );
  }

  Column _backgroundContainer(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.3, // 30% of the screen height
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Text(
                        'Tambah',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      Icon(
                        Icons.attach_file_outlined,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}