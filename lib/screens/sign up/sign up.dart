import 'package:flutter/material.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/screens/Home%20Screens/Home%20Screen1.dart';
import 'package:skill_swap/screens/Sign%20in/sign%20in.dart';
import 'package:skill_swap/screens/SkillsChoose/Selecting%20Skills.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class SignUpScreen extends StatefulWidget {
  SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  Future<void> signUpUser() async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("account_created".tr())),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SkillsScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Signup Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
                  height: screenHeight * 0.35,
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
                              "welcome_back".tr(),
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
                    top: screenHeight * 0.28,
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
                          UiHelper.CustomTextField(context: context,
                            controller: _nameController,
                            text: "name".tr(),
                            tohide: false,
                            textinputtype: TextInputType.name,
                            prefixIcon: Icons.person_outline,
                          ),
                          SizedBox(height: 20),
                          UiHelper.CustomTextField(context: context,
                            controller: _phoneController,
                            text: "phone_number".tr(),
                            tohide: false,
                            textinputtype: TextInputType.phone,
                            prefixIcon: Icons.phone_android_outlined,
                          ),
                          SizedBox(height: 20),
                          UiHelper.CustomTextField(context: context,
                            controller: _emailController,
                            text: "mail".tr(),
                            tohide: false,
                            textinputtype: TextInputType.emailAddress,
                            prefixIcon: Icons.mail_outline,
                          ),
                          SizedBox(height: 20),
                          UiHelper.CustomTextField(context: context,
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                "proceed".tr(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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

                // 3. THE GIRL (Layered on top of everything)
                Positioned(
                  top:
                      screenHeight *
                      0.08, // Higher up to overlap the blue and dark sections
                  right: -10, // Slightly off-screen for that natural look
                  bottom: 630,
                  child: SizedBox(
                    height: 280, // Larger size to match the reference image
                    child: UiHelper.CustomImage(imgurl: "skill girl.png"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
