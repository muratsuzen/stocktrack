import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock.dart';
import '../services/portfolio_service.dart';
import 'portfolio_detail_screen.dart'; // PortfolioService'i buradan ekliyoruz

class PortfolioScreen extends StatefulWidget {
  @override
  _PortfolioScreenState createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final PortfolioService _portfolioService = PortfolioService();
  List<String> _portfolios = []; // Portföy isimlerini tutacak liste

  @override
  void initState() {
    super.initState();
    _fetchPortfolios(); // Portföyleri yükleyin
  }

  Future<void> _fetchPortfolios() async {
    final portfolios = await _portfolioService.fetchPortfolios();
    setState(() {
      _portfolios = portfolios;
    });
  }

  Future<void> _createPortfolio(String portfolioName) async {
    if (portfolioName.isNotEmpty) {
      await _portfolioService.createPortfolio(portfolioName);
      _fetchPortfolios(); // Portföy listesini güncelleyin
    }
  }

  void _showCreatePortfolioDialog() {
    String newPortfolioName = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Yeni Portföy Oluştur'),
          content: TextField(
            onChanged: (value) {
              newPortfolioName = value;
            },
            decoration: InputDecoration(
              labelText: 'Portföy Adı',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialogu kapat
              },
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                _createPortfolio(newPortfolioName); // Portföy oluştur
                Navigator.of(context).pop(); // Dialogu kapat
              },
              child: Text('Oluştur'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _showCreatePortfolioDialog, // Pop-up aç
              child: Text('Yeni Portföy Ekle'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _portfolios.length,
              itemBuilder: (context, index) {
                final portfolioName = _portfolios[index];
                return ListTile(
                  title: Text(portfolioName),
                  onTap: () {
                    // Portföy detay ekranına geçiş yapabilirsiniz
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PortfolioDetailScreen(portfolioName: portfolioName),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      // Portföy silme işlemi
                      await _portfolioService.deletePortfolio(portfolioName);
                      _fetchPortfolios(); // Portföy listesini güncelleyin
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


