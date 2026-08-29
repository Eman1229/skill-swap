import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:skill_swap/ui_helper/ui_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/SkillsChoose/Selecting%20Skills.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:skill_swap/screens/Home%20Screens/Home%20Screen1.dart';
import 'package:skill_swap/services/google_auth_service.dart';
import 'package:skill_swap/widgets/google_sign_in_button.dart';

class SignUpScreen extends StatefulWidget {
  SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isGoogleLoading = false;

  String _completePhoneNumber = "";

  Future<void> signUpUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update Firebase Auth Display Name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(_nameController.text.trim());
        await userCredential.user!.reload();
      }

      // Save user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _completePhoneNumber.isNotEmpty ? _completePhoneNumber : _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("account_created".tr())),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SkillsScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Signup Failed")));
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      final result = await GoogleAuthService().signIn();
      if (!mounted || result == null) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => result.isNewUser ? const SkillsScreen() : HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted || e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Google sign-in failed. Please try again.')),
      );
    } on GoogleAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to sign in with Google. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. TOP GRADIENT SECTION
                Container(
                  height: screenHeight * 0.4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Color(0xFF6B8AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 80,
                        left: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UiHelper.CustomImage(imgurl: "hi.png"),
                            SizedBox(height: 10),
                            Text(
                              "Welcome".tr(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Floating Lesson Bubbles
                      Positioned(
                        top: 90,
                        right: 80,
                        child: SizedBox(
                          height: 140,
                          child: UiHelper.CustomImage(imgurl: "messages.png"),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. DARK FORM SECTION (The "Sliding Up" Layer)
                Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.32,
                  ), // This creates the perfect overlap
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 25.0,
                        vertical: 30,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SizedBox(height: 10),
                            Text(
                              "sign_up".tr(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "create_account_here".tr(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 40),

                            // TextFields
                            UiHelper.CustomTextField(
                              context: context,
                              controller: _nameController,
                              text: "name".tr(),
                              tohide: false,
                              textinputtype: TextInputType.name,
                              prefixIcon: Icons.person_outline,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? "required_field".tr()
                                  : null,
                            ),
                            SizedBox(height: 20),
                            UiHelper.CustomTextField(
                              context: context,
                              controller: _emailController,
                              text: "mail".tr(),
                              tohide: false,
                              textinputtype: TextInputType.emailAddress,
                              prefixIcon: Icons.mail_outline,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return "required_field".tr();
                                }
                                final emailRegex =
                                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                if (!emailRegex.hasMatch(v.trim())) {
                                  return "invalid_email".tr();
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: 343,
                              child: IntlPhoneField(
                                controller: _phoneController,
                                initialCountryCode: 'PK',
                                dropdownIconPosition: IconPosition.trailing,
                                flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 8),
                                showCountryFlag: true,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: "phone_number".tr(),
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outlineVariant,
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outlineVariant,
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFF3B3B), width: 1.0),
                                  ),
                                  focusedErrorBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
                                  ),
                                ),
                                onChanged: (phone) {
                                  _completePhoneNumber = phone.completeNumber;
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            UiHelper.CustomTextField(
                              context: context,
                              controller: _passwordController,
                              text: "passwords".tr(),
                              tohide: _isPasswordHidden,
                              textinputtype: TextInputType.text,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordHidden
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordHidden = !_isPasswordHidden;
                                  });
                                },
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return "required_field".tr();
                                }
                                if (v.trim().length < 6) {
                                  return "password_too_short".tr();
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 40),

                            // Proceed Button
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  signUpUser();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                child: Text('proceed'.tr(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            GoogleSignInButton(
                              onPressed: _signInWithGoogle,
                              isLoading: _isGoogleLoading,
                            ),

                            SizedBox(height: 25),

                            // Sign In Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "already_member".tr(),
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    "sign_in".tr(),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 40),

                            // THE LOGO (Fixed Visibility)
                            UiHelper.CustomImage(imgurl: "Cl.png"),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. THE GIRL (Layered on top of everything)
                Positioned(
                  top:
                  screenHeight *
                      0.08, // Higher up to overlap the blue and dark sections
                  right: -10, // Slightly off-screen for that natural look
                  child: SizedBox(
                    height: 280, // Larger size to match the reference image
                    child: UiHelper.CustomImage(imgurl: "skill girl.png"),
                  ),
                ),
              ],
            ),
            // Manually add space for keyboard
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
