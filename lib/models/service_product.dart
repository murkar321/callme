class ServiceProduct {
  final String name;
  final int price;
  final String imagePath;

  final String? description;
  final String? category;

  final String? time;
  final int? discount;
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
}