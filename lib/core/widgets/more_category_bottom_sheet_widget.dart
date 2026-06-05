import 'package:flutter/material.dart';

class CategoriesBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onCategorySelected;

  const CategoriesBottomSheet({super.key, required this.onCategorySelected});

  @override
  State<CategoriesBottomSheet> createState() => _CategoriesBottomSheetState();
}

class _CategoriesBottomSheetState extends State<CategoriesBottomSheet> {
  final List<Map<String, dynamic>> allCategories = [
    {"icon": Icons.card_giftcard, "name": "উপহার"},
    {"icon": Icons.movie, "name": "বিনোদন"},
    {"icon": Icons.medical_services, "name": "স্বাস্থ্য"},
    {"icon": Icons.school, "name": "শিক্ষা"},
    {"icon": Icons.flight, "name": "ভ্রমণ"},
    {"icon": Icons.family_restroom, "name": "পরিবার"},
    {"icon": Icons.receipt, "name": "বিল"},
    {"icon": Icons.trending_up, "name": "বিনিয়োগ"},
    {"icon": Icons.restaurant, "name": "খাবার"},
    {"icon": Icons.shopping_bag, "name": "কেনাকাটা"},
    {"icon": Icons.directions_car, "name": "পরিবহন"},
    {"icon": Icons.fitness_center, "name": "ব্যায়াম"},
    {"icon": Icons.home, "name": "বাসস্থান"},
    {"icon": Icons.savings, "name": "সঞ্চয়"},
    {"icon": Icons.volunteer_activism, "name": "দান"},
    {"icon": Icons.payments, "name": "বেতন"},
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final handleColor = isDark ? Colors.white24 : Colors.black12;
    final searchFillColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200];
    final itemBgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100];

    final filteredCategories = allCategories
        .where((cat) =>
            cat["name"].toString().toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              style: TextStyle(color: primaryTextColor),
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
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 6,
                mainAxisExtent: 90,
              ),
              itemCount: filteredCategories.length + (searchQuery.isEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < filteredCategories.length) {
                  final category = filteredCategories[index];
                  return _item(
                    category["icon"],
                    category["name"],
                    itemBgColor!,
                    primaryTextColor,
                  );
                } else {
                  return Column(
                    children: [
                      Container(
                        height: 55,
                        width: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: handleColor),
                        ),
                        child: Icon(Icons.add, color: secondaryTextColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "নতুন",
                        style: TextStyle(fontSize: 12, color: secondaryTextColor),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
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
                        style: TextStyle(color: secondaryTextColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
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
      onTap: () => widget.onCategorySelected({"icon": icon, "name": title}),
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
