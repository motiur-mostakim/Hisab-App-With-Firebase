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
  bool isLoan = false;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController personController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TransactionService _transactionService = TransactionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime selectedDate = DateTime.now();

  final List<Map<String, dynamic>> categories = [
    {"icon": Icons.restaurant, "name": "খাবার"},
    {"icon": Icons.shopping_bag, "name": "কেনাকাটা"},
    {"icon": Icons.directions_car, "name": "পরিবহন"},
    {"icon": Icons.payments, "name": "বেতন"},
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
    final amountText = amountController.text.trim();
    final amount = double.tryParse(amountText);
    final category = selectedCategory?['name'];
    final userId = _auth.currentUser?.uid;

    if (amount == null || amount <= 0) {
      _showSnackBar('সঠিক পরিমাণ প্রবেশ করুন');
      return;
    }

    if (isLoan && personController.text.isEmpty) {
      _showSnackBar('ব্যক্তির নাম লিখুন');
      return;
    }

    if (userId == null) {
      _showSnackBar('ব্যবহারকারী লগইন করা নেই');
      return;
    }

    try {
      final transactionId = const Uuid().v4();

      String type;
      if (isLoan) {
        type = isExpense ? 'loan_given' : 'loan_taken';
      } else {
        type = isExpense ? 'expense' : 'income';
      }

      final transaction = TransactionModel(
        id: transactionId,
        userId: userId,
        amount: amount,
        type: type,
        category: isLoan ? "ধার/বাকি" : (category ?? "অন্যান্য"),
        personId: isLoan ? personController.text : null,
        note: isLoan ? noteController.text : noteController.text,
        transactionDate: selectedDate,
        createdAt: DateTime.now(),
      );

      await _transactionService.addTransaction(transaction);

      if (!mounted) return;
      _showSnackBar('লেনদেন সংরক্ষিত হয়েছে');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('ত্রুটি: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final fieldFillColor = isDark ? const Color(0xFF333348) : Colors.grey[200];

    return Scaffold(
      appBar: AppBar(
        title: Text(isLoan 
          ? (isExpense ? "ধার দেওয়া" : "ধার নেওয়া")
          : (isExpense ? "নতুন ব্যয়" : "নতুন আয়")),
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
            // Amount Input Section
            Row(
              children: [
                Text(
                  "৳",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: isLoan ? Colors.orange : (isExpense ? Colors.red : Colors.green),
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
                    decoration: const InputDecoration(
                      hintText: "0.00",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(left: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Income/Expense Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _toggleBtn("ব্যয়", true, isDark),
                  _toggleBtn("আয়", false, isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Loan/Dhar Switch Widget
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isLoan ? Colors.orange.withOpacity(0.1) : fieldFillColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLoan ? Colors.orange.withOpacity(0.5) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLoan ? Colors.orange : Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handshake, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExpense ? "কাউকে ধার দিচ্ছি" : "কারো থেকে ধার নিচ্ছি",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          "এটি ধারের লেনদেন হিসেবে চিহ্নিত করুন",
                          style: TextStyle(color: secondaryTextColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isLoan,
                    onChanged: (v) => setState(() => isLoan = v),
                    activeColor: Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Person Name Field (Only for Loan)
            if (isLoan) ...[
              Text("ব্যক্তির নাম", style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: personController,
                style: TextStyle(color: primaryTextColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldFillColor,
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.orange),
                  hintText: isExpense ? "কাকে টাকা দিচ্ছেন?" : "কার থেকে টাকা নিচ্ছেন?",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Category Selection (Hidden for Loan if needed, but keeping it visible for flexibility)
            if (!isLoan) ...[
              Text("বিভাগ নির্বাচন করুন", style: TextStyle(color: secondaryTextColor)),
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
                          setState(() => selectedCategory = item);
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
                          border: isSelected ? Border.all(color: const Color(0xFF60DCB2)) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item["icon"], color: isSelected ? const Color(0xFF60DCB2) : Colors.grey),
                            const SizedBox(height: 5),
                            Text(
                              item["name"],
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF60DCB2) : Colors.grey,
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
            ],

            // Date Selection
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Description/Note
            Text("বিবরণ (ঐচ্ছিক)", style: TextStyle(color: secondaryTextColor)),
            const SizedBox(height: 5),
            TextField(
              controller: noteController,
              maxLines: 2,
              style: TextStyle(color: primaryTextColor),
              decoration: InputDecoration(
                filled: true,
                fillColor: fieldFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                hintText: "কিছু লিখতে চান?",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),

            const SizedBox(height: 35),

            // Save Button
            GestureDetector(
              onTap: _saveTransaction,
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLoan 
                      ? [Colors.orange, Colors.deepOrange]
                      : [const Color(0xFF60DCB2), const Color(0xFF009672)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: (isLoan ? Colors.orange : const Color(0xFF60DCB2)).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: const Center(
                  child: Text(
                    "লেনদেন সংরক্ষণ করুন",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
          // When switching, we don't necessarily reset isLoan, but keep it consistent
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? (isDark ? const Color(0xFF333348) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showMoreCategories() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoriesBottomSheet(
        onCategorySelected: (category) => Navigator.pop(context, category),
      ),
    );
    if (result != null) {
      setState(() => selectedCategory = result);
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    personController.dispose();
    noteController.dispose();
    dateController.dispose();
    super.dispose();
  }
}
