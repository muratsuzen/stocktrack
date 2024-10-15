import 'stock.dart';

class Portfolio {
  final String name; // Portföy adı
  final List<Stock> stocks; // Hisse senetleri listesi

  Portfolio({
    required this.name,
    required this.stocks,
  });

  // JSON formatında portföy oluşturma
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stocks': stocks.map((stock) => stock.toJson()).toList(),
    };
  }

  // JSON formatından portföy oluşturma
  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      name: json['name'],
      stocks: (json['stocks'] as List).map((item) => Stock.fromJson(Map<String, dynamic>.from(item))).toList(),
    );
  }
}
