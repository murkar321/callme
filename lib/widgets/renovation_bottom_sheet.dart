import 'package:flutter/material.dart';
import 'package:callme/screens/civil_book_page.dart';
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
  State<RenovationBottomSheet> createState() => _RenovationBottomSheetState();
}

class _RenovationBottomSheetState extends State<RenovationBottomSheet> {
  List<RenovationOption> selected = [];

  int get total {
    int sum = 0;

    for (var item in selected) {
      sum += int.parse(
        item.price.replaceAll(RegExp(r'[^0-9]'), ''),
      );
    }

    return sum;
  }

  String getPriceRange() {
    switch (widget.packageId) {
      case "basic":
        return "₹1200 - ₹2800 sq.ft (approx)";
      case "standard":
        return "₹2800 - ₹4500 sq.ft (approx)";
      case "premium":
        return "₹4500+ sq.ft (approx)";
      default:
        return "";
    }
  }

  String getWorkerImage() {
    switch (widget.packageId) {
      case "basic":
        return "assets/worker.jfif";
      case "standard":
        return "assets/worker.jfif";
      case "premium":
        return "assets/worker.jfif";
      default:
        return "assets/worker.jfif";
    }
  }

  String getBestFor() {
    switch (widget.packageId) {
      case "basic":
        return "Best for: Low budget";
      case "standard":
        return "Best for: Medium budget";
      case "premium":
        return "Best for: Luxury homes";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = renovationOptions[widget.packageId] ?? [];

    final width = MediaQuery.of(context).size.width;

    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        height: height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.packageName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// CARD
            Expanded(
              child: SingleChildScrollView(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 50),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.packageName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            getPriceRange(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// OPTIONS
                          Column(
                            children: options.map((opt) {
                              final isSelected = selected.contains(opt);

                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(opt.name),
                                subtitle: Text(opt.price),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
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

                          const SizedBox(height: 10),

                          Text(
                            getBestFor(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    /// WORKER IMAGE
                    Positioned(
                      right: 0,
                      top: 30,
                      child: Container(
                        height: width * 0.42,
                        width: width * 0.26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            getWorkerImage(),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// TOTAL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "₹$total",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// APPOINT
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CivilBookingPage(
                              serviceName: widget.packageName,
                            ),
                          ),
                        );
                      },
                child: const Text("Appoint me"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
