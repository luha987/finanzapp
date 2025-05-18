import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  ForgotPasswordScreen({super.key});

  void sendResetEmail(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    
    try {
      await auth.sendPasswordResetEmail(email: emailController.text);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Email Reset Password'),
            content: const Text('Email reset password berhasil dikirim! Cek kotak masuk Anda.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error: $e');
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Gagal mengirim email reset password. Silakan coba lagi.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restart Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Masukkan alamat email',
                hintStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                border: InputBorder.none,
                filled: true,
                fillColor: const Color(0xFFedf0f8),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    width: 2,
                    color: Colors.greenAccent,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => sendResetEmail(context),
              child: Text('Kirim Email Reset Password',
                style: TextStyle(color: Colors.black)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
