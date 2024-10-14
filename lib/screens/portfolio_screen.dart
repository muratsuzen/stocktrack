import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../extensions/shared_preferences_extension.dart';
import '../extensions/stock_price_fetcher.dart';

class Stock {
  final String symbol;
  final int amount;
  final double price;

  Stock({required this.symbol, required this.amount, required this.price});

  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'amount': amount,
      'price': price,
    };
  }

  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(
      symbol: map['symbol'],
      amount: map['amount'],
      price: map['price'],
    );
  }
}

class PortfolioScreen extends StatefulWidget {
  @override
  _PortfolioScreenState createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final DatabaseReference _portfolioRef =
      FirebaseDatabase.instance.ref().child('portfolio');
  List<Stock> _stocks = [];
  double _totalValue = 0;
  String? _userEmail;

  double? _totalCost; // Toplam maliyet
  double profitLoss = 0.0; // Kar/Zarar tutarı


  final NumberFormat _numberFormat =
      NumberFormat('#,##0.00', 'tr_TR'); // Türkçe format

  @override
  void initState() {
    super.initState();
    _fetchUserEmail().then((_) {
      if (_userEmail != null) {
        _fetchStocks(); // E-posta başarıyla alındıysa hisse senetlerini çek
      } else {
        print("User email is null, cannot fetch stocks.");
      }
    });
  }

  Future<void> _fetchUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('userEmail'); // E-posta adresini al
    _userEmail = _sanitizedEmail(_userEmail); // E-posta adresini temizle
    print("Fetched user email: $_userEmail");
  }

