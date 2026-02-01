class ServiceProduct {
  final String name;
  final int price;
  final String imagePath;
  final String? description; // <--- new optional field

  ServiceProduct({
    required this.name,
    required this.price,
    required this.imagePath,
    this.description,
  });
}
