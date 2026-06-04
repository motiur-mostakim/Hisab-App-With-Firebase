import 'package:flutter/material.dart';

class CategoriesBottomSheet extends StatelessWidget {
  final Function(Map<String, dynamic>) onCategorySelected;

  const CategoriesBottomSheet({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    // Strictly Black and White Theme
    const backgroundColor = Colors.black;
    const primaryTextColor = Colors.white;
    const secondaryTextColor = Colors.white70;
    const handleColor = Colors.white24;
    final searchFillColor = Colors.white.withOpacity(0.1);
    final itemBgColor = Colors.white.withOpacity(0.1);

    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  "অন্যান্য বিভাগ",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: secondaryTextColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: primaryTextColor),
              decoration: InputDecoration(
                hintText: "বিভাগ খুঁজুন...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: searchFillColor,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 20,
              children: [
                _item(
                  Icons.card_giftcard,
                  "উপহার",
                  itemBgColor,
                  primaryTextColor,
                ),
                _item(Icons.movie, "বিনোদন", itemBgColor, primaryTextColor),
                _item(
                  Icons.medical_services,
                  "স্বাস্থ্য",
                  itemBgColor,
                  primaryTextColor,
                ),
                _item(Icons.school, "শিক্ষা", itemBgColor, primaryTextColor),
                _item(Icons.flight, "ভ্রমণ", itemBgColor, primaryTextColor),
                _item(
                  Icons.family_restroom,
                  "পরিবার",
                  itemBgColor,
                  primaryTextColor,
                ),
                _item(Icons.receipt, "বিল", itemBgColor, primaryTextColor),
                _item(
                  Icons.trending_up,
                  "বিনিয়োগ",
                  itemBgColor,
                  primaryTextColor,
                ),
                _item(Icons.restaurant, "খাবার", itemBgColor, primaryTextColor),
                _item(
                  Icons.shopping_bag,
                  "কেনাকাটা",
                  itemBgColor,
                  primaryTextColor,
                ),
                _item(
                  Icons.directions_car,
                  "পরিবহন",
                  itemBgColor,
                  primaryTextColor,
                ),
                _item(
                  Icons.fitness_center,
                  "ব্যায়াম",
                  itemBgColor,
                  primaryTextColor,
                ),
                _item(Icons.home, "বাসস্থান", itemBgColor, primaryTextColor),
                _item(Icons.savings, "সঞ্চয়", itemBgColor, primaryTextColor),
                _item(
                  Icons.volunteer_activism,
                  "দান",
                  itemBgColor,
                  primaryTextColor,
                ),
                _item(Icons.payments, "বেতন", itemBgColor, primaryTextColor),
                Column(
                  children: [
                    Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: handleColor),
                      ),
                      child: const Icon(Icons.add, color: secondaryTextColor),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "নতুন",
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "কাস্টম বিভাগ তৈরি করুন",
                        style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "আপনার নিজস্ব লেবেল এবং আইকন যোগ করুন",
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "শুরু করুন",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, Color bgColor, Color textColor) {
    return GestureDetector(
      onTap: () => onCategorySelected({"icon": icon, "name": title}),
      child: Column(
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: textColor.withOpacity(0.9)),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
