import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? "");
    _emailController = TextEditingController(text: user?.email ?? "");
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("অনুগ্রহ করে আপনার নাম লিখুন")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? photoUrl = user.photoURL;

      if (_imageFile != null) {
        final ref = _storage.ref().child('user_profiles/${user.uid}.jpg');
        await ref.putFile(_imageFile!);
        photoUrl = await ref.getDownloadURL();
      }

      await user.updateDisplayName(_nameController.text);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("প্রোফাইল সফলভাবে আপডেট করা হয়েছে")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("ত্রুটি: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF60DCB2)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "প্রোফাইল এডিট করুন",
          style: TextStyle(
            color: isDark ? const Color(0xFFE2E0FC) : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Column(
              children: [
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF60DCB2),
                                isDark
                                    ? const Color(0xFF333348)
                                    : Colors.grey[300]!,
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : NetworkImage(
                                        user?.photoURL ??
                                            "https://i.pravatar.cc/300",
                                      )
                                      as ImageProvider,
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF60DCB2), Color(0xFF009672)],
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Color(0xFF003829),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "আপনার ছবি পরিবর্তন করুন",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                _inputField(
                  isDark: isDark,
                  controller: _nameController,
                  icon: Icons.person,
                  label: "পুরো নাম",
                  hint: "আপনার নাম লিখুন",
                ),

                _inputField(
                  isDark: isDark,
                  controller: _emailController,
                  icon: Icons.mail,
                  label: "ইমেইল ঠিকানা",
                  hint: "আপনার ইমেইল",
                  readOnly: true,
                ),

                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF60DCB2), Color(0xFF009672)],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF003829),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "পরিবর্তন সংরক্ষণ করুন",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003829),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "বাতিল করুন",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFF60DCB2)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "নিরাপত্তা টিপস",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "আপনার অ্যাকাউন্ট সুরক্ষিত রাখতে নিয়মিত পাসওয়ার্ড পরিবর্তন করুন।",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF60DCB2)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputField({
    required bool isDark,
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E32) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, color: const Color(0xFF60DCB2)),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly: readOnly,
                  style: TextStyle(
                    color: readOnly
                        ? (isDark ? Colors.white54 : Colors.black45)
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
