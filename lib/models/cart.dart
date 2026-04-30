import 'package:callme/data/cleaning_data.dart';
import 'package:callme/data/service_product.dart';


/// 🌍 UNIVERSAL CART ITEM
class CartItem {
  final String id;
  final String name;
  final int price;
  final String service;
  final String category;
  final String? image;

  int quantity;
  int adults;
  int children;

  /// Salon support
  String? visitType;

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
    this.visitType,
  });
}

/// 🛒 UNIVERSAL CART
class Cart {
  static final List<CartItem> _items = [];

  /// =========================
  /// ➕ ADD
  /// =========================
  static void add(CartItem item, {required String service}) {
    final index = _items.indexWhere(
      (e) =>
          e.id.toString().trim() == item.id.toString().trim() &&
          e.service == service,
    );

    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(item);
    }
  }

  /// =========================
  /// ➕ ADD GENERIC
  /// =========================
  static void addItem({
    required String id,
    required String name,
    required int price,
    required String service,
    required String category,
    String? image,
    int adults = 1,
    int children = 0,
  }) {
    add(
      CartItem(
        id: id,
        name: name,
        price: price,
        service: service,
        category: category,
        image: image,
        adults: adults,
        children: children,
      ),
      service: service,
    );
  }

  /// =========================
  /// 💧 WATER / 🧹 CLEANING / 🚿 PLUMBING
  /// =========================
  static void addProduct(ServiceProduct product, String service) {
    add(
      CartItem(
        id: product.id.toString(),
        name: product.name,
        price: product.calculatedFinalPrice,
        service: service,
        category: product.service,
        image: product.imagePath,
      ),
      service: service,
    );
  }

  /// =========================
  /// 🎓 EDUCATION
  /// =========================
  static void addEducation({
    required String id,
    required String name,
    required int price,
    required String category,
    String? image,
  }) {
    addItem(
      id: id,
      name: name,
      price: price,
      service: "Education",
      category: category,
      image: image,
    );
  }

  /// =========================
  /// ➖ REMOVE
  /// =========================
  static void removeById(String id, String service) {
    final index = _items.indexWhere(
      (e) =>
          e.id.toString().trim() == id.toString().trim() &&
          e.service == service,
    );

    if (index == -1) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
  }

  /// =========================
  /// ❌ DELETE
  /// =========================
  static void delete(String id, String service) {
    _items.removeWhere(
      (e) =>
          e.id.toString().trim() == id.toString().trim() &&
          e.service == service,
    );
  }

  /// =========================
  /// 📦 GET ITEMS
  /// =========================
  static List<CartItem> getItems(String service) {
    return _items.where((e) => e.service == service).toList();
  }

  /// =========================
  /// 🔢 TOTAL ITEMS
  /// =========================
  static int getTotalItems(String service) {
    return _items
        .where((e) => e.service == service)
        .fold(0, (sum, e) => sum + e.quantity);
  }

  /// =========================
  /// 💰 TOTAL PRICE
  /// =========================
  static int getTotal(String service) {
    return _items
        .where((e) => e.service == service)
        .fold(
          0,
          (sum, e) =>
              sum +
              (e.price * e.quantity * e.adults) +
              ((e.price ~/ 2) * e.children),
        );
  }

  /// =========================
  /// 🔥 FIXED (IMPORTANT)
  /// =========================
  static int getQuantity(String id, String service) {
    try {
      final item = _items.firstWhere(
        (e) =>
            e.id.toString().trim() == id.toString().trim() &&
            e.service == service,
      );
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  /// =========================
  /// 🧹 CLEANING SUPPORT (OLD SAFE)
  /// =========================
  static void addCleaning(CleaningService service) {
    addItem(
      id: service.name,
      name: service.name,
      price: service.finalPrice,
      service: "Cleaning",
      category: "Cleaning",
      image: service.image,
    );
  }

  /// =========================
  /// 🧺 LAUNDRY (UNCHANGED)
  /// =========================
  static void addLaundry({
    required String id,
    required String name,
    required int price,
    required String category,
    String? image,
  }) {
    add(
      CartItem(
        id: id,
        name: name,
        price: price,
        service: "Laundry",
        category: category,
        image: image,
      ),
      service: "Laundry",
    );
  }

  /// =========================
  /// 💇 SALON (UNCHANGED)
  /// =========================
  static void addSalon({
    required String id,
    required String name,
    required int price,
    required String category,
    required String visitType,
    String? image,
  }) {
    add(
      CartItem(
        id: id,
        name: name,
        price: price,
        service: "Salon",
        category: category,
        image: image,
        visitType: visitType,
      ),
      service: "Salon",
    );
  }

  /// =========================
  /// 🧹 CLEAR
  /// =========================
  static void clear([String? service]) {
    if (service == null) {
      _items.clear();
    } else {
      _items.removeWhere((e) => e.service == service);
    }
  }
/// 🔁 BACKWARD COMPATIBILITY (IMPORTANT)
static int totalItems(String service) {
  return getTotalItems(service);
}

static int totalPrice(String service) {
  return getTotal(service);
}

}