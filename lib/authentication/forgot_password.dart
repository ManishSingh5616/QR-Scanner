import 'package:flutter/material.dart';

import 'auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final _formKey = GlobalKey<FormState>();

  final emailController =
  TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await AuthService.instance.forgotPassword(
        emailController.text.trim(),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            title: const Text(
              "Email Sent",
            ),

            content: Text(
              "A password reset link has been sent to\n\n${emailController.text.trim()}",
            ),

            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.pop(context);
                },

                child: const Text(
                  "OK",
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                "Exception: ", ""),
          ),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Forgot Password",
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.all(20),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,

              children: [

                const SizedBox(height: 40),

                const Icon(
                  Icons.lock_reset,
                  size: 90,
                  color: Colors.orange,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Reset Password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Enter your registered email address and we'll send you a password reset link.",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                TextFormField(
                  controller:
                  emailController,

                  keyboardType:
                  TextInputType.emailAddress,

                  decoration:
                  const InputDecoration(
                    labelText: "Email",

                    border:
                    OutlineInputBorder(),

                    prefixIcon:
                    Icon(Icons.email),
                  ),

                  validator: (value) {

                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Enter your email";
                    }

                    if (!RegExp(
                        r'^[^@]+@[^@]+\.[^@]+')
                        .hasMatch(value)) {
                      return "Enter a valid email";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 55,

                  child: ElevatedButton(
                    onPressed:
                    loading
                        ? null
                        : resetPassword,

                    child: loading
                        ? const SizedBox(
                      width: 25,
                      height: 25,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    )
                        : const Text(
                      "Send Reset Link",
                    ),
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