
import 'package:flutter/material.dart';
import '../data/resorts_data.dart';


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

class _ResortBookingPopupState extends State<ResortBookingPopup> {

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

      title: Text(widget.resort.name),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// ADULT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Adults"),

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
                  Text(adult.toString()),
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

          /// CHILD
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Children"),

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
                  Text(child.toString()),
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

          /// TOTAL
          Text("Total: ₹$totalPrice"),
        ],
      ),

      actions: [

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: () {

            /// ✅ RETURN DATA TO CARD
            Navigator.pop(context, {
              Navigator.pop(context, {
  "adults": adult,
  "children": child,
  "price": widget.resort.price, // ✅ ADD THIS
})
            });
          },
          child: const Text("Continue"),
        ),
      ],
    );
  }
}