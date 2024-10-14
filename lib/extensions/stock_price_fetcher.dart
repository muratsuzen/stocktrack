import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

extension StockPriceFetcher on String {
  Future<Map<String, double?>> fetchLastPrice() async {
    final symbol = this; // Uzantıyı kullandığınız sembol
    final url = 'https://www.google.com/finance/quote/$symbol:IST';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // HTML içeriğini parse edin
      final document = parse(response.body);
      
      // 'data-last-price' değerini çekin
      final lastPriceElement = document.querySelector('div[data-last-price]');

      double? lastPrice;
      double? percentChange;

      // Son fiyatı kontrol et
      if (lastPriceElement != null) {
        final lastPriceString = lastPriceElement.attributes['data-last-price'];
        lastPrice = double.tryParse(lastPriceString!);
      }

      return {'lastPrice': lastPrice, 'percentChange': percentChange};
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}
