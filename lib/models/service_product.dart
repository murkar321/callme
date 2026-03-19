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
  final double? rating; // ✅ made optional

  final List<String>? includes;
  final List<String>? excludes;
  final List<String>? process;
  final List<String>? steps;
  final String? tools;

  ServiceProduct({
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
  });

  /// ✅ Auto calculated final price (safe)
  int get calculatedFinalPrice {
    if (finalPrice != null) return finalPrice!;
    if (discount != null && discount! > 0 && discount! <= 100) {
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

  /// ✅ Safe rating
  double get safeRating {
    return rating ?? 0.0;
  }

  /// ✅ UI formatted price
  String get formattedPrice {
    return '₹$calculatedFinalPrice';
  }
}
