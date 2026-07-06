import 'package:flutter/material.dart';
import 'package:callme/bookings/resort_booking.dart';
import '../data/resorts_data.dart';

class ResortDetailPage extends StatefulWidget {
  final Resort resort;

  const ResortDetailPage({
    super.key,
    required this.resort,
  });

  @override
  State<ResortDetailPage> createState() => _ResortDetailPageState();
}

class _ResortDetailPageState extends State<ResortDetailPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  List<Map<String, String>> get _galleryImages => widget.resort.images;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resort = widget.resort;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

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

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ================= IMAGE CAROUSEL =================
            Stack(
              children: [

                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _galleryImages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentImageIndex = index),
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [

                          Image.asset(
                            _galleryImages[index]['path']!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image,
                                  size: 60, color: Colors.grey.shade400),
                            ),
                          ),

                          Container(
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

                          Positioned(
                            left: 16,
                            bottom: 18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _galleryImages[index]['label']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                /// DISCOUNT BADGE
                if (resort.discount > 0)
                  Positioned(
                    top: 18,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        "${resort.discount}% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                /// DOT INDICATORS
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _galleryImages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentImageIndex == index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentImageIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

                /// LEFT ARROW
                if (_currentImageIndex > 0)
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_left,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),

                /// RIGHT ARROW
                if (_currentImageIndex < _galleryImages.length - 1)
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chevron_right,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            /// ================= THUMBNAIL STRIP =================
            Container(
              height: 72,
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _galleryImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _currentImageIndex == index;
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          _galleryImages[index]['path']!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.image,
                                size: 24, color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// ================= CONTENT =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// ================= TAGLINE =================
                  // ✅ NEW — the one-line distinguisher shown right under the gallery
                  Text(
                    resort.tagline,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  /// ================= LOCATION + RATING =================
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      resort.location,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  resort.rating.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // ✅ NEW — distance/access line, differs per resort
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.directions,
                                color: Colors.grey.shade500, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                resort.distanceInfo,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600),
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
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${resort.price}",
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            "/ person",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 15),
                          ),
                        ),
                        const Spacer(),
                        if (resort.originalPrice > resort.price)
                          Text(
                            "₹${resort.originalPrice}",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 18,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// ================= HIGHLIGHTS =================
                  _sectionTitle("Resort Highlights"),
                  const SizedBox(height: 12),
                  _buildHighlightsGrid(resort.highlights),

                  const SizedBox(height: 24),

                  /// ================= FACILITIES =================
                  _sectionTitle("Facilities"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: resort.facilities.map((f) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(f,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  /// ================= WHAT'S INCLUDED =================
                  _sectionTitle("What's Included"),
                  const SizedBox(height: 12),
                  _buildInclusionsList(resort.inclusions),

                  const SizedBox(height: 24),

                  /// ================= DESCRIPTION =================
                  _sectionTitle("Description"),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8),
                      ],
                    ),
                    child: Text(
                      resort.description,
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade800,
                          height: 1.6),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ================= TIMINGS & RULES =================
                  _sectionTitle("Resort Timings & Rules"),
                  const SizedBox(height: 12),
                  _buildTimingCard(resort.timings, resort.rules),
                ],
              ),
            ),
          ],
        ),
      ),

      /// ================= BOOK BUTTON =================
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ResortBookingPage(resort: widget.resort),
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text(
                "Book Now",
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= HIGHLIGHTS GRID =================
  // ✅ now driven entirely by resort.highlights — different per resort
  Widget _buildHighlightsGrid(List<HighlightItem> highlights) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: highlights.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final item = highlights[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 6),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon,
                    color: Colors.blue.shade700, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                item.sub,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ================= INCLUSIONS LIST =================
  // ✅ now driven entirely by resort.inclusions
  Widget _buildInclusionsList(List<String> inclusions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: inclusions.map((text) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade800),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ================= TIMING CARD =================
  // ✅ now driven entirely by resort.timings + resort.rules
  Widget _buildTimingCard(List<TimingItem> timings, List<String> rules) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          ...timings.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(item.icon,
                      color: Colors.blue.shade600, size: 18),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: Text(
                      item.label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.value,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 24),

          Row(
            children: [
              Icon(Icons.info_outline,
                  color: Colors.orange.shade600, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Important Rules",
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...rules.map((rule) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ",
                      style:
                          TextStyle(fontSize: 15, color: Colors.orange)),
                  Expanded(
                    child: Text(
                      rule,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// ================= SECTION TITLE =================
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }
}