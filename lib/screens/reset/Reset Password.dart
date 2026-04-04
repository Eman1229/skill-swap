import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:skill_swap/screens/Sign in/sign in.dart';

class NewPasswordScreen extends StatefulWidget {

  final String oobCode;

  const NewPasswordScreen({Key? key, required this.oobCode}) : super(key: key);

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool loading = false;

  Future<void> resetPassword() async {

    String password = passwordController.text.trim();
    String confirm = confirmController.text.trim();

    if(password.isEmpty || confirm.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    if(password != confirm){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {

      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: password,
      );

      if (!mounted) return; // ✅ FIXED

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset successful"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
            (route) => false,
      );

    } on FirebaseAuthException catch(e){

      setState(() {
        loading = false; // ✅ FIXED — only stops loading on error
      });

      if (!mounted) return; // ✅ FIXED

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Reset failed")),
      );
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Text(
              "Create New Password",
              style: TextStyle(
                color: Color(0xFF00C2FF),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            UiHelper.CustomTextField(
              controller: passwordController,
              text: "New Password",
              tohide: true,
              textinputtype: TextInputType.text,
              prefixIcon: Icons.lock_outline,
            ),

            const SizedBox(height: 20),

            UiHelper.CustomTextField(
              controller: confirmController,
              text: "Confirm Password",
              tohide: true,
              textinputtype: TextInputType.text,
              prefixIcon: Icons.lock_outline,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: loading ? null : resetPassword,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C2FF),
                ),

                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Reset Password",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              height: 45,
              child: UiHelper.CustomImage(imgurl: "Cl.png"),
            )

          ],
        ),
      ),
    );
  }
}