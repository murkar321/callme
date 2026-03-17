import '../models/service_product.dart';

class Cart {
  static List<ServiceProduct> items = [];

  // product -> quantity
  static Map<ServiceProduct, int> quantities = {};

  /// ➕ ADD TO CART
  static void add(ServiceProduct product) {
    if (quantities.containsKey(product)) {
      quantities[product] = quantities[product]! + 1;
    } else {
      items.add(product);
      quantities[product] = 1;
    }
  }

  /// ➖ REMOVE FROM CART
  static void remove(ServiceProduct product) {
    if (!quantities.containsKey(product)) return;

    if (quantities[product]! > 1) {
      quantities[product] = quantities[product]! - 1;
    } else {
      quantities.remove(product);
      items.remove(product);
    }
  }

  /// 🗑 CLEAR CART
  static void clear() {
    items.clear();
    quantities.clear();
  }

  /// 💰 TOTAL PRICE
  static int getTotal() {
    int total = 0;

    for (var item in items) {
      int qty = quantities[item] ?? 1;
      total += (item.finalPrice ?? item.price) * qty;
    }

    return total;
  }
}