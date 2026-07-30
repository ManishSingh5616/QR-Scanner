import 'package:flutter/material.dart';
import 'auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String name;
  final String email;
  final String password;

  const VerifyEmailScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final TextEditingController otpController = TextEditingController();
  bool loading = false;
  bool canResend = true;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> verifyOtpAndRegister() async {
    if (otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 6-digit OTP.")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 1. Verify OTP locally using the email_otp package
      bool isValid = AuthService.instance.verifyOtp(otp: otpController.text);

      if (!isValid) {
        throw Exception("Invalid OTP code. Please try again.");
      }

      // 2. Save user to Firebase and Firestore ONLY after successful verification
      await AuthService.instance.completeRegistrationAfterOtp(
        name: widget.name,
        email: widget.email,
        password: widget.password,
      );

      if (!mounted) return;

      // 3. Navigate straight to Home screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        "/home",
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
          ),
        ),
      );
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> resendOtp() async {
    setState(() => canResend = false);

    try {
      await AuthService.instance.sendOtp(email: widget.email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New OTP code sent to your email.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }

    await Future.delayed(const Duration(seconds: 30));
    if (!mounted) return;
    setState(() => canResend = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Email OTP"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 120,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 110,
                  color: Colors.blue,
                ),
                const SizedBox(height: 25),
                const Text(
                  "Verify Your Email",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "A 6-digit verification code has been sent to\n\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: const InputDecoration(
                    labelText: "6-Digit OTP",
                    border: OutlineInputBorder(),
                    counterText: "",
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: loading ? null : verifyOtpAndRegister,
                    child: loading
                        ? const SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                        : const Text(
                      "Verify & Create Account",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: canResend && !loading ? resendOtp : null,
                    icon: const Icon(Icons.email_outlined),
                    label: const Text("Resend OTP"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}