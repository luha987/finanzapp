import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService{
  // Untuk menyimpan data di Cloud Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

// Untuk Mendaftar
Future<String> DaftarUser (
  {
    required String email,
    required String password,
    required String nama,
  }) async {
  String res = "Tolong Masukkan dengan Benar !";
  try {
    if(email.isNotEmpty || password.isNotEmpty || nama.isNotEmpty) {
      // Untuk identifikasi pendaftaran email dan password kedalam firebase
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // untuk menyimpan user ke cloud firestore firebase
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'nama': nama,
        'email': email,
        'uid': credential.user!.uid,
      });
      // untuk menyimpan password user ke cloud firestore firebase
      res = "Daftar Sukses";
    }
  } catch (e) {
    return e.toString();
  }
  return res;
  }

  // login Screen
  Future<String> masukUser({
    required String email,
    required String password,
  }) async {
    String res = "Tolong Masukkan dengan Benar !";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // login user untuk email dan password
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        res = "success";
      } else {
        res = "Tolong Masukkan dengan Benar !";
      }
    } catch (e) {
      return e.toString();
    }
    return res;
  }

  // Log Out
  Future<void> signOut() async{
    await _auth.signOut();
  }
}