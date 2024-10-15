class Stock {
  final String symbol; // Hisse sembolü
  final int quantity; // Hisse adedi
  final double price; // Hisse fiyatı
  double? lastPrice; // Opsiyonel son fiyat

  Stock({
    required this.symbol,
    required this.quantity,
    required this.price,
    this.lastPrice, // Opsiyonel olarak lastPrice
  });

  // Toplam kar veya zararı hesaplama
  double get profitLoss {
    if (lastPrice != null) {
      return (lastPrice! - price) * quantity;
    }
    return 0.0; // LastPrice yoksa kar/zarar 0
  }

  // JSON formatında hisse oluşturma
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'price': price,
      'lastPrice': lastPrice, // JSON'a ekle
    };
  }

  // JSON formatından hisse oluşturma
  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'],
      quantity: json['quantity'],
      price: json['price'],
      lastPrice: json['lastPrice'], // JSON'dan lastPrice'ı al
    );
  }

  // Map formatında hisse oluşturma
  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'price': price,
      'lastPrice': lastPrice, // Map'e ekle
    };
  }

  // Map formatından hisse oluşturma
  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(
      symbol: map['symbol'],
      quantity: map['quantity'],
      price: map['price'],
      lastPrice: map['lastPrice'], // Map'ten lastPrice'ı al
    );
  }
}
