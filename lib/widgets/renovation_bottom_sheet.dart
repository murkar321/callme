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
      sum += int.parse(item.price.replaceAll(RegExp(r'[^0-9]'), ''));
    }
    return sum;
  }

  String getPriceRange() {
    switch (widget.packageId) {
      case "basic":
        return "₹1200 - ₹2800 / sq.ft (approx)";
      case "standard":
        return "₹2800 - ₹4500 / sq.ft (approx)";
      case "premium":
        return "₹4500+ / sq.ft (approx)";
      default:
        return "";
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
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: width * 0.9,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xfff3f3f3),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.packageName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff7b1e1e),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              getPriceRange(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...options.map((opt) {
                              final isSelected = selected.contains(opt);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (_) {
                                          setState(() {
                                            if (isSelected) {
                                              selected.remove(opt);
                                            } else {
                                              selected.add(opt);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          opt.name,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            Text(
                              getBestFor(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: SizedBox(
                                width: 140,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff8b1e1e),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
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
                                  child: const Text(
                                    "Appoint me",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Positioned(
                        right: 18,
                        top: 70,
                        child: SizedBox(
                          height: 220,
                          child: Image.asset(
                            'assets/worker.jfif',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "₹$total",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
