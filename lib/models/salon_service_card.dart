import 'package:flutter/material.dart';
import '../data/salon_data.dart';
import '../models/cart.dart';
import '../screens/salon_detail_page.dart';
import '../models/cart_page.dart';

class SalonServiceCard extends StatelessWidget {
  final SalonService service;
  final VoidCallback? onUpdate;

  const SalonServiceCard({
    super.key,
    required this.service,
    this.onUpdate,
  });

  /// =========================
  /// EXISTING LOGIC (UNCHANGED)
  /// =========================
  String _key(String visitType) {
    return "${service.id}_$visitType";
  }

  int _getQty(String visitType) {
    return Cart.getQuantity(_key(visitType), "Salon");
  }

  /// =========================
  /// AUTO UI HELPERS (NEW)
  /// =========================
  String getAutoBadge() {
    if (service.discount >= 25) return "Best Deal";
    if (service.price <= 300) return "Budget";
    return "Popular";
  }

  double getAutoRating() {
    return 4.2 + (service.id % 5) * 0.1;
  }

  String getDiscountLabel() {
    if (service.discount > 0) {
      return "${service.discount}% OFF";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final homeQty = _getQty("Home");
    final salonQty = _getQty("Salon");
    final totalQty = homeQty + salonQty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// =========================
          /// IMAGE + BADGE
          /// =========================
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Image.asset(
                  service.image,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    getAutoBadge(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// =========================
          /// CONTENT
          /// =========================
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// NAME
                Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 5),

                /// SLOGAN
                Text(
                  service.slogan,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 6),

                /// ⭐ RATING + ⏱ TIME
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      getAutoRating().toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        service.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// 💸 PRICE + DISCOUNT
                Row(
                  children: [
                    Text(
                      "₹${service.finalPrice}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "₹${service.price}",
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),

                    if (service.discount > 0)
                      Text(
                        getDiscountLabel(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                /// =========================
                /// BUTTONS (RESPONSIVE SAFE)
                /// =========================
                Row(
                  children: [

                    /// VIEW BUTTON
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SalonDetailPage(service: service),
                              ),
                            );
                          },
                          child: const FittedBox(
                            child: Text("View"),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// BOOK BUTTON
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFAE91BA),
                          ),
                          onPressed: () => _showPopup(context),
                          child: FittedBox(
                            child: Text(
                              totalQty == 0
                                  ? "Book"
                                  : "Added ($totalQty)",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// =========================
  /// POPUP (UNCHANGED)
  /// =========================
  void _showPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              const Center(
                child: Text(
                  "Choose Appointment Type",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.home),
                title: const Text("Home Appointment"),
                onTap: () {
                  Cart.addSalon(
                    id: _key("Home"),
                    name: service.name,
                    price: service.finalPrice,
                    category: service.category,
                    visitType: "Home",
                    image: service.image,
                  );
                  Navigator.pop(context);
                  onUpdate?.call();
                },
              ),

              ListTile(
                leading: const Icon(Icons.store),
                title: const Text("Salon Appointment"),
                onTap: () {
                  Cart.addSalon(
                    id: _key("Salon"),
                    name: service.name,
                    price: service.finalPrice,
                    category: service.category,
                    visitType: "Salon",
                    image: service.image,
                  );
                  Navigator.pop(context);
                  onUpdate?.call();
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text("View Cart"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartPage(
                        service: "Salon",
                        serviceName: "Salon",
                        cart: [],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}