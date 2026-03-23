import 'package:flutter/material.dart';
import '../models/service_product.dart';
import '../models/cart.dart';

class WaterServiceCard extends StatelessWidget {
  final ServiceProduct product;
  final VoidCallback onUpdate;

  const WaterServiceCard({
    super.key,
    required this.product,
    required this.onUpdate,
  });

  /// 🔁 Convert ServiceProduct → CartItem
  CartItem get cartItem => CartItem(
        id: product.id,
        name: product.name,
        price: product.calculatedFinalPrice,
        service: "Water",
        category: "Water",
        image: product.imagePath,
      );

  @override
  Widget build(BuildContext context) {
    /// ✅ Get Quantity from Cart
    int qty = Cart.getQuantity(product.id, "Water");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            color: Colors.grey.shade300,
          )
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔷 IMAGE
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  product.imagePath,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              /// 🔴 DISCOUNT
              if (product.discount != null && product.discount! > 0)
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${product.discount}% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          /// 🔷 NAME
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          /// 🔷 DESCRIPTION
          if (product.description != null)
            Text(
              product.description!,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const Spacer(),

          /// 🔷 PRICE
          Row(
            children: [
              Text(
                "₹${product.calculatedFinalPrice}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 178, 134, 186),
                ),
              ),
              const SizedBox(width: 6),
              if (product.discount != null && product.discount! > 0)
                Text(
                  "₹${product.price}",
                  style: const TextStyle(
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 5),

          /// 🔥 ADD / REMOVE
          qty == 0
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Cart.add(cartItem, service: "Water");
                      onUpdate();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 184, 109, 198),
                    ),
                    child: const Text("Add"),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// ➖ REMOVE
                    IconButton(
                      onPressed: () {
                        Cart.remove(cartItem);
                        onUpdate();
                      },
                      icon: const Icon(
                        Icons.remove_circle,
                        color: Colors.red,
                      ),
                    ),

                    /// 🔢 QTY
                    Text(
                      qty.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),

                    /// ➕ ADD
                    IconButton(
                      onPressed: () {
                        Cart.add(cartItem, service: "Water");
                        onUpdate();
                      },
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}