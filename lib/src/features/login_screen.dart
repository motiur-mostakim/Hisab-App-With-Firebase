import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hisab_app/src/features/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure we start fresh
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in'),
            backgroundColor: Color(0xFF60DCB2),
          ),
        );
      }
    } catch (e) {
      debugPrint("----------error---------------$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0C1F) : Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              /// 🔥 ICON
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E32) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF60DCB2),
                  size: 35,
                ),
              ),

              const SizedBox(height: 20),

              /// TITLE
              Text(
                "স্বাগতম",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE2E0FC) : Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "আপনার অর্থ ব্যবস্থাপনা শুরু করতে লগইন করুন",
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
              ),

              const SizedBox(height: 30),

              /// 🔥 CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF1E1E32).withOpacity(0.7) 
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(25),
                  border: isDark ? null : Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    /// EMAIL
                    _inputField(
                      icon: Icons.mail,
                      hint: "name@example.com",
                      label: "ইমেল বা ফোন নম্বর",
                    ),

                    const SizedBox(height: 20),

                    /// PASSWORD
                    _inputField(
                      icon: Icons.lock,
                      hint: "••••••••",
                      label: "পাসওয়ার্ড",
                      isPassword: true,
                    ),

                    const SizedBox(height: 25),

                    /// LOGIN BUTTON
                    InkWell(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF60DCB2), Color(0xFF009672)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Text(
                            "লগইন করুন →",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003829),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// DIVIDER
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? Colors.grey : Colors.grey[400])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "অথবা",
                            style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                          ),
                        ),
                        Expanded(child: Divider(color: isDark ? Colors.grey : Colors.grey[400])),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// GOOGLE LOGIN
                    InkWell(
                      onTap: _isLoading ? null : _signInWithGoogle,
                      child: Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF28283D) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: isDark ? null : Border.all(color: Colors.grey[300]!),
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF60DCB2),
                                  ),
                                )
                              : Text(
                                  "গুগল দিয়ে প্রবেশ করুন",
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// FOOTER
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "অ্যাকাউন্ট নেই? ",
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    const Text(
                      "রেজিস্ট্রেশন করুন",
                      style: TextStyle(
                        color: Color(0xFF60DCB2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 INPUT FIELD WIDGET
  Widget _inputField({
    required IconData icon,
    required String hint,
    required String label,
    bool isPassword = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: isDark 
                ? const Color(0xFF333348).withOpacity(0.5) 
                : Colors.white,
            enabledBorder: isDark 
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  )
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF60DCB2)),
            ),
          ),
        ),
      ],
    );
  }
}
