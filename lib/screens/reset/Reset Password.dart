import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool loading = false;
  bool showPassword = false;
  bool showConfirm = false;

  Future<void> resetPassword() async {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final String password = passwordController.text.trim();
    final String confirm = confirmController.text.trim();

    if (isLoggedIn) {
      if (password.isEmpty || confirm.isEmpty) {
        _snack('Please fill in all fields');
        return;
      }
      if (password.length < 6) {
        _snack('Password must be at least 6 characters');
        return;
      }
      if (password != confirm) {
        _snack('Passwords do not match');
        return;
      }
    }

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // CASE 1: User is logged in -> Update password directly
      if (user != null) {
        await user.updatePassword(password);
        _snack('Password changed successfully!', color: Colors.green);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
        return;
      }

      // CASE 2: User is logged out -> Send security link (MANDATORY in Firebase)
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);

      if (!mounted) return;

      _snack('Identity verified! A final secure link is in your inbox.', color: Colors.green);

      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      if (e.code == 'requires-recent-login') {
        _snack('For security, please log out and log back in before changing password.');
      } else {
        _snack(e.message ?? 'Update failed');
      }
    }
  }

  void _snack(String msg, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color)
    );
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C2FF).withAlpha(31),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLoggedIn ? Icons.lock_open_rounded : Icons.verified_user_rounded,
                          size: 46,
                          color: const Color(0xFF00C2FF),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        isLoggedIn ? 'Create New Password' : 'Identity Verified',
                        style: const TextStyle(
                          color: Color(0xFF00C2FF),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isLoggedIn
                            ? 'Set your new secure password below.'
                            : 'OTP verified. For maximum security, we will now send a final reset link to your email.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),

                      if (isLoggedIn) ...[
                        UiHelper.CustomTextField(
                          controller: passwordController,
                          text: 'New Password',
                          tohide: !showPassword,
                          textinputtype: TextInputType.text,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => setState(() => showPassword = !showPassword),
                          ),
                        ),
                        const SizedBox(height: 22),
                        UiHelper.CustomTextField(
                          controller: confirmController,
                          text: 'Confirm Password',
                          tohide: !showConfirm,
                          textinputtype: TextInputType.text,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConfirm ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => setState(() => showConfirm = !showConfirm),
                          ),
                        ),
                        const SizedBox(height: 36),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C2FF),
                            disabledBackgroundColor: const Color(0xFF00C2FF).withAlpha(102),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text(
                            isLoggedIn ? 'Update Password' : 'Send Security Link',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(
                height: 45,
                child: UiHelper.CustomImage(imgurl: 'Cl.png'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
