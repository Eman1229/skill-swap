import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_swap/Ui_helper/Ui_helper.dart';
import 'package:skill_swap/screens/reset/Reset Password.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skill_swap/Ui_helper/translation_helper.dart';
// ─────────────────────────────────────────────────────────────────────────────
//  STEP 1 — Email Entry Screen
// ─────────────────────────────────────────────────────────────────────────────
class EmailVerificationScreen extends StatefulWidget {
  final String? email;
  EmailVerificationScreen({Key? key, this.email}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late final TextEditingController emailController;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.email);
  }
  Future<void> _sendEmailOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': 'service_arqfv3m',       // ✅ Paste your Service ID
          'template_id': 'template_2i05gk8',     // ✅ Paste your Template ID
          'user_id': 'cbyedSBUQfq84tNqX',          // ✅ Paste your Public Key
          'template_params': {
            'to_email': email,
            'otp': otp,
          },
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('EmailJS Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Email send failed: $e');
    }
  }

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
      final String otp = (100000 + Random().nextInt(900000)).toString();

      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(email)
          .set({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: 10)),
        ),
        'used': false,
      });

      await _sendEmailOtp(email, otp);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OtpVerificationScreen(email: email, otp: otp),
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          Icons.lock_reset_rounded,
                          size: 46,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 28),
                      Text(
                        'forgot_password_title'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'enter_email_otp'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 36),
                      UiHelper.CustomTextField(context: context,
                        controller: emailController,
                        text: 'enter_your_email'.tr(),
                        tohide: false,
                        textinputtype: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline,
                      ),
                      SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            disabledBackgroundColor:
                            Theme.of(context).colorScheme.primary.withAlpha(102),
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
                            'send_otp'.tr(),
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

// ─────────────────────────────────────────────────────────────────────────────
//  STEP 2 — OTP Verification Screen
// ─────────────────────────────────────────────────────────────────────────────
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String otp;

  OtpVerificationScreen({
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

  String get _enteredOtp => _controllers.map((c) => c.text).join();

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

      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(widget.email)
          .update({'used': true});

      if (!mounted) return;

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
  Future<void> _sendEmailOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': 'service_arqfv3m',       // ✅ Same values as before
          'template_id': 'template_2i05gk8',
          'user_id': 'cbyedSBUQfq84tNqX',
          'template_params': {
            'to_email': email,
            'otp': otp,
          },
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('EmailJS Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Email send failed: $e');
    }
  }
  Future<void> resendOtp() async {
    setState(() => loading = true);
    try {
      final String newOtp = (100000 + Random().nextInt(900000)).toString();

      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(widget.email)
          .set({
        'otp': newOtp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: 10)),
        ),
        'used': false,
      });

      await _sendEmailOtp(widget.email, newOtp);
      _snack('A new OTP has been sent to ${widget.email}',
          color: Colors.green);

      for (final c in _controllers) {
        c.clear();
      }
      if (mounted) FocusScope.of(context).requestFocus(_focusNodes[0]);
    } catch (e) {
      _snack('Failed to resend OTP. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(String msg, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
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
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
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
                          Icons.mark_email_read_rounded,
                          size: 46,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: 28),
                      Text(
                        'verify_otp_title'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '${'enter_otp_sent'.tr()}\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 36),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, _buildOtpBox),
                      ),
                      SizedBox(height: 14),
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
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
                            ),
                            SizedBox(width: 6),
                            Text(
                              _otpVisible ? 'hide_otp'.tr() : 'show_otp'.tr(),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            disabledBackgroundColor:
                            Theme.of(context).colorScheme.primary.withOpacity(0.4),
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
                            'verify_otp'.tr(),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "didnt_receive_otp".tr(),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: loading ? null : resendOtp,
                            child: Text(
                              'resend'.tr(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
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
