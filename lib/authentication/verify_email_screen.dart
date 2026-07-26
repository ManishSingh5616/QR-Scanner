import 'dart:async';

import 'package:flutter/material.dart';

import 'auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() =>
      _VerifyEmailScreenState();
}

class _VerifyEmailScreenState
    extends State<VerifyEmailScreen> {

  Timer? timer;

  bool loading = false;

  bool canResend = false;

  @override
  void initState() {
    super.initState();

    startCheckingVerification();

    enableResendButton();
  }

  void enableResendButton() async {
    await Future.delayed(
      const Duration(seconds: 30),
    );

    if (!mounted) return;

    setState(() {
      canResend = true;
    });
  }

  void startCheckingVerification() {
    timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) => checkVerification(),
    );
  }

  Future<void> checkVerification() async {
    await AuthService.instance.reloadUser();

    if (AuthService.instance.isEmailVerified) {
      timer?.cancel();

      await AuthService.instance
          .updateVerificationStatus();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        "/home",
            (route) => false,
      );
    }
  }

  Future<void> resendEmail() async {
    setState(() {
      loading = true;
      canResend = false;
    });

    try {
      await AuthService.instance
          .sendVerificationEmail();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Verification email sent.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }

    await Future.delayed(
      const Duration(seconds: 30),
    );

    if (!mounted) return;

    setState(() {
      loading = false;
      canResend = true;
    });
  }

  Future<void> refreshVerification() async {
    setState(() {
      loading = true;
    });

    await checkVerification();

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> logout() async {
    timer?.cancel();

    await AuthService.instance.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
          (route) => false,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final email =
        AuthService.instance.currentUser?.email ??
            "";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Verify Email",
        ),
        automaticallyImplyLeading: false,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 48,
            ),

         child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.mark_email_read_outlined,
              size: 110,
              color: Colors.blue,
            ),

            const SizedBox(height: 25),

            const Text(
              "Verify your email",
              style: TextStyle(
                fontSize: 28,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              "A verification email has been sent to\n\n$email",

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: loading
                    ? null
                    : refreshVerification,

                icon: const Icon(
                  Icons.refresh,
                ),

                label: const Text(
                  "I've Verified My Email",
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: OutlinedButton.icon(
                onPressed:
                canResend && !loading
                    ? resendEmail
                    : null,

                icon: const Icon(
                  Icons.email_outlined,
                ),

                label: const Text(
                  "Resend Email",
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: TextButton.icon(
                onPressed: logout,

                icon: const Icon(
                  Icons.logout,
                ),

                label: const Text(
                  "Logout",
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "The app automatically checks your verification status every 3 seconds.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
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