import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  NewPasswordScreen({Key? key, required this.email}) : super(key: key);

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
        await Future.delayed(Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
        return;
      }

      // CASE 2: User is logged out -> Send security link (MANDATORY in Firebase)
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);

      if (!mounted) return;

      _snack('Identity verified! A final secure link is in your inbox.', color: Colors.green);

      await Future.delayed(Duration(seconds: 3));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25),
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
                          color: Theme.of(context).colorScheme.primary.withAlpha(31),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLoggedIn ? Icons.lock_open_rounded : Icons.verified_user_rounded,
                          size: 46,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 28),
                      Text(
                        isLoggedIn ? 'create_new_password'.tr() : 'identity_verified'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        isLoggedIn
                            ? 'set_new_password'.tr()
                            : 'otp_verified'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 36),

                      if (isLoggedIn) ...[
                        UiHelper.CustomTextField(context: context,
                          controller: passwordController,
                          text: 'new_password'.tr(),
                          tohide: !showPassword,
                          textinputtype: TextInputType.text,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword ? Icons.visibility : Icons.visibility_off,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () => setState(() => showPassword = !showPassword),
                          ),
                        ),
                        SizedBox(height: 22),
                        UiHelper.CustomTextField(context: context,
                          controller: confirmController,
                          text: 'confirm_password'.tr(),
                          tohide: !showConfirm,
                          textinputtype: TextInputType.text,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConfirm ? Icons.visibility : Icons.visibility_off,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () => setState(() => showConfirm = !showConfirm),
                          ),
                        ),
                        SizedBox(height: 36),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            disabledBackgroundColor: Theme.of(context).colorScheme.primary.withAlpha(102),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onSurface,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text(
                            isLoggedIn ? 'update_password'.tr() : 'send_security_link'.tr(),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
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
              padding: EdgeInsets.only(bottom: 24),
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
