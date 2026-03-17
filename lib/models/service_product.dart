class ServiceProduct {
  final String name;
  final int price;
  final String imagePath;

  final String? description;
  final String? category;

  final String? time;
  final int? discount; // in percentage
  final int? finalPrice;

  final String? slogan;

  final List<String>? includes;
  final List<String>? process;

  ServiceProduct({
    required this.name,
    required this.price,
    required this.imagePath,
    this.description,
    this.category,
    this.time,
    this.discount,
    this.finalPrice,
    this.slogan,
    this.includes,
    this.process,
  });

  /// ✅ Auto calculated final price (if not given)
  int get calculatedFinalPrice {
    if (finalPrice != null) return finalPrice!;
    if (discount != null) {
      return price - ((price * discount!) ~/ 100);
    }
    return price;
  }

  /// ✅ Discount label (for UI)
  String get discountLabel {
    if (discount == null || discount == 0) return '';
    return '$discount% OFF';
  }

  /// ✅ Time fallback
  String get serviceTime {
    return time ?? 'Standard Time';
  }

  /// ✅ Safe includes list
  List<String> get safeIncludes {
    return includes ?? [];
  }

  /// ✅ Safe process list
  List<String> get safeProcess {
    return process ?? [];
  }
}