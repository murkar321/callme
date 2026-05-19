import 'package:flutter/material.dart';
import 'package:callme/data/service_product.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/models/cart_page.dart';
import 'package:callme/bookings/booking_page.dart';

class LaundryDetailPage extends StatefulWidget {
  final ServiceProduct product;
  final String category;
  final String serviceName;

  const LaundryDetailPage({
    super.key,
    required this.product,
    required this.category,
    required this.serviceName,
  });

  @override
  State<LaundryDetailPage> createState() =>
      _LaundryDetailPageState();
}

class _LaundryDetailPageState
    extends State<LaundryDetailPage> {

  /// ================= FABRIC POPUP =================
  void showFabricPopup() {

    String selectedFabric = "Cotton";
    int selectedPrice = 50;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (context) {

        return StatefulBuilder(
          builder: (context, setModalState) {

            return Container(
              height:
                  MediaQuery.of(context).size.height *
                      0.60,

              padding: const EdgeInsets.all(18),

              decoration: const BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),

              child: Column(
                children: [

                  /// HANDLE
                  Container(
                    width: 60,
                    height: 5,

                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// HEADER
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [

                      const Text(
                        "Choose Fabric Type",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      IconButton(
                        onPressed: () =>
                            Navigator.pop(context),

                        icon: Container(
                          padding:
                              const EdgeInsets.all(6),

                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// SUBTITLE
                  Text(
                    "Select fabric for accurate laundry pricing",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// FABRIC LIST
                  Expanded(
                    child: ListView(
                      children: [

                        fabricTile(
                          "Cotton",
                          50,
                          selectedFabric,
                          setModalState,
                          (f, p) {
                            selectedFabric = f;
                            selectedPrice = p;
                          },
                        ),

                        fabricTile(
                          "Silk",
                          70,
                          selectedFabric,
                          setModalState,
                          (f, p) {
                            selectedFabric = f;
                            selectedPrice = p;
                          },
                        ),

                        fabricTile(
                          "Wool",
                          80,
                          selectedFabric,
                          setModalState,
                          (f, p) {
                            selectedFabric = f;
                            selectedPrice = p;
                          },
                        ),

                        fabricTile(
                          "Denim",
                          60,
                          selectedFabric,
                          setModalState,
                          (f, p) {
                            selectedFabric = f;
                            selectedPrice = p;
                          },
                        ),

                        fabricTile(
                          "Curtains",
                          90,
                          selectedFabric,
                          setModalState,
                          (f, p) {
                            selectedFabric = f;
                            selectedPrice = p;
                          },
                        ),

                        fabricTile(
                          "Shoes",
                          100,
                          selectedFabric,
                          setModalState,
                          (f, p) {
                            selectedFabric = f;
                            selectedPrice = p;
                          },
                        ),
                      ],
                    ),
                  ),

                  /// TOTAL CONTAINER
                  Container(
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFAE91BA)
                              .withOpacity(0.08),

                      borderRadius:
                          BorderRadius.circular(18),
                    ),

                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                      children: [

                        const Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),

                        Text(
                          "₹${widget.product.calculatedFinalPrice + selectedPrice}",

                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFFAE91BA),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// BUTTONS
                  Row(
                    children: [

                      /// VIEW CART
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {

                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CartPage(
                                  service:
                                      "Laundry",

                                  serviceName:
                                      "Laundry",

                                  cart:
                                      Cart.getItems(
                                    "Laundry",
                                  ),
                                ),
                              ),
                            ).then(
                              (_) => setState(() {}),
                            );
                          },

                          style:
                              OutlinedButton
                                  .styleFrom(
                            minimumSize:
                                const Size(
                                    0, 55),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          16),
                            ),
                          ),

                          child: const Text(
                            "VIEW CART",
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      /// ADD BUTTON
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {

                            Cart.addLaundry(
                              id:
                                  widget.product.id,

                              name:
                                  "${widget.product.name} ($selectedFabric)",

                              price:
                                  widget.product.calculatedFinalPrice +
                                      selectedPrice,

                              category:
                                  widget.category,

                              image: widget
                                  .product
                                  .imagePath,
                            );

                            Navigator.pop(context);

                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(
                              SnackBar(
                                content:
                                    const Text(
                                  "Added to Cart",
                                ),

                                behavior:
                                    SnackBarBehavior
                                        .floating,

                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              14),
                                ),
                              ),
                            );

                            setState(() {});
                          },

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                                    0xFFAE91BA),

                            minimumSize:
                                const Size(
                                    0, 55),

                            elevation: 0,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          16),
                            ),
                          ),

                          child: const Text(
                            "ADD TO CART",

                            style: TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ================= FABRIC TILE =================
  Widget fabricTile(
    String name,
    int price,
    String selectedFabric,
    StateSetter setModalState,
    Function(String, int) onSelect,
  ) {

    bool isSelected =
        selectedFabric == name;

    return GestureDetector(
      onTap: () {
        setModalState(() {
          onSelect(name, price);
        });
      },

      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 250),

        margin:
            const EdgeInsets.only(bottom: 14),

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFAE91BA)
                  .withOpacity(0.08)
              : Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color: isSelected
                ? const Color(0xFFAE91BA)
                : Colors.grey.shade300,

            width: 1.4,
          ),
        ),

        child: Row(
          children: [

            /// RADIO
            Container(
              width: 22,
              height: 22,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFAE91BA)
                      : Colors.grey,
                  width: 2,
                ),
              ),

              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,

                        decoration:
                            const BoxDecoration(
                          color:
                              Color(0xFFAE91BA),
                          shape:
                              BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 14),

            /// NAME
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Premium laundry care",
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            /// PRICE
            Text(
              "₹$price",

              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color: Color(0xFFAE91BA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F4FA),

      body: Stack(
        children: [

          /// ================= BODY =================
          CustomScrollView(
            slivers: [

              /// APP BAR
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,

                backgroundColor:
                    const Color(0xFFAE91BA),

                iconTheme:
                    const IconThemeData(
                  color: Colors.white,
                ),

                flexibleSpace:
                    FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [

                      /// IMAGE
                      Image.asset(
                        widget.product.imagePath,
                        fit: BoxFit.cover,
                      ),

                      /// OVERLAY
                      Container(
                        decoration:
                            BoxDecoration(
                          gradient:
                              LinearGradient(
                            begin:
                                Alignment
                                    .topCenter,
                            end: Alignment
                                .bottomCenter,

                            colors: [
                              Colors.black
                                  .withOpacity(
                                      0.2),
                              Colors.black
                                  .withOpacity(
                                      0.7),
                            ],
                          ),
                        ),
                      ),

                      /// TEXT
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 30,

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            /// CATEGORY
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    14,
                                vertical: 7,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .white
                                    .withOpacity(
                                        0.2),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            30),
                              ),

                              child: Text(
                                widget.category,

                                style:
                                    const TextStyle(
                                  color: Colors
                                      .white,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ),

                            const SizedBox(
                                height: 14),

                            Text(
                              widget.product.name,

                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 28,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      /// PRICE CARD
                      Container(
                        padding:
                            const EdgeInsets
                                .all(18),

                        decoration:
                            BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius
                                  .circular(
                                      24),

                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withOpacity(
                                      0.05),

                              blurRadius: 10,
                              offset:
                                  const Offset(
                                      0, 4),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  const Text(
                                    "Service Price",
                                    style:
                                        TextStyle(
                                      color: Colors
                                          .grey,
                                    ),
                                  ),

                                  const SizedBox(
                                      height: 8),

                                  Text(
                                    "₹${widget.product.calculatedFinalPrice}",

                                    style:
                                        const TextStyle(
                                      fontSize:
                                          30,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color: Color(
                                          0xFFAE91BA),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (widget.product
                                    .discount !=
                                null)
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      14,
                                  vertical: 10,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color: Colors
                                      .green
                                      .shade100,

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              14),
                                ),

                                child: Text(
                                  "${widget.product.discount}% OFF",

                                  style:
                                      TextStyle(
                                    color: Colors
                                        .green
                                        .shade700,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// DESCRIPTION
                      if (widget.product
                              .description !=
                          null)
                        modernCard(
                          title:
                              "Description",
                          child: Text(
                            widget.product
                                .description!,

                            style:
                                const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ),

                      const SizedBox(height: 22),

                      /// INCLUDES
                      if (widget.product
                          .safeIncludes
                          .isNotEmpty)
                        modernCard(
                          title:
                              "What's Included",

                          child: Column(
                            children: widget
                                .product
                                .safeIncludes
                                .map(
                              (item) {

                                return Padding(
                                  padding:
                                      const EdgeInsets
                                          .only(
                                    bottom:
                                        14,
                                  ),

                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [

                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .all(
                                                    5),

                                        decoration:
                                            BoxDecoration(
                                          color: Colors
                                              .green
                                              .withOpacity(
                                                  0.1),

                                          shape: BoxShape
                                              .circle,
                                        ),

                                        child:
                                            const Icon(
                                          Icons
                                              .check,
                                          color: Colors
                                              .green,
                                          size:
                                              16,
                                        ),
                                      ),

                                      const SizedBox(
                                          width:
                                              12),

                                      Expanded(
                                        child:
                                            Text(
                                          item,

                                          style:
                                              const TextStyle(
                                            fontSize:
                                                15,
                                            height:
                                                1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ),

                      const SizedBox(height: 22),

                      /// TOOLS
                      if (widget.product.tools !=
                          null)
                        modernCard(
                          title:
                              "Tools Used",

                          child: Text(
                            widget.product.tools!,

                            style:
                                const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          /// ================= BOTTOM BAR =================
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,

            child: Container(
              padding:
                  const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(24),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.08),

                    blurRadius: 14,
                    offset:
                        const Offset(0, -4),
                  ),
                ],
              ),

              child: Row(
                children: [

                  /// PRICE
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        const Text(
                          "Starting From",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(
                            height: 4),

                        Text(
                          "₹${widget.product.calculatedFinalPrice}",

                          style:
                              const TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ADD
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          showFabricPopup,

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            Colors.green,

                        minimumSize:
                            const Size(
                                0, 55),

                        elevation: 0,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      16),
                        ),
                      ),

                      child: const Text(
                        "ADD",

                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// BOOK
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingPage(
                              serviceName:
                                  widget
                                      .serviceName,

                              product:
                                  widget.product,

                              products: [],
                            ),
                          ),
                        );
                      },

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                                0xFFAE91BA),

                        minimumSize:
                            const Size(
                                0, 55),

                        elevation: 0,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      16),
                        ),
                      ),

                      child: const Text(
                        "BOOK",

                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= MODERN CARD =================
  Widget modernCard({
    required String title,
    required Widget child,
  }) {

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),

            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            title,

            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          child,
        ],
      ),
    );
  }
}