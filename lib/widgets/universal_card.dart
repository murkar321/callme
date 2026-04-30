import 'package:flutter/material.dart';

enum ServiceActionType {
  normal,
  quantity,
}

class UniversalServiceCard extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final double? rating;

  final int price;
  final Color primaryColor;

  final ServiceActionType actionType;
  final int quantity;

  final VoidCallback onView;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  const UniversalServiceCard({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.primaryColor,
    required this.onView,
    required this.onPrimaryAction,
    this.rating,
    this.actionType = ServiceActionType.normal,
    this.quantity = 0,
    this.onIncrease,
    this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// IMAGE
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              image,
              height: width * 0.42,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: width * 0.42,
                color: Colors.grey[200],
                child: const Icon(Icons.image),
              ),
            ),
          ),

          /// CONTENT
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),

                const SizedBox(height: 4),

                Text(description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),

                const SizedBox(height: 6),

                Row(
                  children: [
                    if (rating != null) ...[
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(rating!.toStringAsFixed(1)),
                    ],
                    const Spacer(),
                    Text("₹$price",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onView,
                        child: const Text("View"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildAction()),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAction() {
    if (actionType == ServiceActionType.quantity) {
      return quantity == 0
          ? ElevatedButton(
              onPressed: onIncrease,
              child: const Text("ADD"),
            )
          : Container(
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(onPressed: onDecrease, icon: const Icon(Icons.remove)),
                  Text(quantity.toString()),
                  IconButton(onPressed: onIncrease, icon: const Icon(Icons.add)),
                ],
              ),
            );
    }

    return ElevatedButton(
      onPressed: onPrimaryAction,
      child: const Text("ADD"),
    );
  }
}