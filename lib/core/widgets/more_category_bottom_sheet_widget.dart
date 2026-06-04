import 'package:flutter/material.dart';

class CategoriesBottomSheet extends StatelessWidget {
  final Function(Map<String, dynamic>) onCategorySelected;

  const CategoriesBottomSheet({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final fieldColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200];
    final handleColor = isDark ? Colors.white24 : Colors.grey[400];
    final itemBgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100];
    final iconColor = isDark ? Colors.white : Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          /// 🔥 DRAG HANDLE
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

          /// 🔥 HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
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
                  icon: Icon(Icons.close, color: secondaryTextColor),
                ),
              ],
            ),
          ),

          /// 🔥 SEARCH FIELD
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: TextStyle(color: primaryTextColor),
              decoration: InputDecoration(
                hintText: "বিভাগ খুঁজুন...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: fieldColor,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// 🔥 GRID
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 20,
              children: [
                _item(Icons.card_giftcard, "উপহার", itemBgColor!, iconColor, primaryTextColor),
                _item(Icons.movie, "বিনোদন", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.medical_services, "স্বাস্থ্য", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.school, "শিক্ষা", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.flight, "ভ্রমণ", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.family_restroom, "পরিবার", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.receipt, "বিল", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.trending_up, "বিনিয়োগ", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.restaurant, "খাবার", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.shopping_bag, "কেনাকাটা", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.directions_car, "পরিবহন", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.fitness_center, "ব্যায়াম", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.home, "বাসস্থান", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.savings, "সঞ্চয়", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.volunteer_activism, "দান", itemBgColor, iconColor, primaryTextColor),
                _item(Icons.payments, "বেতন", itemBgColor, iconColor, primaryTextColor),

                /// ADD NEW
                Column(
                  children: [
                    Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white38 : Colors.grey),
                      ),
                      child: Icon(Icons.add, color: secondaryTextColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "নতুন",
                      style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 🔥 BOTTOM CARD
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
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
                      const SizedBox(height: 4),
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
                    backgroundColor: isDark ? Colors.white : Colors.black87,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("শুরু করুন", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, Color bgColor, Color iconColor, Color textColor) {
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
            child: Icon(icon, color: iconColor),
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
