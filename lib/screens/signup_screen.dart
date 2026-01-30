import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔥 BACKEND LOGIC (UNCHANGED)
  Future<void> _createAccount() async {
    if (!_agreeToTerms) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      _showSnackBar('Please fill all required fields');
      return;
    }

    try {
      setState(() => _isLoading = true);

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Account created successfully 🎉');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Signup failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 12),

              // Illustration
              Image.asset(
                'assets/images/passport.png',
                height: 100,
              ),

              const SizedBox(height: 24),

              const Text(
                'Create Your Account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 32),

              _inputField(
                controller: _fullNameController,
                hint: 'Full Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _inputField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),

              _inputField(
                controller: _phoneController,
                hint: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _inputField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (v) => setState(() => _agreeToTerms = v!),
                  ),
                  const Text('I agree to Terms & Conditions'),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _agreeToTerms && !_isLoading ? _createAccount : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: const StadiumBorder(),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: const TextStyle(color: Colors.black54),
                  children: [
                    TextSpan(
                      text: 'Login',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
