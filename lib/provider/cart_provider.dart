import 'package:flutter/material.dart';
import '../models/service_product.dart';

class CartProvider extends ChangeNotifier {
  final List<ServiceProduct> _items = [];

  List<ServiceProduct> get items => _items;

  int get count => _items.length;

  bool isAdded(ServiceProduct product) {
    return _items.contains(product);
  }

  void toggle(ServiceProduct product) {
    if (_items.contains(product)) {
      _items.remove(product);
    } else {
      _items.add(product);
    }
    notifyListeners();
  }
}
