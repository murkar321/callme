import 'package:flutter/material.dart';
import 'booking_page.dart';
import '../models/cleaning_service.dart';

class CleaningServiceDetailPage
    extends StatefulWidget {
  final CleaningService product;
  final String serviceName;

  const CleaningServiceDetailPage({
    super.key,
    required this.product,
    required this.serviceName,
  });

  @override
  State<
          CleaningServiceDetailPage>
      createState() =>
          _CleaningServiceDetailPageState();
}

class _CleaningServiceDetailPageState
    extends State<
        CleaningServiceDetailPage> {
  bool isNavigating = false;

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(),
          ),
          ElevatedButton(
            onPressed:
                isNavigating
                    ? null
                    : () async {
                        setState(() {
                          isNavigating =
                              true;
                        });

                        await Navigator
                            .push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingPage(
                              serviceName: widget
                                  .serviceName,
                            ),
                          ),
                        );

                        if (mounted) {
                          setState(() {
                            isNavigating =
                                false;
                          });
                        }
                      },
            child: Text(
              "Book Now • ₹${widget.product.finalPrice}",
            ),
          )
        ],
      ),
    );
  }
}