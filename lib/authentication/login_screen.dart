import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {

  final _formKey = GlobalKey<FormState>();

  final emailController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await AuthService.instance.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      await AuthService.instance.reloadUser();

      if (!mounted) return;

      if (AuthService.instance.isEmailVerified) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/home",
              (route) => false,
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
            const VerifyEmailScreen(),
          ),
        );
      }
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
        title: const Text("Login"),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
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
                  Icons.qr_code_2,
                  size: 90,
                  color: Colors.green,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                    FontWeight.bold,
                  ),
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
                  ),

                  validator: (value) {

                    if (value == null ||
                        value.isEmpty) {
                      return "Enter email";
                    }

                    if (!RegExp(
                        r'^[^@]+@[^@]+\.[^@]+')
                        .hasMatch(value)) {
                      return "Invalid email";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller:
                  passwordController,

                  obscureText:
                  obscurePassword,

                  decoration:
                  InputDecoration(
                    labelText:
                    "Password",

                    border:
                    const OutlineInputBorder(),

                    suffixIcon:
                    IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword =
                          !obscurePassword;
                        });
                      },

                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),

                  validator: (value) {

                    if (value == null ||
                        value.isEmpty) {
                      return "Enter password";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 10),

                Align(
                  alignment:
                  Alignment.centerRight,

                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const ForgotPasswordScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      "Forgot Password?",
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  height: 55,

                  child: ElevatedButton(
                    onPressed:
                    loading ? null : login,

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
                      "Login",
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [

                    const Text(
                      "Don't have an account?",
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const RegisterScreen(),
                          ),
                        );
                      },

                      child: const Text(
                        "Register",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}