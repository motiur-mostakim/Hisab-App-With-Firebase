import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hisab_app/src/features/home_screen.dart';
import 'package:hisab_app/src/features/main_screen.dart';
import 'package:hisab_app/src/features/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
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
          SnackBar(
            content: Text('Successfully sign in'),
            backgroundColor: Colors.white,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      print(e);
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

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C1F),
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
                  color: const Color(0xFF1E1E32),
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
              const Text(
                "স্বাগতম",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE2E0FC),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "আপনার অর্থ ব্যবস্থাপনা শুরু করতে লগইন করুন",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),

              const SizedBox(height: 30),

              /// 🔥 CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E32).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
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
                      children: const [
                        Expanded(child: Divider(color: Colors.grey)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "অথবা",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// GOOGLE LOGIN
                    InkWell(
                      onTap: _signInWithGoogle,
                      child: Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          color: const Color(0xFF28283D),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: _isLoading
                              ? CircularProgressIndicator()
                              : Text(
                                  "গুগল দিয়ে প্রবেশ করুন",
                                  style: TextStyle(color: Colors.white),
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
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "অ্যাকাউন্ট নেই? ",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF333348).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
