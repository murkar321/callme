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
    String? id, // ✅ CHANGED (optional now)
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
  }) : id = id == null || id.isEmpty
            ? _generateId(service, name) // ✅ AUTO GENERATE
            : id;

  /// 🔥 AUTO ID GENERATOR
  static String _generateId(String service, String name) {
    return "${service}_${name}"
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  int get calculatedFinalPrice {
    if (finalPrice != null) return finalPrice!;
    if (discount != null && discount! > 0 && discount! <= 100) {
      return price - ((price * discount!) ~/ 100);
    }
    return price;
  }

  String get discountLabel {
    if (discount == null || discount == 0) return '';
    return '$discount% OFF';
  }

  String get serviceTime => time ?? 'Standard Time';

  List<String> get safeIncludes => includes ?? [];
  List<String> get safeProcess => process ?? [];
  List<String> get safeSteps => steps ?? [];
  List<String> get safeExcludes => excludes ?? [];

  double get safeRating => rating ?? 0.0;

  String get formattedPrice => '₹$calculatedFinalPrice';

  /// 🔥 KEEP THIS (now safe because ID is unique)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceProduct &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
