import 'package:finanzapp/auth/authentication.dart';
import 'package:finanzapp/beranda/h_beranda.dart';
import 'package:finanzapp/login/daftar.dart';
import 'package:finanzapp/login/file_text.dart';
import 'package:finanzapp/login/h_lupa_pas.dart';
import 'package:finanzapp/login/masuk.dart';
import 'package:finanzapp/pesan/pesan.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _HalamanDaftar();
}

class _HalamanDaftar extends State<LoginScreen> {
  // Kontrol Login Firebase
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false; // Track password visibility

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void masukUsers() async {
    String res = await AuthService().masukUser (
      email: emailController.text,
      password: passwordController.text,
    );
    // pesan untuk kesalahan
    if (res == "success") {
      setState(() {
        isLoading = true;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Bottom(),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      // Melihat Pesan Kesalahan
      showPesan(context, res);
    }
  }

  void togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible; // Toggle visibility
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets .all(16.0), // Add padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: 200,
                child: Image.asset("gambar/login.png"),
              ),
              const SizedBox(height: 15),
              const SizedBox(height: 20), // Add spacing
              // Email input
              FileTextInput(
                textEditingController: emailController,
                hintText: "Masukkan Email",
                icon: Icons.email,
              ),
              const SizedBox(height: 15), // Add spacing
              // Password input with show/hide functionality
              FileTextInput(
                textEditingController: passwordController,
                hintText: "Masukkan Password",
                icon: Icons.lock,
                isPass: true,
                isVisible: isPasswordVisible,
                toggleVisibility: togglePasswordVisibility, // Pass the toggle function
              ),
              const SizedBox(height: 15), // Add spacing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Lupa Password",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Add spacing
              // Masuk ke file masuk.dart
              MasukHalaman(
                onTab: masukUsers,
                text: "Masuk",
              ),
              const SizedBox(height: 20), // Add spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Tidak Punya Akun ? ",
                    style: TextStyle(fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DaftarAkun(),
                        ),
                      );
                    },
                    child: const Text(
                      "Daftar",
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