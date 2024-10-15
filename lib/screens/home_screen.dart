import 'package:flutter/material.dart';
import 'package:stocktrack/l10n/app_localizations.dart'; // Localization sınıfı import edilir
import 'portfolio_screen.dart'; // Yeni sayfanın içe aktarılması
import 'profile_screen.dart'; // Profil ekranının içe aktarılması

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('stock_track'),
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.person), // Profil simgesi
            onPressed: () {
              // Profil ekranına yönlendirme
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: PortfolioScreen(), // Sadece PortfolioScreen açılır
      backgroundColor: Colors.black,
    );
  }
}