// Örnek sanitize fonksiyonu
  String? _sanitizedEmail(String? email) {
    if (email == null) return null;
    // Geçersiz karakterleri değiştir
    return email
        .replaceAll('@', '_at_')
        .replaceAll('.', '_dot_')
        .trim(); // Boşlukları temizle
  }

  List<PieChartSectionData> _buildPieChartSections() {
    // Eğer hisse senedi listesi boşsa, boş bir liste döndür
    if (_stocks.isEmpty) return [];

    // Toplam değeri hesaplayın
    _totalValue =
        _stocks.fold(0, (sum, stock) => sum + (stock.price * stock.amount));

    // Toplam değer sıfır ise, işlem yapmayın
    if (_totalValue <= 0) {
      print("Total value is zero or negative. Cannot calculate percentages.");
      return []; // Boş bir liste döndür
    }

    return _stocks
        .map((stock) {
          // Yüzde hesaplama
          final value = (stock.price * stock.amount) / _totalValue * 100;

          // NaN kontrolü
          if (value.isNaN) {
            print("Calculated value is NaN for stock: ${stock.symbol}");
            return null; // Eğer NaN ise null döndür
          }

          return PieChartSectionData(
            color: Colors.primaries[_stocks.indexOf(stock) %
                Colors.primaries.length], // Renk belirleme
            value: value,
            title:
                '${stock.symbol}\n${_numberFormat.format(value)}%', // Başlık formatlama
            radius: 50, // Çemberin yarıçapı
            titleStyle:
                TextStyle(color: Colors.white, fontSize: 12), // Başlık stili
          );
        })
        .where((section) => section != null)
        .cast<PieChartSectionData>()
        .toList(); // null olanları filtreleme
  }

  // Hisse ekleme popup'ı
  void _showAddSymbolDialog() {
    String symbol = '';
    int amount = 0;
    double price = 0;

    showDialog(
      context: context,
      builder: (context) {
        var appLocalizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(appLocalizations.translate('add_symbol'),
              style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                    labelText: appLocalizations.translate('symbol'),
                    labelStyle: TextStyle(color: Colors.black)),
                onChanged: (value) {
                  symbol = value;
                },
              ),
              TextField(
                decoration: InputDecoration(
                    labelText: appLocalizations.translate('amount'),
                    labelStyle: TextStyle(color: Colors.black)),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  amount = int.tryParse(value) ?? 0;
                },
              ),
              TextField(
                decoration: InputDecoration(
                    labelText: appLocalizations.translate('price'),
                    labelStyle: TextStyle(color: Colors.black)),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  price = double.tryParse(value) ?? 0.0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(appLocalizations.translate('cancel'),
                  style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                if (symbol.isNotEmpty && amount > 0 && price > 0) {
                  _addStock(symbol, amount, price);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields correctly')),
                  );
                }
              },
              child: Text(appLocalizations.translate('add'),
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  // Hisse güncelleme popup'ı
  void _showUpdateStockDialog(Stock stock, String key) {
    String symbol = stock.symbol;
    int amount = stock.amount;
    double price = stock.price;

    showDialog(
      context: context,
      builder: (context) {
        var appLocalizations = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(appLocalizations.translate('update_stock'),
              style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                    labelText: appLocalizations.translate('symbol'),
                    labelStyle: TextStyle(color: Colors.black)),
                onChanged: (value) {
                  symbol = value;
                },
                controller: TextEditingController(text: stock.symbol),
              ),
              TextField(
                decoration: InputDecoration(
                    labelText: appLocalizations.translate('amount'),
                    labelStyle: TextStyle(color: Colors.black)),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  amount = int.tryParse(value) ?? stock.amount;
                },
                controller:
                    TextEditingController(text: stock.amount.toString()),
              ),
              TextField(
                decoration: InputDecoration(
                    labelText: appLocalizations.translate('price'),
                    labelStyle: TextStyle(color: Colors.black)),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  price = double.tryParse(value) ?? stock.price;
                },
                controller: TextEditingController(text: stock.price.toString()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(appLocalizations.translate('cancel'),
                  style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                if (symbol.isNotEmpty && amount > 0 && price > 0) {
                  _updateStock(key, symbol, amount, price);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields correctly')),
                  );
                }
              },
              child: Text(appLocalizations.translate('update'),
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchStocks() async {
  final String? userEmail = _userEmail;
  final _portfolioRef = FirebaseDatabase.instance.ref('portfolio/$userEmail');

  _portfolioRef.once().then((DatabaseEvent event) async {
    final snapshot = event.snapshot;
    if (snapshot.exists) {
      print("snapshot.value: ${snapshot.value}");

      if (snapshot.value is Map) {
        Map<Object?, Object?> rawMap = snapshot.value as Map<Object?, Object?>;

        List<Stock> stocksList = rawMap.entries.map((entry) {
          var stockData = entry.value as Map<Object?, dynamic>;
          return Stock.fromMap({
            'symbol': stockData['symbol'] as String,
            'amount': (stockData['amount'] is int)
                ? stockData['amount'] as int
                : (stockData['amount'] as double).toInt(),
            'price': (stockData['price'] is int)
                ? (stockData['price'] as int).toDouble()
                : stockData['price'] as double,
          });
        }).toList();

        // Listeyi güncelleyin
        setState(() {
          _stocks = stocksList;
        });

        // Kar/Zarar hesaplama işlemini başlat
        await _calculateProfitLoss();
      } else {
        print("Snapshot value is not a Map.");
      }
    } else {
      print("No stocks found");
    }
  }).catchError((error) {
    print("Failed to fetch stocks: $error");
  });
}

// Kar/Zarar hesaplaması
Future<void> _calculateProfitLoss() async {
  double totalInvestment = 0.0;
  double totalCurrentValue = 0.0;

  for (var stock in _stocks) {
    // Alış maliyetini hesapla
    totalInvestment += stock.amount * stock.price;

    // Her hisse senedinin güncel fiyatını getir
    var lastPriceMap = await stock.symbol.fetchLastPrice();
    var lastPrice = lastPriceMap['lastPrice'] ?? 0.0;

    // Güncel piyasa değerini hesapla
    totalCurrentValue += stock.amount * lastPrice;
  }

  // Kar/Zarar hesaplaması
  double calculatedProfitLoss = totalCurrentValue - totalInvestment;

  // Ekranı güncelle
  setState(() {
    profitLoss = calculatedProfitLoss;
  });

  print("Profit/Loss: $profitLoss");
}


// Yeni hisse ekleme işlemi
  void _addStock(String symbol, int amount, double price) {
    Stock newStock =
        Stock(symbol: symbol.toUpperCase(), amount: amount, price: price);
    final String? userEmail = _userEmail;
    final _portfolioRef = FirebaseDatabase.instance.ref('portfolio/$userEmail');
    _portfolioRef
        .child(symbol.toUpperCase()) // Hisse sembolünü anahtar olarak kullan
        .set(newStock.toMap())
        .then((_) {
      _fetchStocks();
      print("Stock added: ${newStock.toMap()}");
    }).catchError((error) {
      print("Failed to add stock: $error");
    });
  }

// Hisse güncelleme işlemi
  Future<void> _updateStock(
      String key, String symbol, int amount, double price) async {
    Stock updatedStock = Stock(
      symbol: symbol.toUpperCase(),
      amount: amount,
      price: price,
    );

    final String? userEmail = _userEmail;
    if (userEmail == null) {
      print("User email is null. Cannot update stock.");
      return;
    }

    final _portfolioRef = FirebaseDatabase.instance.ref('portfolio/$userEmail');
    try {
      await _portfolioRef.child(symbol.toUpperCase()).set(updatedStock.toMap());
      print("Stock updated: ${updatedStock.toMap()}");

      await _fetchStocks(); // Fetch updated stocks after the update
    } catch (error) {
      print("Failed to update stock: $error");
    }
  }

// Hisse silme işlemi
  void _deleteStock(String symbol) {
    // Anahtar olarak sembol kullan
    final String? userEmail = _userEmail;
    final _portfolioRef = FirebaseDatabase.instance.ref('portfolio/$userEmail');
    _portfolioRef.child(symbol.toUpperCase()).remove().then((_) {
      _fetchStocks();
      print("Stock deleted");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock deleted successfully')),
      );
    }).catchError((error) {
      print("Failed to delete stock: $error");
    });
  }

  // Hisse uzun basılınca açılan menü
  void _showContextMenu(Stock stock, String key) {
    var appLocalizations = AppLocalizations.of(context);
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        PopupMenuItem(
          value: 'update',
          child: Text(appLocalizations.translate('update')),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(appLocalizations.translate('delete')),
        ),
      ],
    ).then((value) {
      if (value == 'update') {
        _showUpdateStockDialog(stock, key);
      } else if (value == 'delete') {
        _deleteStock(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var appLocalizations = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(),
                centerSpaceRadius: 45,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, // Sağda hizalama
              children: [
                // Toplam Değer (Total Value)
                Text(
                  '${_numberFormat.format(_totalValue)}', // Para formatı
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10), // Araya boşluk ekleyelim

                // Kar/Zarar Tutarı
                if (profitLoss != null) // Kar/Zarar tutarı varsa göster
                  Text(
                    _numberFormat
                        .format(profitLoss!), // Kar/Zarar tutarını formatla
                    style: TextStyle(
                      fontSize: 16, // Yazı boyutu
                      fontWeight: FontWeight.normal,
                      color: (profitLoss <
                              0) // Kar/Zarar negatifse kırmızı, pozitifse yeşil
                          ? Colors.red
                          : Colors.green,
                    ),
                  )
                else
                  // Eğer profitLoss null ise alternatif bir metin göster
                  Text(
                    'Kar/Zarar bilgisi mevcut değil', // Alternatif metin
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _stocks.length,
              itemBuilder: (context, index) {
                Stock stock = _stocks[index];
                String key = _portfolioRef
                    .child(stock.symbol)
                    .key!; // Her hissenin anahtarı

                return GestureDetector(
                  onLongPress: () => _showContextMenu(stock, key),
                  child: ListTile(
                    title: Text(
                      stock.symbol,
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${appLocalizations.translate('amount')}: ${_numberFormat.format(stock.amount)}\n'
                      '${appLocalizations.translate('price')}: ${_numberFormat.format(stock.price)}',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: FutureBuilder<Map<String, double?>>(
                      future: stock.symbol
                          .fetchLastPrice(), // Son fiyat ve yüzdelik değişim almak için çağırıyoruz
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                            '...', // Yükleniyor durumu
                            style: TextStyle(color: Colors.grey),
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            appLocalizations.translate(
                                'error_fetching_price'), // Hata durumu
                            style: TextStyle(color: Colors.grey),
                          );
                        } else {
                          final lastPrice = snapshot.data?['lastPrice'];
                          final price = stock.price; // Portföy fiyatı
                          final amount = stock.amount; // Toplam miktar

                          String lastPriceFormatted = lastPrice != null
                              ? _numberFormat.format(lastPrice)
                              : appLocalizations
                                  .translate('no_data'); // Son fiyat yoksa

                          // Yüzde değişim hesaplama
                          double? percentChange;
                          if (lastPrice != null && price != 0) {
                            percentChange = ((lastPrice - price) / price) *
                                100; // Yüzde değişimi hesapla
                          }

                          // Kar/Zarar hesaplama
                          double? profitLoss;
                          if (lastPrice != null) {
                            profitLoss = (lastPrice - price) *
                                amount; // Kar/Zarar hesapla
                          }

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                lastPriceFormatted, // Son fiyat
                                style: TextStyle(color: Colors.grey),
                              ),
                              if (percentChange !=
                                  null) // Yüzde değişim varsa göster
                                Text(
                                  '(${percentChange.toStringAsFixed(2)}%)', // Yüzde değişimi 2 ondalık ile göster
                                  style: TextStyle(
                                    color: percentChange <
                                            0 // Yüzde değişimi negatifse kırmızı, pozitifse yeşil
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              if (profitLoss !=
                                  null) // Kar/Zarar tutarı varsa göster
                                Text(
                                  _numberFormat.format(
                                      profitLoss), // Kar/Zarar tutarını formatla
                                  style: TextStyle(
                                    color: profitLoss <
                                            0 // Kar/Zarar negatifse kırmızı, pozitifse yeşil
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _showAddSymbolDialog,
              child: Text(appLocalizations.translate('add_symbol')),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
