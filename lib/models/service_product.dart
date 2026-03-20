class ServiceProduct {
  final String id;
  final String service;
  final String name;
  final int price;
  final String imagePath;

  final String? description;
  final String? category;
  final String? time;
  final int? discount;
  final int? finalPrice;
  final String? slogan;
  final double? rating;

  final List<String>? includes;
  final List<String>? excludes;
  final List<String>? process;
  final List<String>? steps;
  final String? tools;

  ServiceProduct({
    String? id,
    required this.service,
    required this.name,
    required this.price,
    required this.imagePath,
    this.rating,
    this.description,
    this.category,
    this.time,
    this.discount,
    this.finalPrice,
    this.slogan,
    this.includes,
    this.process,
    this.steps,
    this.tools,
    this.excludes,
  }) : id = (id == null || id.trim().isEmpty)
            ? _generateId(service, name)
            : id.trim();

  /// 🔥 AUTO ID GENERATOR (SAFE)
  static String _generateId(String service, String name) {
    return "${service.trim()}_${name.trim()}"
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// ✅ FINAL PRICE (MAIN LOGIC)
  int get calculatedFinalPrice {
    if (finalPrice != null && finalPrice! > 0) return finalPrice!;
    if (discount != null && discount! > 0 && discount! <= 100) {
      return price - ((price * discount!) ~/ 100);
    }
    return price;
  }

  /// ✅ ORIGINAL PRICE (FOR STRIKE UI)
  int get originalPrice {
    if (discount != null && discount! > 0) return price;
    return price;
  }

  /// ✅ DISCOUNT LABEL
  String get discountLabel {
    if (discount == null || discount == 0) return '';
    return '$discount% OFF';
  }

  /// ✅ SAFE VALUES (NO CRASH UI)
  String get serviceTime => time ?? 'Standard Time';
  double get safeRating => rating ?? 4.5;

  List<String> get safeIncludes => includes ?? [];
  List<String> get safeProcess => process ?? [];
  List<String> get safeSteps => steps ?? [];
  List<String> get safeExcludes => excludes ?? [];

  /// ✅ FORMATTED PRICE
  String get formattedPrice => '₹$calculatedFinalPrice';

  /// ✅ EQUALITY (IMPORTANT FOR CART)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceProduct &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
