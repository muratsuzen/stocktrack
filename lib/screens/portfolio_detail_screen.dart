import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stocktrack/services/portfolio_service.dart';
import '../models/stock.dart';

class PortfolioDetailScreen extends StatefulWidget {
  final String portfolioName;

  const PortfolioDetailScreen({Key? key, required this.portfolioName}) : super(key: key);

  @override
  _PortfolioDetailScreenState createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  final PortfolioService _portfolioService = PortfolioService();
  List<Stock> _stocks = [];
  String _newStockSymbol = '';
  int _newStockQuantity = 0;
  double _newStockPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchStocks(); // Hisse senetlerini yükleyin
  }

  Future<void> _fetchStocks() async {
    final stocks = await _portfolioService.fetchStocks(widget.portfolioName);
    setState(() {
      _stocks = stocks;
    });
  }

  Future<void> _createStock() async {
    if (_newStockSymbol.isNotEmpty && _newStockQuantity > 0 && _newStockPrice > 0) {
      
      final newStock = Stock(
        symbol: _newStockSymbol,
        quantity: _newStockQuantity,
        price: _newStockPrice,
      );
      await _portfolioService.addStock(widget.portfolioName, newStock); // Hisse senedini oluştur
      setState(() {
        _newStockSymbol = '';
        _newStockQuantity = 0;
        _newStockPrice = 0.0;
      });
      _fetchStocks(); // Hisse listesini güncelleyin
    }
  }

double getTotalValue() {
  double totalValue = 0.0;
  for (var stock in _stocks) {
    totalValue += stock.price * stock.quantity;
  }
  return totalValue;
}

double getTotalProfitLoss() {
  double totalProfitLoss = 0.0;
  for (var stock in _stocks) {
    totalProfitLoss += stock.profitLoss; // Burada `profitLoss` özelliğini kullanmalısınız
  }
  return totalProfitLoss;
}

double getNetProfitLoss() {
  
  return getTotalValue()+getTotalProfitLoss();
}

double getTotalPercentChange() {
  double totalPercentChange = 0.0;
  int count = 0;
  for (var stock in _stocks) {
    if (stock.lastPrice != null) {
      totalPercentChange += ((stock.lastPrice! - stock.price) / stock.price) * 100;
      count++;
    }
  }
  return count > 0 ? totalPercentChange / count : 0.0;
}

String formatCurrency(double value) {
    return NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 2).format(value);
  }

