import 'package:flutter/material.dart';

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({super.key});

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  int selectedIndex = 0;

  final List<IconData> icons = [
    Icons.restaurant,
    Icons.shopping_cart,
    Icons.directions_car,
    Icons.home,
    Icons.medical_services,
    Icons.payments,
    Icons.school,
    Icons.fitness_center,
    Icons.flight,
    Icons.theaters,
    Icons.card_giftcard,
    Icons.pets,
  ];

  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// HANDLE
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              /// TITLE
              const Text(
                "নতুন বিভাগ যোগ করুন",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "আপনার ব্যয়ের জন্য একটি নতুন ক্যাটাগরি তৈরি করুন",
                style: TextStyle(color: Colors.white54),
              ),

              const SizedBox(height: 25),

              /// INPUT
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "বিভাগের নাম",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "যেমন: বিনোদন",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF333348),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              /// ICON GRID
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "আইকন নির্বাচন করুন",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: icons.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemBuilder: (context, index) {
                      final selected = selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF60DCB2).withOpacity(0.2)
                                : const Color(0xFF333348),
                            borderRadius: BorderRadius.circular(15),
                            border: selected
                                ? Border.all(
                                    color: const Color(0xFF60DCB2),
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Icon(
                            icons[index],
                            color: selected
                                ? const Color(0xFF60DCB2)
                                : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("বাতিল করুন"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Save category
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60DCB2),
                        foregroundColor: const Color(0xFF003829),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("যোগ করুন"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
