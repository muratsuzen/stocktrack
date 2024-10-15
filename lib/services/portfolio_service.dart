import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stocktrack/extensions/stock_price_fetcher.dart';
import '../models/stock.dart'; // Stock sınıfı

class PortfolioService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

// Kullanıcının portföy referansı (belirli bir portföy adına göre)
Future<DatabaseReference?> _getUserPortfolioRef(String portfolioName) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Kullanıcı kimliğini al
  String? userId = prefs.getString('userId'); // userId'yi buradan alıyoruz
  if (userId == null || userId.isEmpty) {
    print("User ID is null or empty.");
    return null;
  }
  
  return _databaseRef.child('portfolios').child(userId).child(portfolioName);
}




  // Kullanıcı tipi kontrolü (free veya premium)
  Future<String> getUserSubscriptionType() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('subscriptionType') ?? 'free'; // Free varsayılan
  }

  // Kullanıcının oluşturabileceği portföy sayısını abonelik tipine göre sınırlandırma
  Future<int> getMaxPortfolioCount() async {
    String subscriptionType = await getUserSubscriptionType();
    if (subscriptionType == 'premium') {
      return 5; // Premium kullanıcılar en fazla 5 portföy ekleyebilir
    } else {
      return 1; // Free kullanıcılar sadece 1 portföy ekleyebilir
    }
  }

  // Kullanıcının mevcut portföy sayısını kontrol etme
Future<int> getCurrentPortfolioCount() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Kullanıcı kimliğini al
  String? userId = prefs.getString('userId'); // userId'yi buradan alıyoruz
  if (userId == null || userId.isEmpty) {
    print("User ID is null or empty.");
    return 0;
  }

  final DataSnapshot snapshot = await _databaseRef.child('portfolios').child(userId).get();
  if (snapshot.exists && snapshot.value != null) {
    return (snapshot.value as Map).length; // Mevcut portföy sayısı
  }
  return 0;
}


  // Portföy oluşturma
  Future<void> createPortfolio(String portfolioName) async {
    int maxPortfolioCount = await getMaxPortfolioCount();
    int currentPortfolioCount = await getCurrentPortfolioCount();

    if (currentPortfolioCount >= maxPortfolioCount) {
      print('Kullanıcı mevcut abonelik türünde en fazla $maxPortfolioCount portföy oluşturabilir.');
      return;
    }

    final portfolioRef = await _getUserPortfolioRef(portfolioName);
    if (portfolioRef != null) {
      await portfolioRef.set({
        'portfolioName': portfolioName,
        'createdAt': DateTime.now().toString(),
      });
      print("Portföy oluşturuldu: $portfolioName");
    } else {
      print("Portföy oluşturma hatası: Portföy referansı null.");
    }
  }

// Kullanıcının portföylerini çekme
Future<List<String>> fetchPortfolios() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Kullanıcı kimliğini al
  String? userId = prefs.getString('userId'); // userId'yi buradan alıyoruz
  if (userId == null || userId.isEmpty) {
    print("User ID is null or empty.");
    return [];
  }

  final DataSnapshot snapshot = await _databaseRef.child('portfolios').child(userId).get();
  
  if (snapshot.exists && snapshot.value != null) {
    final Map portfoliosMap = snapshot.value as Map;
    return portfoliosMap.keys.map((key) => key.toString()).toList();
  }
  
  return [];
}


 // Portföy silme metodu
Future<void> deletePortfolio(String portfolioName) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Kullanıcı kimliğini al
    String? userId = prefs.getString('userId'); // userId'yi buradan alıyoruz
    if (userId == null || userId.isEmpty) {
      print("User ID is null or empty.");
      throw Exception('User ID is required to delete portfolio.');
    }

    await _databaseRef.child('portfolios').child(userId).child(portfolioName).remove();
    print('Portfolio $portfolioName has been deleted successfully.');
  } catch (e) {
    print('Error deleting portfolio: $e');
    throw Exception('Failed to delete portfolio: $portfolioName');
  }
}


Future<List<Stock>> fetchStocks(String portfolioName) async {
  final portfolioRef = await _getUserPortfolioRef(portfolioName);
  if (portfolioRef == null) {
    return [];
  }

  final DataSnapshot snapshot = await portfolioRef.child('stocks').get();
  if (snapshot.exists) {
    final Map<Object?, Object?>? stockMap = snapshot.value as Map<Object?, Object?>?;
    if (stockMap != null) {
      List<Stock> stocks = [];

      for (var entry in stockMap.entries) {
        final stockData = entry.value as Map<Object?, dynamic>;

        // Hisse bilgilerini al
        final stock = Stock.fromMap({
          'symbol': stockData['symbol'] as String,
          'quantity': (stockData['quantity'] is int)
              ? stockData['quantity'] as int
              : (stockData['quantity'] as double).toInt(),
          'price': (stockData['price'] is int)
              ? (stockData['price'] as int).toDouble()
              : stockData['price'] as double,
        });

        // Son fiyatı al
        final lastPriceData = await stock.symbol.fetchLastPrice();
        stock.lastPrice = lastPriceData['lastPrice'];

        // Toplam kar/zararı hesapla
        double totalProfitLoss = stock.profitLoss;

        stocks.add(stock);
      }

      return stocks;
    }
  }
  return [];
}




  // Belirli bir portföye hisse ekleme
  Future<void> addStock(String portfolioName, Stock stock) async {
    final portfolioRef = await _getUserPortfolioRef(portfolioName);
    if (portfolioRef != null) {
      await portfolioRef.child('stocks').child(stock.symbol.toUpperCase()).set(stock.toMap());
      print("Hisse eklendi $portfolioName: ${stock.toMap()}");
    } else {
      print("Hisse ekleme hatası: Portföy referansı null.");
    }
  }

  // Belirli bir portföyde hisse güncelleme
  Future<void> updateStock(String portfolioName, Stock stock) async {
    final portfolioRef = await _getUserPortfolioRef(portfolioName);
    if (portfolioRef != null) {
      await portfolioRef.child('stocks').child(stock.symbol.toUpperCase()).set(stock.toMap());
      print("Hisse güncellendi $portfolioName: ${stock.toMap()}");
    } else {
      print("Hisse güncelleme hatası: Portföy referansı null.");
    }
  }

  // Belirli bir portföyde hisse silme
  Future<void> deleteStock(String portfolioName, String symbol) async {
    final portfolioRef = await _getUserPortfolioRef(portfolioName);
    if (portfolioRef != null) {
      await portfolioRef.child('stocks').child(symbol.toUpperCase()).remove();
      print("Hisse silindi $portfolioName: $symbol");
    } else {
      print("Hisse silme hatası: Portföy referansı null.");
    }
  }

  // Kar/Zarar hesaplaması
  Future<double> calculateProfitLoss(String portfolioName, List<Stock> stocks) async {
    double totalInvestment = 0.0;
    double totalCurrentValue = 0.0;

    for (var stock in stocks) { // Hisse listesi üzerinden döngü
  var priceList = await stock.symbol.fetchLastPrice();
  var lastPrice = priceList['lastPrice'];

  // lastPrice'in null olup olmadığını kontrol ediyoruz
  if (lastPrice != null) {
    totalCurrentValue += stock.quantity * lastPrice; // null değilse çarpıyoruz
  } else {
    print('Son fiyat bulunamadı for symbol: ${stock.symbol}');
  }
}

    return totalCurrentValue - totalInvestment; // Kar/Zarar tutarı
  }
}
