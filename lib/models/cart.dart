import 'service_product.dart';

class Cart {
  /// 🔥 SERVICE-WISE CART
  static Map<String, List<ServiceProduct>> serviceItems = {};

  /// 🔢 quantities → service → productId → qty
  static Map<String, Map<String, int>> quantities = {};

  /// 👨‍👩‍👧 guest data → service → productId → {adults, children}
  static Map<String, Map<String, Map<String, int>>> guestData = {};

  /// ➕ ADD ITEM
  static void add(
    ServiceProduct product, {
    int adults = 1,
    int children = 0,
    required String service,
  }) {
    final String service = product.service;
    final String id = product.id;

    serviceItems.putIfAbsent(service, () => []);
    quantities.putIfAbsent(service, () => {});
    guestData.putIfAbsent(service, () => {});

    if (quantities[service]!.containsKey(id)) {
      quantities[service]![id] = quantities[service]![id]! + 1;
    } else {
      serviceItems[service]!.add(product);
      quantities[service]![id] = 1;
    }

    /// 🔹 store guest info (used mainly for Resort)
    guestData[service]![id] = {
      "adults": adults,
      "children": children,
    };
  }

  /// ➖ REMOVE ITEM
  static void remove(ServiceProduct product) {
    final String service = product.service;
    final String id = product.id;

    if (!quantities.containsKey(service) ||
        !quantities[service]!.containsKey(id)) {
      return;
    }

    if (quantities[service]![id]! > 1) {
      quantities[service]![id] = quantities[service]![id]! - 1;
    } else {
      quantities[service]!.remove(id);
      serviceItems[service]!.removeWhere((p) => p.id == id);
      guestData[service]!.remove(id);
    }

    /// 🧹 CLEAN EMPTY SERVICE
    if (serviceItems[service]?.isEmpty ?? false) {
      serviceItems.remove(service);
      quantities.remove(service);
      guestData.remove(service);
    }
  }

  /// 📦 GET ITEMS BY SERVICE
  static List<ServiceProduct> getItems(String service) {
    return serviceItems[service] ?? [];
  }

  /// 🔢 GET QUANTITY
  static int getQuantity(ServiceProduct product) {
    return quantities[product.service]?[product.id] ?? 0;
  }

  /// 👨‍👩‍👧 GET GUEST DATA (Resort use)
  static Map<String, int> getGuestData(ServiceProduct product) {
    return guestData[product.service]?[product.id] ??
        {"adults": 1, "children": 0};
  }

  /// 💰 TOTAL PER SERVICE (UPDATED 🔥)
  static int getTotal(String service) {
    int total = 0;

    final items = serviceItems[service] ?? [];

    for (var item in items) {
      int qty = quantities[service]?[item.id] ?? 1;

      /// ✅ USE YOUR MODEL LOGIC
      total += item.calculatedFinalPrice * qty;
    }

    return total;
  }

  /// 💰 GRAND TOTAL
  static int getGrandTotal() {
    int total = 0;

    for (var service in serviceItems.keys) {
      total += getTotal(service);
    }

    return total;
  }

  /// 🔢 TOTAL ITEMS COUNT
  static int getTotalItems() {
    int count = 0;

    for (var service in quantities.keys) {
      for (var qty in quantities[service]!.values) {
        count += qty;
      }
    }

    return count;
  }

  /// 🗑 CLEAR ONE SERVICE
  static void clearService(String service) {
    serviceItems.remove(service);
    quantities.remove(service);
    guestData.remove(service);
  }

  /// 🧹 CLEAR ALL
  static void clearAll() {
    serviceItems.clear();
    quantities.clear();
    guestData.clear();
  }
}
