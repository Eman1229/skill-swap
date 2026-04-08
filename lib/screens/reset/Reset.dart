import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:skill_swap/screens/reset/Reset Password.dart';
import 'package:skill_swap/screens/Sign in/sign in.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  STEP 1 — Email Entry Screen (generates & stores OTP, navigates to verify)
// ─────────────────────────────────────────────────────────────────────────────
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController emailController = TextEditingController();
  bool loading = false;

  /// Generates a 6-digit OTP, stores it in Firestore under `password_resets/`,
  /// and navigates to the OTP verification screen.
  Future<void> sendOtp() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _snack('Please enter your email address');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _snack('Please enter a valid email address');
      return;
    }

    setState(() => loading = true);

    try {
      // Generate 6-digit OTP
      final String otp =
          (100000 + Random().nextInt(900000)).toString();

      // Save OTP to Firestore (expires in 10 minutes)
      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(email)
          .set({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
        'used': false,

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      setState(() {
        emailSent = true;
        loading = false;
      });

      // Show OTP in snackbar (in production, send via email service / Cloud Function)
      // For development: OTP is shown in the UI below & also printed to console.
      debugPrint('🔑 OTP for $email: $otp');

      if (!mounted) return;

      // Navigate to OTP verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(email: email, otp: otp),
        ),
      );
    } on FirebaseException catch (e) {
      _snack('Error: ${e.message ?? 'Something went wrong'}');
    } catch (e) {
      _snack('Unexpected error. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(String msg, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
    } on FirebaseAuthException catch(e){
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Error sending email")),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      // Icon / illustration
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C2FF).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 46,
                          color: Color(0xFF00C2FF),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF00C2FF),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Enter your registered email address.\nWe will send a 6-digit OTP to verify your identity.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 36),

                      UiHelper.CustomTextField(
                        controller: emailController,
                        text: 'Enter your email',
                        tohide: false,
                        textinputtype: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline,
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C2FF),
                            disabledBackgroundColor:
                                const Color(0xFF00C2FF).withOpacity(0.4),
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
                              : const Text(
                                  'Send OTP',
                                  style: TextStyle(
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

            // Bottom logo
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

// ─────────────────────────────────────────────────────────────────────────────
//  STEP 2 — OTP Verification Screen
// ─────────────────────────────────────────────────────────────────────────────
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String otp; // passed for dev/demo; in prod compare from Firestore only

  const OtpVerificationScreen({
    Key? key,
    required this.email,
    required this.otp,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool loading = false;
  bool _otpVisible = false;

  String get _enteredOtp =>
      _controllers.map((c) => c.text).join();

  Future<void> verifyOtp() async {
    if (_enteredOtp.length < 6) {
      _snack('Please enter the complete 6-digit OTP');
      return;
    }

    setState(() => loading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(widget.email)
          .get();

      if (!doc.exists) {
        _snack('OTP expired or invalid. Please request a new one.');
        setState(() => loading = false);
        return;
      }

      final data = doc.data()!;
      final String storedOtp = data['otp'] ?? '';
      final bool used = data['used'] ?? false;
      final Timestamp expiresAt = data['expiresAt'];

      if (used) {
        _snack('This OTP has already been used. Please request a new one.');
        setState(() => loading = false);
        return;
      }

      if (DateTime.now().isAfter(expiresAt.toDate())) {
        _snack('OTP has expired. Please request a new one.');
        setState(() => loading = false);
        return;
      }

      if (_enteredOtp != storedOtp) {
        _snack('Incorrect OTP. Please try again.');
        setState(() => loading = false);
        return;
      }

      // Mark OTP as used
      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(widget.email)
          .update({'used': true});

      if (!mounted) return;

      // Navigate to reset password
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NewPasswordScreen(email: widget.email),
        ),
      );
    } on FirebaseException catch (e) {
      _snack('Error: ${e.message ?? 'Verification failed'}');
    } catch (e) {
      _snack('Unexpected error. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resendOtp() async {
    setState(() => loading = true);
    try {
      final String newOtp =
          (100000 + Random().nextInt(900000)).toString();

      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(widget.email)
          .set({
        'otp': newOtp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
        'used': false,
      });

      debugPrint('🔑 Resent OTP for ${widget.email}: $newOtp');

      _snack('A new OTP has been sent to ${widget.email}',
          color: Colors.green);

      // Clear existing input
      for (final c in _controllers) {
        c.clear();
      }
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    } catch (e) {
      _snack('Failed to resend OTP. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(String msg, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 58,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        obscureText: !_otpVisible,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF00C2FF), width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      // Icon
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C2FF).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          size: 46,
                          color: Color(0xFF00C2FF),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Verify OTP',
                        style: TextStyle(
                          color: Color(0xFF00C2FF),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Enter the 6-digit OTP sent to\n${widget.email}',
                    // ✅ Show email field only if email not sent yet
                    if(!emailSent) ...[

                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Enter your email",
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : sendResetEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C2FF),
                          ),
                          child: loading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Send Reset Link"),
                        ),
                      ),

                    ],

                    // ✅ Show instructions + button after email is sent
                    if(emailSent) ...[

                      const Icon(
                        Icons.mark_email_read_outlined,
                        color: Color(0xFF00C2FF),
                        size: 80,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Email Sent!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Step 1: Open your email\nStep 2: Click the reset link\nStep 3: Reset your password in the browser\nStep 4: Come back and press the button below",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 2,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // OTP boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, _buildOtpBox),
                      ),

                      const SizedBox(height: 14),

                      // Show / Hide OTP toggle
                      GestureDetector(
                        onTap: () =>
                            setState(() => _otpVisible = !_otpVisible),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              _otpVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 18,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _otpVisible ? 'Hide OTP' : 'Show OTP',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C2FF),
                            disabledBackgroundColor:
                                const Color(0xFF00C2FF).withOpacity(0.4),
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
                              : const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Resend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Didn't receive OTP?  ",
                            style:
                                TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: loading ? null : resendOtp,
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                color: Color(0xFF00C2FF),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom logo
                      const SizedBox(height: 30),

                      // This button takes user to SignIn after resetting in browser
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                                  (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "I've Reset My Password → Sign In",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    ],

                  ],
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