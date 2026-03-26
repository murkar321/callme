import 'package:flutter/material.dart';
import '../data/resorts_data.dart';
import '../models/resort_detail_page.dart';
import '../widgets/rbooking_popup.dart';

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
          horizontal: 12, vertical: 8),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.grey.shade300,
            offset: const Offset(0, 3),
          )
        ],
      ),

      child: Row(
        children: [

          /// LEFT PANEL - CIRCULAR IMAGE
          CircleAvatar(
            radius: 45,
            backgroundImage:
                AssetImage(resort.image),
          ),

          const SizedBox(width: 15),

          /// RIGHT PANEL
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                /// NAME
                Text(
                  resort.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                /// CITY BADGE
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    resort.city,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                /// FACILITIES
                Wrap(
                  spacing: 5,
                  children: resort.facilities
                      .take(2)
                      .map(
                        (f) => Chip(
                          label: Text(
                            f,
                            style:
                                const TextStyle(
                              fontSize: 10,
                            ),
                          ),
                          backgroundColor:
                              Colors.grey.shade200,
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 8),

                /// PRICE ROW
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [

                    /// PRICE
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [

                        Text(
                          "₹${resort.price}",
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                Colors.green,
                          ),
                        ),

                        Text(
                          "per person",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    /// DISCOUNT BADGE
                    if (resort.discount > 0)
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .red.shade50,
                          borderRadius:
                              BorderRadius
                                  .circular(8),
                        ),
                        child: Text(
                          "${resort.discount}% OFF",
                          style:
                              const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                /// BUTTONS
                Row(
                  children: [

                    /// VIEW DETAILS
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ResortDetailPage(
                                      resort:
                                          resort),
                            ),
                          );
                        },
                        child:
                            const Text(
                                "View Details"),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// BOOK NOW
                    Expanded(
                      child: ElevatedButton(
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors.green,
                        ),
                        onPressed: () {
                          showDialog(
                            context:
                                context,
                            builder: (_) =>
                                ResortBookingPopup(
                                    resort:
                                        resort),
                          );
                        },
                        child:
                            const Text(
                          "Book Now",
                          style: TextStyle(
                              color:
                                  Colors
                                      .white),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}