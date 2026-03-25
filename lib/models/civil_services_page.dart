import 'package:flutter/material.dart';
import '../data/civil_data.dart';
import '../models/service_product.dart';
import '../models/cart.dart';
import '../widgets/civil_card.dart';
import '../widgets/renovation_bottom_sheet.dart';
import '../models/civil_detail_page.dart';
import '../screens/civil_book_page.dart';

class CivilServicesPage extends StatefulWidget {
  const CivilServicesPage({super.key});

  @override
  State<CivilServicesPage> createState() => _CivilServicesPageState();
}

class _CivilServicesPageState extends State<CivilServicesPage> {

  int selectedIndex = 0;

  void refresh() => setState(() {});

  /// PRICE FIX
  int extractPrice(String price) {
    final numbers = price.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.isEmpty) return 0;
    return int.tryParse(numbers) ?? 0;
  }

  /// CONVERT
  ServiceProduct convert(SubService sub, String category) {
    return ServiceProduct(
      id: sub.id,
      name: sub.name,
      price: extractPrice(sub.price),
      imagePath: sub.image,
      category: category,
      rating: sub.rating,
      discount: sub.discount,
      service: '',
    );
  }

  /// ADD TO CART
  void addToCart(ServiceProduct service) {

    Cart.add(
      CartItem(
        id: "civil_${service.id}",
        name: service.name,
        price: service.price,
        service: "Civil Contract Services",
        category: service.category ?? "",
        image: service.imagePath,
      ),
      service: "Civil Contract Services",
    );

    refresh();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${service.name} added")),
    );
  }

  /// BOOK HANDLER
  void handleBooking(ServiceProduct service) {

    if (service.category == "Renovation") {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => RenovationBottomSheet(
          packageId: service.id,
          packageName: service.name,
        ),
      );
    } else {
      addToCart(service);
    }
  }

  /// OPEN DETAILS
  void openDetails(SubService sub, String mainId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CivilServiceDetailPage(
          service: sub,
          mainServiceId: mainId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final categories = civilServices;
    final selectedService = categories[selectedIndex];
    final subServices = selectedService.subServices;

    final totalItems =
        Cart.getTotalItems("Civil Contract Services");
    final totalPrice =
        Cart.getTotal("Civil Contract Services");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Civil Contract Services"),
      ),

      body: SafeArea(
        child: Column(
          children: [

            /// MAIN CONTENT
            Expanded(
              child: Row(
                children: [

                  /// LEFT CATEGORY PANEL
                  Container(
                    width: 90,
                    color: Colors.grey.shade100,
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {

                        final category = categories[index];
                        final isSelected =
                            selectedIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() =>
                                selectedIndex = index);
                          },

                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 12),

                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 4,
                                ),
                              ),
                            ),

                            child: Column(
                              children: [

                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage:
                                      AssetImage(
                                          category.image),
                                ),

                                const SizedBox(height: 6),

                                Padding(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                              horizontal:
                                                  4),
                                  child: Text(
                                    category.name,
                                    textAlign:
                                        TextAlign.center,
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight
                                                  .bold
                                              : FontWeight
                                                  .normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  /// RIGHT SERVICE LIST
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          10,
                          10,
                          10,
                          totalItems > 0 ? 90 : 10),
                      itemCount: subServices.length,
                      itemBuilder: (context, index) {

                        final sub =
                            subServices[index];

                        final service = convert(
                            sub, selectedService.name);

                        return CivilServiceCard(
                          service: service,
                          displayPrice: sub.price,
                          onAddCart: () =>
                              handleBooking(service),
                          onTap: () => openDetails(
                              sub,
                              selectedService.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            /// CART BAR
            if (totalItems > 0)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10),
                color: Colors.black,
                child: Row(
                  children: [

                    Text(
                      "$totalItems items",
                      style: const TextStyle(
                          color: Colors.white),
                    ),

                    const Spacer(),

                    Text(
                      "₹$totalPrice",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.orange,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CivilBookingPage(
                                    serviceName: ''),
                          ),
                        ).then(
                            (_) => refresh());
                      },
                      child:
                          const Text("View Cart"),
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