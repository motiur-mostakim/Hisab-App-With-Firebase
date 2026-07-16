import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool isChecked = false;
  bool obscure1 = true;
  bool obscure2 = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সবগুলো তথ্য পূরণ করুন'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('পাসওয়ার্ড মিলছে না'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('শর্তাবলী মেনে নিন'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('সফলভাবে রেজিস্ট্রেশন হয়েছে'),
              backgroundColor: Color(0xFF60DCB2),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'রেজিস্ট্রেশন ব্যর্থ হয়েছে';
      if (e.code == 'weak-password') {
        message = 'পাসওয়ার্ডটি খুব দুর্বল';
      } else if (e.code == 'email-already-in-use') {
        message = 'এই ইমেলটি ইতিপূর্বে ব্যবহার করা হয়েছে';
      } else if (e.code == 'invalid-email') {
        message = 'সঠিক ইমেল ঠিকানা দিন';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            if (MediaQuery.of(context).size.width > 800)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  color: isDark ? const Color(0xFF0C0C1F) : Colors.grey[100],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF60DCB2),
                        size: 50,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "অর্থ সঞ্চয়",
                        style: TextStyle(
                          color: Color(0xFF60DCB2),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "আপনার সম্পদ,\nআপনার নিয়ন্ত্রণ।",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "সহজে আপনার অর্থ ব্যবস্থাপনা করুন",
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "অ্যাকাউন্ট তৈরি করুন",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "আপনার আর্থিক ভবিষ্যৎ সুরক্ষিত করতে আজই যুক্ত হোন",
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                    ),

                    const SizedBox(height: 30),
                    _input("পুরো নাম", Icons.person, "আপনার নাম লিখুন", controller: _nameController),
                    _input("ইমেল ঠিকানা", Icons.mail, "example@email.com", controller: _emailController),
                    _input(
                      "পাসওয়ার্ড",
                      Icons.lock,
                      "••••••••",
                      isPassword: true,
                      isFirst: true,
                      controller: _passwordController,
                    ),
                    _input(
                      "পাসওয়ার্ড নিশ্চিত করুন",
                      Icons.key,
                      "••••••••",
                      isPassword: true,
                      isFirst: false,
                      controller: _confirmPasswordController,
                    ),

                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          activeColor: const Color(0xFF60DCB2),
                          onChanged: (v) {
                            setState(() {
                              isChecked = v!;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            "আমি সকল শর্তাবলী মেনে নিচ্ছি",
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    InkWell(
                      onTap: _isLoading ? null : _register,
                      child: Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF60DCB2), Color(0xFF009672)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF003829),
                                  ),
                                )
                              : const Text(
                                  "রেজিস্ট্রেশন করুন →",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003829),
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                    Center(
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: "ইতিমধ্যে অ্যাকাউন্ট আছে? ",
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                            children: const [
                              TextSpan(
                                text: "লগইন করুন",
                                style: TextStyle(
                                  color: Color(0xFF60DCB2),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _input(
    String label,
    IconData icon,
    String hint, {
    required TextEditingController controller,
    bool isPassword = false,
    bool isFirst = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            obscureText: isPassword ? (isFirst ? obscure1 : obscure2) : false,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        (isFirst ? obscure1 : obscure2)
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isFirst) {
                            obscure1 = !obscure1;
                          } else {
                            obscure2 = !obscure2;
                          }
                        });
                      },
                    )
                  : null,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: isDark 
                  ? const Color(0xFF333348) 
                  : Colors.grey[50],
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF60DCB2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
