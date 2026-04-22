import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111125),

      /// 🔥 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF60DCB2)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "প্রোফাইল এডিট করুন",
          style: TextStyle(
            color: Color(0xFFE2E0FC),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          children: [
            /// 🔥 PROFILE IMAGE
            Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF60DCB2), Color(0xFF333348)],
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          "https://lh3.googleusercontent.com/aida-public/AB6AXuBo9_adZC6MgUyZjOGOlb5mQa4uHHShmT7QbZjV49wCwE-MSoCVag_hF0J4hVnPuh84GYg--yZ3g9vM14Hae_DFtWV1T2mTJ4BBvNTsMAl_s7QdiKyu-r3AYmQjSX6-ypk62gPLToNNQXULGNLtIQOwBqfFfxiv05AsiA3Rp-7LTQSaiRzBXO0ZdVwzunorZUKZC0_skhicQ2cluCnP5BAXCQmvwhfOFJG3PAI-VrhyJQklYYic-B_-zT0WIcraGlH8hdDn8BwLXtA",
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF60DCB2), Color(0xFF009672)],
                        ),
                      ),
                      child: const Icon(Icons.edit, size: 18),
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

            /// 🔥 FORM FIELDS
            _inputField(
              icon: Icons.person,
              label: "পুরো নাম",
              hint: "আপনার নাম লিখুন",
              initialValue: "আন্দুর রহমান",
            ),

            _inputField(
              icon: Icons.mail,
              label: "ইমেইল ঠিকানা",
              hint: "আপনার ইমেইল",
              initialValue: "rahman.abdur@email.com",
            ),

            _inputField(
              icon: Icons.call,
              label: "ফোন নম্বর",
              hint: "+৮৮০ ১xxx xxxxxx",
            ),

            const SizedBox(height: 30),

            /// 🔥 SAVE BUTTON
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: const LinearGradient(
                  colors: [Color(0xFF60DCB2), Color(0xFF009672)],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text(
                  "পরিবর্তন সংরক্ষণ করুন",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 🔥 CANCEL BUTTON
            TextButton(
              onPressed: () {},
              child: const Text(
                "বাতিল করুন",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),

            const SizedBox(height: 30),

            /// 🔥 SECURITY CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.security, color: Color(0xFF60DCB2)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "নিরাপত্তা টিপস",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
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
    );
  }

  /// 🔥 REUSABLE INPUT FIELD
  Widget _inputField({
    required IconData icon,
    required String label,
    required String hint,
    String? initialValue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E32),
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
                  initialValue: initialValue,
                  style: const TextStyle(color: Colors.white),
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
}
