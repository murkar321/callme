import 'package:callme/screens/civil_book_page.dart';
import 'package:flutter/material.dart';
import '../data/renovation_options.dart';


class RenovationBottomSheet extends StatefulWidget {
  final String packageId;
  final String packageName;

  const RenovationBottomSheet({
    super.key,
    required this.packageId,
    required this.packageName,
  });

  @override
  State<RenovationBottomSheet> createState() =>
      _RenovationBottomSheetState();
}

class _RenovationBottomSheetState extends State<RenovationBottomSheet> {
  List<RenovationOption> selected = [];

  int get total {
    int sum = 0;
    for (var item in selected) {
      sum += int.parse(item.price.replaceAll(RegExp(r'[^0-9]'), ''));
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final options = renovationOptions[widget.packageId] ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [

          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.packageName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
          ),

          const Divider(),

          /// LIST
          Expanded(
            child: ListView(
              children: options.map((opt) {
                final isSelected = selected.contains(opt);

                return CheckboxListTile(
                  value: isSelected,
                  title: Text(opt.name),
                  subtitle: Text(opt.price),
                  onChanged: (_) {
                    setState(() {
                      if (isSelected) {
                        selected.remove(opt);
                      } else {
                        selected.add(opt);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),

          /// TOTAL + BUTTON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("₹$total",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CivilBookingPage(
                                  serviceName:
                                      "${widget.packageName} (Custom)",
                                ),
                              ),
                            );
                          },
                    child: const Text("Proceed to Booking"),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}