List<PieChartSectionData> getChartData() {
  double totalPortfolioValue = _stocks.fold(0, (sum, stock) => sum + (stock.price * stock.quantity)); // Toplam portföy değerini hesapla

  return _stocks.map((stock) {
    double totalValue = stock.price * stock.quantity;
    double percentage = (totalPortfolioValue > 0) ? (totalValue / totalPortfolioValue) * 100 : 0; // Oranı hesapla
    return PieChartSectionData(
      color: Colors.primaries[_stocks.indexOf(stock) % Colors.primaries.length],
      value: percentage, // Oranı değere ata
      title: '${stock.symbol} | ${percentage.toStringAsFixed(1)}%', // Oranı başlıkta göster
      radius: 60,
      titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }).toList();
}


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.portfolioName),
      actions: [
        IconButton(
          icon: Icon(Icons.add),
          onPressed: _showCreateStockDialog, // Pop-up aç
        ),
      ],
    ),
    body: Column(
      children: [// Pasta grafiği
        SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: getChartData(),
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 30,
              ),
            ),
          ),
        // Toplam Değer, Kar/Zarar ve Oranı Göster
        Center(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, // Center the items vertically
      crossAxisAlignment: CrossAxisAlignment.center, // Center the items horizontally
      children: [
        Text(
          '${formatCurrency(getNetProfitLoss())}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          '${formatCurrency(getTotalProfitLoss())} | ${getTotalPercentChange().toStringAsFixed(2)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: getTotalProfitLoss() >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    ),
  ),
),

        Expanded(
          child: ListView.builder(
            itemCount: _stocks.length,
            itemBuilder: (context, index) {
              final stock = _stocks[index];
              double totalValue = stock.price * stock.quantity;
              double profitLoss = stock.profitLoss;
              double? percentChange = stock.lastPrice != null
                  ? ((stock.lastPrice! - stock.price) / stock.price) * 100
                  : null;

              return GestureDetector(
                onLongPress: () {
                  _showStockOptions(stock);
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Sol taraf
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${stock.symbol} | (${formatCurrency(stock.lastPrice??0)})',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Text('${stock.quantity} | ${formatCurrency(stock.price)}',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal)),
                          ],
                        ),
                        // Sağ taraf
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(height: 8,),
                            Text('${formatCurrency(totalValue)}',style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),),
                            Text(
                              '${formatCurrency(profitLoss)} | ${percentChange?.toStringAsFixed(2) ?? 'N/A'}%',
                              style: TextStyle(fontSize: 10,color: profitLoss > 0 ? Colors.green : Colors.red,fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

  void _showCreateStockDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Yeni Hisse Ekle'),
        content: SingleChildScrollView( // İçeriği kaydırılabilir hale getiriyoruz
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  _newStockSymbol = value.toUpperCase();
                },
                decoration: InputDecoration(
                  labelText: 'Hisse Sembolü',
                ),
              ),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _newStockQuantity = int.tryParse(value) ?? 0;
                },
                decoration: InputDecoration(
                  labelText: 'Hisse Adedi',
                ),
              ),
              TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  _newStockPrice = double.tryParse(value) ?? 0.0;
                },
                decoration: InputDecoration(
                  labelText: 'Hisse Fiyatı',
                ),
              ),
            ],
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
              _createStock(); // Hisse oluştur
              Navigator.of(context).pop(); // Dialogu kapat
            },
            child: Text('Ekle'),
          ),
        ],
      );
    },
  );
}

  void _showStockOptions(Stock stock) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Seçenekler'),
          content: Text('Hisse için bir işlem seçin:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialogu kapat
                _showUpdateStockDialog(stock); // Hisse güncelleme
              },
              child: Text('Güncelle'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dialogu kapat
                await _portfolioService.deleteStock(widget.portfolioName, stock.symbol); // Hisse sil
                _fetchStocks(); // Hisse listesini güncelleyin
              },
              child: Text('Sil'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialogu kapat
              },
              child: Text('İptal'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateStockDialog(Stock stock) {
  String updatedSymbol = stock.symbol.toUpperCase();
  int updatedQuantity = stock.quantity;
  double updatedPrice = stock.price;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Hisse Güncelle'),
        content: SingleChildScrollView( // İçeriği kaydırılabilir hale getiriyoruz
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  updatedSymbol = value;
                },
                decoration: InputDecoration(
                  labelText: 'Yeni Hisse Sembolü',
                  hintText: stock.symbol,
                ),
              ),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  updatedQuantity = int.tryParse(value) ?? stock.quantity;
                },
                decoration: InputDecoration(
                  labelText: 'Yeni Hisse Adedi',
                  hintText: stock.quantity.toString(),
                ),
              ),
              TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  updatedPrice = double.tryParse(value) ?? stock.price;
                },
                decoration: InputDecoration(
                  labelText: 'Yeni Hisse Fiyatı',
                  hintText: stock.price.toString(),
                ),
              ),
            ],
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
            onPressed: () async {
              final updatedStock = Stock(
                symbol: updatedSymbol,
                quantity: updatedQuantity,
                price: updatedPrice,
              );
              await _portfolioService.updateStock(widget.portfolioName, updatedStock); // Hisse güncelle
              _fetchStocks(); // Hisse listesini güncelle
              Navigator.of(context).pop(); // Dialogu kapat
            },
            child: Text('Güncelle'),
          ),
        ],
      );
    },
  );
}

}
