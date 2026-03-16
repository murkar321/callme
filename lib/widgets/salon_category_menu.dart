import 'package:flutter/material.dart';

class SalonCategoryMenu extends StatelessWidget {

  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const SalonCategoryMenu({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 100,
      color: Colors.grey.shade100,

      child: ListView.builder(
        itemCount: categories.length,

        itemBuilder: (context, index) {

          String category = categories[index];
          bool selected = category == selectedCategory;

          return GestureDetector(

            onTap: () {
              onCategorySelected(category);
            },

            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),

              child: Column(
                children: [

                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: Colors.purple,
                              width: 3,
                            )
                          : null,
                    ),

                    child: const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage("assets/salon.png"),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      category,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selected
                            ? Colors.purple
                            : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}