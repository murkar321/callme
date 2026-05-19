import 'package:flutter/material.dart';
import 'package:callme/bookings/resort_booking.dart';

import '../data/resorts_data.dart';

class ResortDetailPage extends StatelessWidget {

  final Resort resort;

  const ResortDetailPage({
    super.key,
    required this.resort,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F6FA),

      /// ================= APP BAR =================
      appBar: AppBar(

        elevation: 0,

        centerTitle: true,

        backgroundColor: Colors.blue,

        title: Text(
          resort.name,

          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      /// ================= BODY =================
      body: SingleChildScrollView(

        padding: const EdgeInsets.only(
          bottom: 110,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            /// ================= IMAGE =================
            Stack(
              children: [

                SizedBox(
                  height: 280,
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
                          size: 60,
                          color: Colors.grey.shade400,
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

                        end: Alignment.topCenter,

                        colors: [
                          Colors.black
                              .withOpacity(0.5),

                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// DISCOUNT BADGE
                if (resort.discount > 0)

                  Positioned(
                    top: 18,
                    right: 18,

                    child: Container(

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
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
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                /// TITLE
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 20,

                  child: Text(
                    resort.name,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight:
                          FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),

            /// ================= CONTENT =================
            Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  /// ================= LOCATION + RATING =================
                  Container(

                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.04),

                          blurRadius: 8,
                        ),
                      ],
                    ),

                    child: Row(
                      children: [

                        /// LOCATION
                        Expanded(
                          child: Row(
                            children: [

                              const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 20,
                              ),

                              const SizedBox(width: 6),

                              Expanded(
                                child: Text(
                                  resort.city,

                                  maxLines: 1,

                                  overflow:
                                      TextOverflow
                                          .ellipsis,

                                  style:
                                      const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight
                                            .w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// RATING
                        Row(
                          children: [

                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 20,
                            ),

                            const SizedBox(width: 4),

                            Text(
                              resort.rating
                                  .toString(),

                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// ================= PRICE =================
                  Container(

                    width: double.infinity,

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(22),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.05),

                          blurRadius: 10,
                        ),
                      ],
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,

                      children: [

                        Text(
                          "₹${resort.price}",

                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(width: 8),

                        const Padding(
                          padding:
                              EdgeInsets.only(
                            bottom: 6,
                          ),

                          child: Text(
                            "/ night",

                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                        ),

                        const Spacer(),

                        if (resort.originalPrice >
                            resort.price)

                          Text(
                            "₹${resort.originalPrice}",

                            style: TextStyle(
                              color:
                                  Colors.grey.shade500,

                              fontSize: 18,

                              decoration:
                                  TextDecoration
                                      .lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// ================= FACILITIES =================
                  _sectionTitle("Facilities"),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,

                    children:
                        resort.facilities.map((f) {

                      return Container(

                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,

                          borderRadius:
                              BorderRadius.circular(
                            30,
                          ),
                        ),

                        child: Text(
                          f,

                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  /// ================= DESCRIPTION =================
                  _sectionTitle("Description"),

                  const SizedBox(height: 12),

                  Container(

                    width: double.infinity,

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(22),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.04),

                          blurRadius: 8,
                        ),
                      ],
                    ),

                    child: Text(
                      resort.description,

                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// ================= BOOK BUTTON =================
      bottomNavigationBar: SafeArea(

        child: Container(

          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            16,
          ),

          decoration: BoxDecoration(
            color: Colors.white,

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.08),

                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],

            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),

          child: SizedBox(

            height: 56,

            child: ElevatedButton(

              onPressed: () {

                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        ResortBookingPage(
                      resort: resort,
                    ),
                  ),
                );
              },

              style: ElevatedButton.styleFrom(
                elevation: 0,

                backgroundColor: Colors.green,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                ),
              ),

              child: const Text(
                "Book Now",

                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= SECTION TITLE =================
  Widget _sectionTitle(String title) {

    return Text(
      title,

      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}