import 'package:callme/bookings/hotel_booking_page.dart';
import 'package:callme/models/hotel_detail_page.dart';
import 'package:flutter/material.dart';
import '../data/hotel_data.dart';

class HotelCard extends StatelessWidget {
  final HotelData hotel;

  const HotelCard({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final discountedPrice = hotel.price - (hotel.price * hotel.discount ~/ 100);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor      = isDark ? const Color(0xFF1B1922) : Colors.white;
    final textPrimary    = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary  = isDark ? Colors.white70 : Colors.grey.shade800;
    final textMuted      = isDark ? Colors.white54 : Colors.grey.shade600;
    final chipBg         = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100;
    final chipText       = isDark ? Colors.white70 : Colors.grey.shade800;
    final outlineBorder  = isDark ? Colors.white24 : Colors.grey.shade400;
    final ratingBg       = isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ================= IMAGE =================
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [

                /// IMAGE
                SizedBox(
                  height: 230,
                  width: double.infinity,
                  child: Image.asset(
                    hotel.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image, size: 60, color: Colors.grey.shade400),
                    ),
                  ),
                ),

                /// GRADIENT OVERLAY
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                /// DISCOUNT BADGE
                if (hotel.discount > 0)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        "${hotel.discount}% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                /// CITY BADGE
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      hotel.city.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                /// HOTEL NAME OVERLAY
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,
                  child: Text(
                    hotel.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: width < 360 ? 20 : 24,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// LOCATION ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.location_on, color: Colors.red, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hotel.location,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                /// PRICE + RATING
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    /// PRICE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Price Per Night",
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹$discountedPrice",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                              ),
                            ),
                            if (hotel.discount > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                "₹${hotel.price}",
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    /// RATING
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: ratingBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            hotel.rating.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                /// AMENITIES
                if (hotel.facilities.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hotel.facilities.take(4).map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          amenity,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: chipText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
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
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HotelDetailPage(hotel: hotel),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: outlineBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "View Details",
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
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
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HotelBookingPage(
                                hotel: hotel,
                                products: [],
                                providerId: '<PROVIDER_ID>',
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 235, 65, 65),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Book Now",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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