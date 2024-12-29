import 'package:currensee/services/user_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:currensee/common_widgets/custom_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignInEnabled = false;
  bool _isLoading = false;
  String _message = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkFields);
    _passwordController.addListener(_checkFields);
  }

  void _checkFields() {
    final isAllFieldsFilled =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

    setState(() {
      _isSignInEnabled = isAllFieldsFilled;
    });
  }

  Future<void> _login(WidgetRef ref) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _isError = false;
        _message = '';
      });

      try {
        UserCredential userCredential= await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Load user info into Riverpod state
        final userNotifier = ref.read(userProvider.notifier);
        await userNotifier.loadUser(userCredential.user!.uid);

        // Navigate to HomePage on successful login
        Navigator.pushReplacementNamed(context, '/');
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isError = true;
          _message = e.message ?? "An error occurred.";
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Login Page",
                    style: const TextStyle(
                      fontSize: 25.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Welcome Back! We've missed you",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email Address",
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE4E0E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      floatingLabelStyle: TextStyle(color: Colors.grey),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email.";
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Enter a valid email address.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE4E0E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      floatingLabelStyle: TextStyle(color: Colors.grey),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your password.";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_isError)
                    Text(
                      _message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: "Login",
                    width: double.infinity,
                    height: 50,
                    backgroundColor: _isSignInEnabled
                        ? Colors.blue
                        : Colors.blue.withOpacity(0.5),
                    textColor: Colors.white,
                    borderRadius: 8,
                    isEnabled: _isSignInEnabled,
                    isLoading: _isLoading,
                    onPressed: () => _login(ref)
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child:
                    const Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(
                        color: Color(0xff003194)
                      ),),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
