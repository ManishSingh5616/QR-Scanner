import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  final nameController =
  TextEditingController();

  final emailController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  final confirmPasswordController =
  TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await AuthService.instance.registerUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const VerifyEmailScreen(),
        ),
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

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text("Register")),

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

                const SizedBox(height: 30),

                const Icon(
                  Icons.qr_code_2,
                  size: 90,
                  color: Colors.blue,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Create Account",
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
                  nameController,

                  decoration:
                  const InputDecoration(
                    labelText: "Full Name",
                    border:
                    OutlineInputBorder(),
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Enter your name";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

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
                        value.trim().isEmpty) {
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
                    labelText: "Password",

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
                        value.length < 6) {
                      return "Minimum 6 characters";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller:
                  confirmPasswordController,

                  obscureText:
                  obscureConfirm,

                  decoration:
                  InputDecoration(
                    labelText:
                    "Confirm Password",

                    border:
                    const OutlineInputBorder(),

                    suffixIcon:
                    IconButton(
                      onPressed: () {
                        setState(() {
                          obscureConfirm =
                          !obscureConfirm;
                        });
                      },

                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),

                  validator: (value) {
                    if (value !=
                        passwordController.text) {
                      return "Passwords do not match";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 55,

                  child: ElevatedButton(
                    onPressed:
                    loading ? null : register,

                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text(
                      "Create Account",
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    "Already have an account? Login",
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