import '../models/service_product.dart';

class Cart {
  static List<ServiceProduct> items = [];

  // product -> quantity
  static Map<ServiceProduct, int> quantities = {};
}
