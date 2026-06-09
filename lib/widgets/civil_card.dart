import 'package:flutter/material.dart';
import '../data/service_product.dart';
import '../models/cart.dart';

const kCivilCartKey = "Civil";

class CivilServiceCard extends StatelessWidget {
  final ServiceProduct service;
  final String? displayPrice;
  final VoidCallback onAddCart;
  final VoidCallback? onTap;

  const CivilServiceCard({
    super.key,
    required this.service,
    required this.onAddCart,
    this.onTap,
    this.displayPrice,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cartCount = Cart.getItemCount(service.id, kCivilCartKey);
    final bool inCart = cartCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: width * 0.40,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 5),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              /// IMAGE
              Positioned.fill(
                child: Image.asset(service.imagePath, fit: BoxFit.cover),
              ),

              /// GRADIENT OVERLAY
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              /// VIEW DETAILS BUTTON — top left
              Positioned(
                left: 10,
                top: 10,
                child: InkWell(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "View Details",
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),

              /// PRICE CHIP — top right
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayPrice ?? "₹${service.price}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              /// SERVICE NAME — bottom left
              Positioned(
                left: 12,
                bottom: 14,
                right: 90,
                child: Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              /// BOOK / SELECT BUTTON — bottom right
              Positioned(
                right: 10,
                bottom: 10,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: onAddCart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          /// Green when already in cart, red otherwise
                          color: inCart ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (inCart) ...[
                              const Icon(Icons.check,
                                  color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              service.category == "Renovation"
                                  ? "SELECT"
                                  : inCart
                                      ? "BOOKED"
                                      : "BOOK",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// Cart count badge
                    if (cartCount > 0)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cartCount > 9 ? "9+" : "$cartCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}