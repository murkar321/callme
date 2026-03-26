import 'package:flutter/material.dart';
import '../data/resorts_data.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';

class ResortBookingPopup extends StatefulWidget {
  final Resort resort;

  const ResortBookingPopup({
    super.key,
    required this.resort,
  });

  @override
  State<ResortBookingPopup> createState() =>
      _ResortBookingPopupState();
}

class _ResortBookingPopupState
    extends State<ResortBookingPopup> {

  int adult = 1;
  int child = 0;

  int get totalPrice {
    return (widget.resort.price * adult) +
        ((widget.resort.price ~/ 2) * child);
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),

      title: Text(
        widget.resort.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// ADULT
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [

              const Text(
                "Adults",
                style: TextStyle(fontSize: 16),
              ),

              Row(
                children: [

                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (adult > 1) {
                        setState(() => adult--);
                      }
                    },
                  ),

                  Text(
                    adult.toString(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),

                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() => adult++);
                    },
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 10),

          /// CHILD
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [

              const Text(
                "Children",
                style: TextStyle(fontSize: 16),
              ),

              Row(
                children: [

                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (child > 0) {
                        setState(() => child--);
                      }
                    },
                  ),

                  Text(
                    child.toString(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),

                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() => child++);
                    },
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 20),

          /// TOTAL PRICE
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [

                const Text(
                  "Total Price",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  "₹$totalPrice",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      actions: [

        /// CANCEL
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),

        /// PROCEED
        ElevatedButton(
          onPressed: () {

            /// ADD TO CART
            Cart.addResortBooking(
              id: widget.resort.name,
              name: widget.resort.name,
              price: widget.resort.price,
              adults: adult,
              children: child,
              image: widget.resort.image,
            );

            Navigator.pop(context);

            /// GO TO CART PAGE
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const CartPage(
                      serviceName: "Resort",
                      cart: [],
                    ),
              ),
            );
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),

          child: const Text(
            "Proceed to Cart",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}