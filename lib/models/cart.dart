import 'package:flutter/foundation.dart';

/// 🌍 UNIVERSAL CART ITEM
class CartItem {
  final String id;
  final String name;
  final int price;
  final String service; // Salon / Hotel / Cleaning etc
  final String category;
  final String? image;

  int quantity;
  int adults;
  int children;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.service,
    required this.category,
    this.image,
    this.quantity = 1,
    this.adults = 1,
    this.children = 0,
  });
}

/// 🛒 MAIN CART
class Cart {
  static final List<CartItem> _items = [];

  /// =========================
  /// ➕ ADD ITEM
  /// =========================
  static void add(CartItem item, {required String service}) {
    final index = _items.indexWhere(
      (e) => e.id == item.id && e.service == item.service,
    );

    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(item);
    }

    debugPrint("Added: ${item.name} (${item.service})");
  }

  /// =========================
  /// ➖ REMOVE (DECREASE QTY)
  /// =========================
  static void remove(CartItem item) {
    final index = _items.indexWhere(
      (e) => e.id == item.id && e.service == item.service,
    );

    if (index == -1) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
  }

  /// =========================
  /// ❌ REMOVE BY ID
  /// =========================
  static void removeById(String id, String service) {
    final index = _items.indexWhere(
      (e) => e.id == id && e.service == service,
    );

    if (index == -1) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
  }

  /// =========================
  /// ❌ DELETE COMPLETELY
  /// =========================
  static void delete(CartItem item) {
    _items.removeWhere(
      (e) => e.id == item.id && e.service == item.service,
    );
  }

  /// =========================
  /// 📦 GET ALL ITEMS
  /// =========================
  static List<CartItem> get allItems => _items;

  static get quantities => null;

  /// =========================
  /// 🎯 FILTER BY SERVICE
  /// =========================
  static List<CartItem> getItems(String service) {
    return _items.where((e) => e.service == service).toList();
  }

  /// 🔁 Alias (safe use anywhere)
  static List<CartItem> getByService(String serviceName) {
    return getItems(serviceName);
  }

  /// =========================
  /// 🔢 TOTAL ITEMS
  /// =========================
  static int getTotalItems([String? service]) {
    if (service == null) {
      return _items.fold(0, (sum, e) => sum + e.quantity);
    }

    return _items
        .where((e) => e.service == service)
        .fold(0, (sum, e) => sum + e.quantity);
  }

  /// =========================
  /// 💰 TOTAL PRICE (SERVICE)
  /// =========================
  static int getTotal(String service) {
    return _items
        .where((e) => e.service == service)
        .fold(0, (sum, e) => sum + (e.price * e.quantity));
  }

  /// 🔁 Alias
  static int totalPrice(String serviceName) {
    return getTotal(serviceName);
  }

  /// =========================
  /// 💰 GRAND TOTAL
  /// =========================
  static int getGrandTotal() {
    return _items.fold(
      0,
      (sum, e) => sum + (e.price * e.quantity),
    );
  }

  /// =========================
  /// 🔍 FIND ITEM
  /// =========================
  static CartItem? find(String id, String service) {
    try {
      return _items.firstWhere(
        (e) => e.id == id && e.service == service,
      );
    } catch (e) {
      return null;
    }
  }

  /// =========================
  /// 🔢 GET QUANTITY
  /// =========================
  static int getQuantity(String id, String service) {
    final item = find(id, service);
    return item?.quantity ?? 0;
  }

  /// =========================
  /// 👨‍👩‍👧 UPDATE GUESTS (HOTEL USE)
  /// =========================
  static void updateGuests(
    String id,
    String service, {
    int? adults,
    int? children,
  }) {
    final item = find(id, service);
    if (item == null) return;

    if (adults != null) item.adults = adults;
    if (children != null) item.children = children;
  }

  /// =========================
  /// 🧹 CLEAR CART
  /// =========================
  static void clear([String? service]) {
    if (service == null) {
      _items.clear();
    } else {
      _items.removeWhere((e) => e.service == service);
    }
  }
}
