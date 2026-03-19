import '../models/service_product.dart';

class Cart {
  static List<ServiceProduct> items = [];

  // product -> quantity
  static Map<ServiceProduct, int> quantities = {};

  /// 🆕 STORE GUEST DATA (NEW - SAFE ADDITION)
  static Map<ServiceProduct, Map<String, int>> guestData = {};

  /// ➕ ADD TO CART
  static void add(ServiceProduct product, {int adults = 1, int children = 0}) {
    if (quantities.containsKey(product)) {
      quantities[product] = quantities[product]! + 1;
    } else {
      items.add(product);
      quantities[product] = 1;
    }

    /// ✅ SAVE GUEST DATA
    guestData[product] = {
      "adults": adults,
      "children": children,
    };
  }

  /// ➖ REMOVE FROM CART
  static void remove(ServiceProduct product) {
    if (!quantities.containsKey(product)) return;

    if (quantities[product]! > 1) {
      quantities[product] = quantities[product]! - 1;
    } else {
      quantities.remove(product);
      items.remove(product);

      /// ✅ ALSO REMOVE GUEST DATA
      guestData.remove(product);
    }
  }

  /// 🗑 CLEAR CART
  static void clear() {
    items.clear();
    quantities.clear();
    guestData.clear(); // ✅ clear guests also
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
