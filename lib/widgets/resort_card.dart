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

    final width =
        MediaQuery.of(context).size.width;

    return Container(

      margin: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.06),

            blurRadius: 14,
            offset: const Offset(0, 5),
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
              top: Radius.circular(24),
            ),

            child: Stack(
              children: [

                /// IMAGE
                SizedBox(
                  height: 230,
                  width: double.infinity,

                  child: Image.asset(
                    resort.image,

                    fit: BoxFit.cover,

                    errorBuilder:
                        (_, __, ___) {

                      return Container(
                        color:
                            Colors.grey.shade200,

                        child: Icon(
                          Icons.image,
                          size: 60,
                          color: Colors
                              .grey.shade400,
                        ),
                      );
                    },
                  ),
                ),

                /// OVERLAY
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:
                            Alignment.bottomCenter,

                        end:
                            Alignment.topCenter,

                        colors: [
                          Colors.black
                              .withOpacity(0.55),

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
                        horizontal: 12,
                        vertical: 7,
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
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                /// LOCATION BADGE
                Positioned(
                  top: 14,
                  right: 14,

                  child: Container(

                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.blue,

                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),
                    ),

                    child: Text(
                      resort.city.toUpperCase(),

                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                /// RESORT NAME
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,

                  child: Text(
                    resort.name,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style: TextStyle(
                      color: Colors.white,

                      fontWeight:
                          FontWeight.bold,

                      fontSize:
                          width < 360 ? 20 : 24,

                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ================= DETAILS =================
          Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                /// LOCATION
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Padding(
                      padding:
                          EdgeInsets.only(
                        top: 2,
                      ),

                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        resort.location,

                        maxLines: 3,

                        overflow:
                            TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,

                          color:
                              Colors.grey.shade800,

                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                /// PRICE + RATING
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
                          "Price Per Person",

                          style: TextStyle(
                            color:
                                Colors.grey.shade600,

                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "₹${resort.price}",

                          style:
                              const TextStyle(
                            color: Colors.green,

                            fontWeight:
                                FontWeight.bold,

                            fontSize: 26,
                          ),
                        ),
                      ],
                    ),

                    /// RATING
                    Container(

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),

                      decoration: BoxDecoration(
                        color:
                            Colors.orange.shade50,

                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),

                      child: Row(
                        children: [

                          const Icon(
                            Icons.star_rounded,
                            color: Colors.orange,
                            size: 18,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            resort.rating
                                .toString(),

                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                /// FACILITIES
                Wrap(

                  spacing: 8,
                  runSpacing: 8,

                  children:
                      resort.facilities.take(4).map(
                    (facility) {

                      return Container(

                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color:
                              Colors.grey.shade100,

                          borderRadius:
                              BorderRadius.circular(
                            30,
                          ),
                        ),

                        child: Text(
                          facility,

                          style: TextStyle(
                            fontSize: 11.5,
                            color:
                                Colors.grey.shade800,

                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),

                const SizedBox(height: 22),

                /// ================= BUTTONS =================
                Row(
                  children: [

                    /// VIEW DETAILS
                    Expanded(
                      child: SizedBox(
                        height: 52,

                        child: OutlinedButton(

                          onPressed: () {

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder:
                                    (context) {

                                  return ResortDetailPage(
                                    resort: resort,
                                  );
                                },
                              ),
                            );
                          },

                          style:
                              OutlinedButton.styleFrom(
                            side: BorderSide(
                              color:
                                  Colors.grey.shade400,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(14),
                            ),
                          ),

                          child: const Text(
                            "View Details",

                            style: TextStyle(
                              color: Colors.black,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// BOOK NOW
                    Expanded(
                      child: SizedBox(
                        height: 52,

                        child: ElevatedButton(

                          onPressed: () {

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder:
                                    (context) {

                                  return ResortBookingPage(
                                    resort: resort,
                                  );
                                },
                              ),
                            );
                          },

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blue,

                            elevation: 0,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(14),
                            ),
                          ),

                          child: const Text(
                            "Book Now",

                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
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