class CleaningService {
  final String name;
  final String image;
  final String description;

  final List<String> includes;
  final List<String> excludes;
  final List<String> steps;

  final String tools;
  final String time;

  final int price;
  final int discount;
  final int finalPrice;

  final String warranty;

  CleaningService({
    required this.name,
    required this.image,
    required this.description,
    required this.includes,
    required this.excludes,
    required this.steps,
    required this.tools,
    required this.time,
    required this.price,
    required this.discount,
    required this.finalPrice,
    required this.warranty,
  });
}
