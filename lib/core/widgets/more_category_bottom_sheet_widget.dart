import 'package:flutter/material.dart';

class CategoriesBottomSheet extends StatelessWidget {
  final Function(Map<String, dynamic>) onCategorySelected;

  const CategoriesBottomSheet({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          /// 🔥 DRAG HANDLE
          const SizedBox(height: 10),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 10),

          /// 🔥 HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  "অন্যান্য বিভাগ",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE2E0FC),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),

          /// 🔥 SEARCH FIELD
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "বিভাগ খুঁজুন...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2A2A40),
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
                _item(Icons.card_giftcard, "উপহার"),
                _item(Icons.movie, "বিনোদন"),
                _item(Icons.medical_services, "স্বাস্থ্য"),
                _item(Icons.school, "শিক্ষা"),
                _item(Icons.flight, "ভ্রমণ"),
                _item(Icons.family_restroom, "পরিবার"),
                _item(Icons.receipt, "বিল"),
                _item(Icons.trending_up, "বিনিয়োগ"),
                _item(Icons.restaurant, "খাবার"),
                _item(Icons.shopping_bag, "কেনাকাটা"),
                _item(Icons.directions_car, "পরিবহন"),
                _item(Icons.fitness_center, "ব্যায়াম"),
                _item(Icons.home, "বাসস্থান"),
                _item(Icons.savings, "সঞ্চয়"),
                _item(Icons.volunteer_activism, "দান"),

                /// ADD NEW
                Column(
                  children: [
                    Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(Icons.add, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "নতুন",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF60DCB2).withOpacity(0.2),
                  const Color(0xFF60DCB2).withOpacity(0.05),
                ],
              ),
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "আপনার নিজস্ব লেবেল এবং আইকন যোগ করুন",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF60DCB2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("শুরু করুন"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title) {
    return GestureDetector(
      // Wrap in GestureDetector
      onTap: () => onCategorySelected({"icon": icon, "name": title}),
      child: Column(
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A40),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF60DCB2)),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
