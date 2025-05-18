import 'package:finanzapp/auth/authentication.dart';
import 'package:finanzapp/beranda/view/halaman_profile.dart';
import 'package:finanzapp/login/file_text.dart';
import 'package:finanzapp/login/login.dart';
import 'package:finanzapp/login/masuk.dart';
import 'package:finanzapp/pesan/pesan.dart';
import 'package:flutter/material.dart';

class DaftarAkun extends StatefulWidget {
  const DaftarAkun({super.key});

  @override
  State<DaftarAkun> createState() => _DaftarAkunState();
}

class _DaftarAkunState extends State<DaftarAkun> {
  // Kontrol Login Firebase
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false; // Track password visibility

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    namaController.dispose();
    super.dispose();
  }

  void togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible; // Toggle visibility
    });
  }

  void daftarAkun() async {
    setState(() {
      isLoading = true; // Start loading
    });

    String res = await AuthService().DaftarUser (
      email: emailController.text,
      password: passwordController.text,
      nama: namaController.text,
    );

    // pesan untuk kesalahan
    if (res == "success") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HalamanProfile(),
        ),
      );
    } else {
      // Melihat Pesan Kesalahan
      showPesan(context, res);
    }

    setState(() {
      isLoading = false; // Stop loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView( // Make the content scrollable
          padding: const EdgeInsets.all(16.0), // Add padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: 250,
                child: Image.asset("gambar/daftar.jpg"),
              ),
              const SizedBox(height: 20), // Add spacing
              // File text for Name, Email, and Password
              FileTextInput(
                textEditingController: namaController,
                hintText: "Masukkan Nama",
                icon: Icons.person,
              ),
              const SizedBox(height: 15), // Add spacing
              FileTextInput(
                textEditingController: emailController,
                hintText: "Masukkan Email",
                icon: Icons.email,
              ),
              const SizedBox(height: 15), // Add spacing
              FileTextInput(
                textEditingController: passwordController,
                hintText: "Masukkan Password",
                isPass: true,
                icon: Icons.lock,
                isVisible: isPasswordVisible,
                toggleVisibility: togglePasswordVisibility, // Pass the toggle function
              ),
              const SizedBox(height: 20), // Add spacing
              // Masuk ke file masuk.dart
              isLoading
                  ? const CircularProgressIndicator() // Show loading indicator
                  : MasukHalaman(
                      onTab: daftarAkun,
                      text: "Daftar",
                    ),
              const SizedBox(height: 15), // Add spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Sudah Punya Akun ? ",
                    style: TextStyle(fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Masuk",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}