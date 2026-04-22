import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/model/transaction_model.dart';
import '../../core/services/transaction_service.dart';
import '../../core/widgets/more_category_bottom_sheet_widget.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool isExpense = true;
  Map<String, dynamic>? selectedCategory;
  File? receiptFile;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  DateTime selectedDate = DateTime.now();

  final List<Map<String, dynamic>> categories = [
    {"icon": Icons.restaurant, "name": "খাবার"},
    {"icon": Icons.shopping_bag, "name": "কেনাকাটা"},
    {"icon": Icons.directions_car, "name": "পরিবহন"},
    {"icon": Icons.movie, "name": "বিনোদন"},
    {"icon": Icons.health_and_safety, "name": "স্বাস্থ্য"},
    {"icon": Icons.more_horiz, "name": "অন্যান্য"},
  ];

  @override
  void initState() {
    super.initState();
    dateController.text = _formatDate(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = _formatDate(picked);
      });
    }
  }

  // Future<void> _pickReceipt() async {
  //   final picked = await _picker.pickImage(
  //     source: ImageSource.gallery,
  //     maxWidth: 1200,
  //     maxHeight: 1200,
  //     imageQuality: 80,
  //   );
  //   if (picked != null) {
  //     setState(() {
  //       receiptFile = File(picked.path);
  //     });
  //   }
  // }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(amountController.text);
    final category = selectedCategory?['name'] ?? 'অন্যান্য';
    final userId = _auth.currentUser?.uid;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সঠিক পরিমাণ প্রবেশ করুন')),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ব্যবহারকারী লগইন করা নেই')),
      );
      return;
    }

    try {
      final transactionId = const Uuid().v4();
      // String? receiptUrl;
      //
      // if (receiptFile != null) {
      //   receiptUrl = await _transactionService.uploadReceipt(
      //     receiptFile!,
      //     userId,
      //     transactionId,
      //   );
      // }

      final transaction = TransactionModel(
        id: transactionId,
        userId: userId,
        amount: amount,
        category: category,
        note: noteController.text,
        isExpense: isExpense,
        date: selectedDate,
        createdAt: DateTime.now(),
        // receiptUrl: receiptUrl,
      );

      await _transactionService.addTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('লেনদেন সংরক্ষিত হয়েছে')),
      );

      setState(() {
        amountController.clear();
        noteController.clear();
        selectedCategory = null;
        isExpense = true;
        selectedDate = DateTime.now();
        dateController.text = _formatDate(selectedDate);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ত্রুটি: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111125),
        elevation: 0,
        title: const Text("নতুন লেনদেন"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "\$",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: "0.00",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [_toggleBtn("ব্যয়", true), _toggleBtn("আয়", false)],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "বিভাগ নির্বাচন করুন",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final item = categories[index];
                  final isSelected = selectedCategory == item ||
                      (index == categories.length - 1 &&
                          selectedCategory != null &&
                          !categories.contains(selectedCategory));

                  return GestureDetector(
                    onTap: () {
                      if (index == categories.length - 1) {
                        _showMoreCategories();
                      } else {
                        setState(() {
                          selectedCategory = item;
                        });
                      }
                    },
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF60DCB2).withOpacity(0.2)
                            : const Color(0xFF1E1E32),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item["icon"],
                            color: isSelected
                                ? const Color(0xFF60DCB2)
                                : Colors.grey,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item["name"],
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF60DCB2)
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),
            const Text("তারিখ", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 5),
            TextField(
              controller: dateController,
              onTap: _selectDate,
              readOnly: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF333348),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            const Text("বিবরণ", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 5),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF333348),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: "এটি কিসের জন্য ছিল?",
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            // const SizedBox(height: 25),
            // GestureDetector(
            //   onTap: _pickReceipt,
            //   child: Container(
            //     height: 180,
            //     width: double.infinity,
            //     decoration: BoxDecoration(
            //       color: const Color(0xFF1E1E32),
            //       borderRadius: BorderRadius.circular(15),
            //       border: Border.all(color: Colors.grey.shade700),
            //     ),
            //     child: receiptFile != null
            //         ? ClipRRect(
            //       borderRadius: BorderRadius.circular(15),
            //       child: Image.file(
            //         receiptFile!,
            //         fit: BoxFit.cover,
            //         width: double.infinity,
            //       ),
            //     )
            //         : const Center(
            //       child: Text(
            //         "📷 রসিদ আপলোড করুন (ঐচ্ছিক)",
            //         style: TextStyle(color: Colors.grey),
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _saveTransaction,
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF60DCB2), Color(0xFF009672)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    "লেনদেন সংরক্ষণ করুন",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "বাতিল করুন",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String text, bool value) {
    final selected = isExpense == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          isExpense = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF333348) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(color: selected ? Colors.white : Colors.grey),
        ),
      ),
    );
  }

  void _showMoreCategories() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) => CategoriesBottomSheet(
        onCategorySelected: (category) => Navigator.pop(context, category),
      ),
    );
    if (result != null) {
      setState(() {
        selectedCategory = result;
      });
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    dateController.dispose();
    super.dispose();
  }
}