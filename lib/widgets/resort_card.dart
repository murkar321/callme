import 'package:flutter/material.dart';

import '../data/resorts_data.dart';
import '../models/resort_detail_page.dart';
import '../bookings/resort_booking.dart';

class ResortCard extends StatelessWidget {

  final Resort resort;

  const ResortCard({
    super.key,
    required this.resort,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      margin: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 10,
      ),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          /// ================= IMAGE =================
          ClipRRect(

            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(20),
            ),

            child: Stack(
              children: [

                /// IMAGE
                SizedBox(
                  height: 190,
                  width: double.infinity,

                  child: Image.asset(
                    resort.image,

                    fit: BoxFit.cover,

                    errorBuilder:
                        (_, __, ___) {

                      return Container(
                        color: Colors.grey.shade200,

                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                ),

                /// DARK OVERLAY
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:
                            Alignment.bottomCenter,

                        end: Alignment.topCenter,

                        colors: [
                          Colors.black
                              .withOpacity(0.35),

                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// DISCOUNT BADGE
                if (resort.discount > 0)

                  Positioned(
                    top: 14,
                    left: 14,

                    child: Container(

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.red,

                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),

                      child: Text(
                        "${resort.discount}% OFF",

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          /// ================= CONTENT =================
          Padding(
            padding: const EdgeInsets.all(14),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                /// NAME
                Text(
                  resort.name,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 8),

                /// LOCATION
                Row(
                  children: [

                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.red,
                    ),

                    const SizedBox(width: 4),

                    Expanded(
                      child: Text(
                        resort.city,

                        maxLines: 1,

                        overflow:
                            TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// PRICE
                Text(
                  "₹${resort.price} / night",

                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 14),

                /// ================= BUTTONS =================
                Row(
                  children: [

                    /// VIEW BUTTON
                    Expanded(
                      child: SizedBox(

                        height: 45,

                        child: OutlinedButton(

                          onPressed: () {

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (context) {

                                  return ResortDetailPage(
                                    resort: resort,
                                  );
                                },
                              ),
                            );
                          },

                          style:
                              OutlinedButton.styleFrom(
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(14),
                            ),

                            side: BorderSide(
                              color:
                                  Colors.grey.shade400,
                            ),
                          ),

                          child: const Text(
                            "View",

                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// BOOK BUTTON
                    Expanded(
                      child: SizedBox(

                        height: 45,

                        child: ElevatedButton(

                          onPressed: () {

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (context) {

                                  return ResortBookingPage(
                                    resort: resort,
                                  );
                                },
                              ),
                            );
                          },

                          style:
                              ElevatedButton.styleFrom(
                            elevation: 0,

                            backgroundColor:
                                Colors.blue,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(14),
                            ),
                          ),

                          child: const Text(
                            "Book",

                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}