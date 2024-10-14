import 'package:flutter/material.dart';
import 'package:stocktrack/l10n/app_localizations.dart'; // Localization sınıfı import edilir
import 'portfolio_screen.dart'; // Yeni sayfanın içe aktarılması

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Toplam tab sayısı
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).translate('stock_track'), style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.black,
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context).translate('portfolio')), // İlk sekme
              Tab(text: AppLocalizations.of(context).translate('empty')),     // İkinci sekme
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PortfolioScreen(), // İlk sekmede PortfolioScreen
            Center(
              child: Text(
                AppLocalizations.of(context).translate('empty'),
                style: TextStyle(color: Colors.white, fontSize: 24),
              ), // İkinci sekmede boş bir ekran
            ),
          ],
        ),
        backgroundColor: Colors.black,
      ),
    );
  }
}
