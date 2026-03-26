import 'package:flutter/material.dart';
import '../models/service_product.dart';
import '../models/cart.dart';
import '../screens/water_detail_page.dart';

class WaterServiceCard extends StatelessWidget {
  final ServiceProduct product;
  final VoidCallback onUpdate;

  const WaterServiceCard({
    super.key,
    required this.product,
    required this.onUpdate,
  });

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
    Cart.getQuantity(product.id, "Water");

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
          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              product.imagePath,
              height: 90,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 6),

          /// NAME
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          /// DESCRIPTION
          if (product.description != null)
            Text(
              product.description!,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 4),

          /// PRICE
          Text(
            "₹${product.calculatedFinalPrice}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),

          const SizedBox(height: 4),

          /// BUTTONS (LOGIC SAME)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WaterDetailPage(product: product),
                      ),
                    );
                  },
                  child: const Text("Details", style: TextStyle(fontSize: 10)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Cart.add(cartItem, service: "Water");
                    onUpdate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: const Text("Add", style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
