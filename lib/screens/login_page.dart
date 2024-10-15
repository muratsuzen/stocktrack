import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stocktrack/screens/home_screen.dart';
import '../l10n/app_localizations.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signInWithEmail(BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (userCredential.user != null) {
        // Kullanıcının ID'sini sakla
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userCredential.user!.uid);
        await prefs.setString('userEmail', _emailController.text);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      print(e); // Hata mesajını yazdır
      // Burada kullanıcıya hata mesajını gösterebilirsiniz
    }
  }

  Future<User?> _signInWithGoogle(BuildContext context) async {
    try {
      // Google ile giriş yap
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Kullanıcı giriş işlemini iptal etti
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Kimlik bilgilerini oluştur
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase'de giriş yap
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        // Kullanıcının ID'sini sakla
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userCredential.user!.uid);
        
        // Ana ekrana yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
      return userCredential.user;  // Kullanıcıyı döndür
    } catch (error) {
      print('Giriş hatası: $error');  // Hata mesajını yazdır
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context); // Localization'ı alın

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              appLocalizations.translate('welcome'), // Çeviri ile metin
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: appLocalizations.translate('email'), // Çeviri ile metin
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: appLocalizations.translate('password'), // Çeviri ile metin
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _signInWithEmail(context);
              },
              child: Text(appLocalizations.translate('sign_in_email')), // Çeviri ile metin
            ),
            SizedBox(height: 10),
            Text(appLocalizations.translate('or')), // Çeviri ile metin
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _signInWithGoogle(context);
              },
              child: Text(appLocalizations.translate('sign_in_google')), // Çeviri ile metin
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            // Kayıt ol butonu
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()), // Kayıt sayfasına yönlendir
                );
              },
              child: Text(appLocalizations.translate('register')), // Çeviri ile metin
            ),
          ],
        ),
      ),
    );
  }
}
