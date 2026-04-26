import 'package:budget_buddy/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const String _privacyPolicyUrl =
    'https://doc-hosting.flycricket.io/budgetbuddy-privacy-policy/0f0a52ad-f282-4a38-9b32-31d8a06228e6/privacy';
const String _termsUrl =
    'https://doc-hosting.flycricket.io/budgetbuddy-terms-of-use/7055e9ac-1f70-4d5b-a1e9-643c648708e1/terms';

class Login extends StatefulWidget {
  const Login({super.key});
  static String id = "login_page";

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _auth = FirebaseAuth.instance;
  final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,}$',
  );
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;
  bool _obscurePassword = true;

  bool _isPasswordValid(String password) {
    return _passwordRegex.hasMatch(password);
  }

  String _passwordRequirements() {
    return "Use 8+ chars with upper, lower, number, and symbol.";
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter your email first.")));
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset email sent to $email.")),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Could not send reset email.")),
      );
    }
  }

  Future<void> _openLegalLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not open link.")));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Link opening is unavailable right now. Restart the app and try again.",
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    setState(() {
      isLoading = true;
    });
    try {
      if (isLogin) {
        String userEmail = _emailController.text.trim();
        String userPassword = _passwordController.text;
        if (userEmail.isEmpty || userPassword.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter email and password")),
          );
          return;
        }
        await _auth.signInWithEmailAndPassword(
          email: userEmail,
          password: userPassword,
        );
        if (!mounted) return;
        FocusManager.instance.primaryFocus?.unfocus();
        // Go through AuthGate to check if user needs onboarding
        Navigator.pushNamedAndRemoveUntil(
          context,
          AuthGate.id,
          (route) => false,
        );
      } else {
        String userEmail = _emailController.text.trim();
        String userPassword = _passwordController.text;
        String username = _usernameController.text;

        if (userEmail.isEmpty || userPassword.isEmpty || username.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please fill in all fields")),
          );
          return;
        }

        if (!_isPasswordValid(userPassword)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _passwordRequirements(),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          return;
        }
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: userEmail,
          password: userPassword,
        );
        await userCredential.user?.updateDisplayName(username);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_first_launch', true);

        if (!mounted) return;
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pushNamedAndRemoveUntil(
          context,
          AuthGate.id,
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = "Something Went Wrong";
      if (e.code == "user-not-found") {
        message = "No user with that email";
      } else if (e.code == "wrong-password") {
        message = "Wrong password";
      } else if (e.code == "invalid-credential") {
        message = "Invalid email or password";
      } else if (e.code == "email-already-in-use") {
        message = "Email already registered";
      } else if (e.code == "weak-password") {
        message = "Password too weak";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0XFF1A2035),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF378ADD).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: Color(0XFF378ADD),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Budget Buddy",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
              const Text(
                "Track every shilling",
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2035),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0XFF2A3150)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isLogin
                                ? const Color(0xFF378ADD)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Sign in",
                              style: TextStyle(
                                color: isLogin
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLogin = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: !isLogin
                                ? const Color(0xFF378ADD)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Create account",
                              style: TextStyle(
                                color: !isLogin
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!isLogin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "USERNAME",
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormField(
                      theController: _usernameController,
                      hints: "Username",
                      myIcons: Icons.person,
                      keyboardType: TextInputType.text,
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "EMAIL",
                    style: TextStyle(
                      color: Color(0XFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FormField(
                    theController: _emailController,
                    hints: 'Email',
                    myIcons: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PASSWORD",
                        style: TextStyle(
                          color: Color(0XFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FormField(
                        theController: _passwordController,
                        hints: "*********",
                        myIcons: Icons.lock_outline,
                        obscure: _obscurePassword,
                        helperText: isLogin ? null : _passwordRequirements(),
                        onToggleObscure: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      if (isLogin) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _sendPasswordReset,
                            child: const Text(
                              "Forgot password?",
                              style: TextStyle(color: Color(0xFF378ADD)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF378ADD),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isLogin ? "Sign in" : "Create Account",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFF2A3150))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "or continue with",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFF2A3150))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final GoogleSignInAccount googleUser =
                              await GoogleSignIn.instance.authenticate();

                          final GoogleSignInAuthentication googleAuth =
                              googleUser.authentication;

                          final AuthCredential credential =
                              GoogleAuthProvider.credential(
                                idToken: googleAuth.idToken,
                              );
                          final userCred = await _auth.signInWithCredential(
                            credential,
                          );
                          final bool isNewUser =
                              userCred.additionalUserInfo?.isNewUser ?? false;

                          if (!context.mounted) return;

                          if (isNewUser) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('is_first_launch', true);

                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AuthGate.id,
                              (route) => false,
                            );
                          } else {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AuthGate.id,
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Google sign in failed: $e"),
                            ),
                          );
                        }
                      },
                      icon: Image.asset('images/noback.png', height: 20),
                      label: const Text(
                        "Continue with Google",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0XFF2A3150)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      const Text(
                        "By continuing, you agree to the",
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openLegalLink(_termsUrl),
                        child: const Text(
                          "Terms & Conditions",
                          style: TextStyle(
                            color: Color(0xFF378ADD),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        "and",
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openLegalLink(_privacyPolicyUrl),
                        child: const Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: Color(0xFF378ADD),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        ".",
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FormField extends StatelessWidget {
  const FormField({
    super.key,
    required this.theController,
    required this.hints,
    required this.myIcons,
    this.keyboardType,
    this.obscure = false,
    this.helperText,
    this.onToggleObscure,
  });

  final TextEditingController theController;
  final String hints;
  final IconData myIcons;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? helperText;
  final VoidCallback? onToggleObscure;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          obscureText: obscure,
          keyboardType: keyboardType,
          controller: theController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A2035),
            hintText: hints,
            prefixIcon: Icon(myIcons, color: const Color(0xFF6B7280)),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0XFF4B5563),
                    ),
                  ),
            hintStyle: const TextStyle(color: Color(0XFF4B5563)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF378ADD),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 8),
          Text(
            helperText!,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ],
    );
  }
}
