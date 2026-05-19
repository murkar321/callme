import 'package:flutter/material.dart';

import '../data/salon_data.dart';
import '../models/cart.dart';
import '../screens/salon_detail_page.dart';
import '../models/cart_page.dart';

class SalonServiceCard extends StatefulWidget {
  final SalonService service;
  final VoidCallback? onUpdate;

  const SalonServiceCard({
    super.key,
    required this.service,
    this.onUpdate,
  });

  @override
  State<SalonServiceCard> createState() => _SalonServiceCardState();
}

class _SalonServiceCardState extends State<SalonServiceCard> {

  /// ================= KEY LOGIC =================
  String _key(String visitType) => "${widget.service.id}_$visitType";

  int _getQty(String visitType) =>
      Cart.getQuantity(_key(visitType), "Salon");

  void _add(String visitType) {
    Cart.addSalon(
      id: _key(visitType),
      name: widget.service.name,
      price: widget.service.finalPrice,
      category: widget.service.category,
      visitType: visitType,
      image: widget.service.image,
    );

    setState(() {});
    widget.onUpdate?.call();
  }

  void _remove(String visitType) {
    Cart.removeById(_key(visitType), "Salon");

    setState(() {});
    widget.onUpdate?.call();
  }

  /// ================= UI HELPERS =================
  String getAutoBadge() {
    if (widget.service.discount >= 25) return "Best Deal";
    if (widget.service.price <= 300) return "Budget";
    return "Popular";
  }

  double getAutoRating() {
    return 4.2 + (widget.service.id % 5) * 0.1;
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

          /// IMAGE
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.asset(
                  widget.service.image,
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

          /// CONTENT
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  widget.service.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.service.slogan,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(getAutoRating().toStringAsFixed(1)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.service.time,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Text("₹${widget.service.finalPrice}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Text("₹${widget.service.price}",
                        style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey)),
                  ],
                ),

                const SizedBox(height: 12),

                /// BUTTON AREA
                if (totalQty == 0)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SalonDetailPage(service: widget.service),
                              ),
                            );
                          },
                          child: const Text("View"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showPopup(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAE91BA)),
                          child: const Text("Book"),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _qtyRow("Home", homeQty),
                      _qtyRow("Salon", salonQty),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
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
                        child: Text("View Cart ($totalQty)"),
                      )
                    ],
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  /// ================= QTY ROW =================
  Widget _qtyRow(String type, int qty) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(type),
        qty == 0
            ? TextButton(
                onPressed: () => _add(type),
                child: const Text("Add"),
              )
            : Row(
                children: [
                  IconButton(
                    onPressed: () => _remove(type),
                    icon: const Icon(Icons.remove),
                  ),
                  Text("$qty"),
                  IconButton(
                    onPressed: () => _add(type),
                    icon: const Icon(Icons.add),
                  ),
                ],
              )
      ],
    );
  }

  /// ================= 🔥 PREMIUM POPUP =================
  void _showPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// DRAG HANDLE
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const Text(
                "Choose Appointment Type",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              /// HOME CARD
              _optionCard(
                icon: Icons.home,
                title: "Home Appointment",
                subtitle: "Service at your doorstep",
                color: Colors.purple,
                onTap: () {
                  _add("Home");
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 12),

              /// SALON CARD
              _optionCard(
                icon: Icons.store,
                title: "Salon Visit",
                subtitle: "Visit nearest salon",
                color: Colors.green,
                onTap: () {
                  _add("Salon");
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// OPTION CARD UI
  Widget _optionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14)
          ],
        ),
      ),
    );
  }
}