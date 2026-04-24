import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../core/model/transaction_model.dart';
import '../../core/services/transaction_service.dart';
import '../../core/widgets/more_category_bottom_sheet_widget.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool initialIsExpense;
  const AddTransactionScreen({super.key, this.initialIsExpense = true});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late bool isExpense;
  Map<String, dynamic>? selectedCategory;
  File? receiptFile;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    isExpense = widget.initialIsExpense;
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

      final transaction = TransactionModel(
        id: transactionId,
        userId: userId,
        amount: amount,
        category: category,
        note: noteController.text,
        isExpense: isExpense,
        date: selectedDate,
        createdAt: DateTime.now(),
      );

      await _transactionService.addTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('লেনদেন সংরক্ষিত হয়েছে')),
      );

      Navigator.pop(context); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ত্রুটি: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final fieldFillColor = isDark ? const Color(0xFF333348) : Colors.grey[200];

    return Scaffold(
      appBar: AppBar(
        title: Text(isExpense ? "নতুন ব্যয়" : "নতুন আয়"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "\৳",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                    decoration: InputDecoration(
                      hintText: "0.00",
                      hintStyle: const TextStyle(color: Colors.grey),
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
                color: isDark ? const Color(0xFF1A1A2E) : Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [_toggleBtn("ব্যয়", true, isDark), _toggleBtn("আয়", false, isDark)],
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "বিভাগ নির্বাচন করুন",
              style: TextStyle(color: secondaryTextColor),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final item = categories[index];
                  final isSelected = selectedCategory == item;

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
                            : (isDark ? const Color(0xFF1E1E32) : Colors.grey[200]),
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
            Text("তারিখ", style: TextStyle(color: secondaryTextColor)),
            const SizedBox(height: 5),
            TextField(
              controller: dateController,
              onTap: _selectDate,
              readOnly: true,
              style: TextStyle(color: primaryTextColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: fieldFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            Text("বিবরণ", style: TextStyle(color: secondaryTextColor)),
            const SizedBox(height: 5),
            TextField(
              controller: noteController,
              maxLines: 2,
              style: TextStyle(color: primaryTextColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: fieldFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: "এটি কিসের জন্য ছিল?",
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
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
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String text, bool value, bool isDark) {
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
          color: selected ? (isDark ? const Color(0xFF333348) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected 
              ? (isDark ? Colors.white : Colors.black) 
              : Colors.grey,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
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
