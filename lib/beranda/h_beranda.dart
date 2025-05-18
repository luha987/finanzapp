import 'package:finanzapp/beranda/view/BarChartSample2.dart';
import 'package:finanzapp/beranda/view/D_keuangan.dart';
import 'package:finanzapp/beranda/view/halaman_profile.dart';
import 'package:finanzapp/beranda/view/home.dart';
import 'package:finanzapp/data/add.dart';
import 'package:flutter/material.dart';

class Bottom extends StatefulWidget {
  const Bottom({Key? key}) : super(key: key);

  @override
  State<Bottom> createState() => _BottomState();
}

class _BottomState extends State<Bottom> {
  int selectedIndex = 0; // Renamed for clarity

  // Adjust this list to include the correct screens
  List<Widget> screens = [
    Home(), // Home Screen
    ChartPP(), // Statistics Screen
    KeuanganScreen(), // Placeholder for Wallet Screen (replace with actual screen)
    HalamanProfile(), // Placeholder for Profile Screen (replace with actual screen)
  ];

  void onTabTapped(int index) {
    setState(() {
      selectedIndex = index; // Update the selected index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex], // Use selectedIndex to display the correct screen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the Add_Screen instead of Update_Screen
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => Add_Screen()),
          );
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.only(top: 7.5, bottom: 7.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabTapped(0),
                  child: Icon(
                    Icons.home,
                    size: 30,
                    color: selectedIndex == 0 ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabTapped(1),
                  child: Icon(
                    Icons.bar_chart_outlined,
                    size: 30,
                    color: selectedIndex == 1 ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
              SizedBox(width: 30), // untuk kasih jarak untuk FloatingActionButton
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabTapped(2),
                  child: Icon(
                    Icons.notes,
                    size: 30,
                    color: selectedIndex == 2 ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabTapped(3),
                  child: Icon(
                    Icons.person_outlined,
                    size: 30,
                    color: selectedIndex == 3 ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}