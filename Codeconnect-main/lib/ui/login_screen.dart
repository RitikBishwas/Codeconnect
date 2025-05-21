import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nitd_code/pages/home_page.dart';
import 'package:nitd_code/ui/login_field.dart';
import 'package:nitd_code/ui/pallete.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  bool isLoading = false;
  bool isLogin = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _register() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        String uid = user.uid;
        String email = user.email ?? '';
        String name = _nameController.text.trim();
        String year = _yearController.text.trim();

        // Extract starting and end years
        List<String> years = year.split('-');
        String startingYear = years.isNotEmpty ? years[0] : '';
        String endYear = years.length > 1 ? years[1] : '';

        // Save user details in Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'name': name,
          'email': email,
          'year': year,
          'startingYear': startingYear,
          'endYear': endYear,
          'location': "Delhi, India",
          'school': "NIT Delhi",
          'github_url': "https://www.github.com",
          'linkedin_url': "https://www.linkedin.com",
          'contactNumber': "+910123456789",
          'profileImage':
              "https://ui-avatars.com/api/?bold=true&background=fff&color=181820&rounded=true&name=$name&size=128",
          'imagePublicId': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration Successful')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) {
        _showError("An unexpected error occurred. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _login() async {
    setState(() => isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Successful')),
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomePage()));
    } on FirebaseAuthException catch (e) {
      _showError(e.message);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String? errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage ?? 'An error occurred')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Image.asset('assets/images/signin_balls.png'),
              Text(
                isLogin ? 'Sign in' : 'Register',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                  color: Pallete.whiteColor,
                ),
              ),
              const SizedBox(height: 50),
              if (!isLogin) ...[
                LoginField(controller: _nameController, hintText: 'Name'),
                const SizedBox(height: 15),
                LoginField(
                    controller: _yearController,
                    hintText: 'Year (e.g., 2022-2026)'),
                const SizedBox(height: 15),
              ],
              LoginField(controller: _emailController, hintText: 'Email'),
              const SizedBox(height: 15),
              LoginField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Pallete.gradient1,
                            Pallete.gradient2,
                            Pallete.gradient3,
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: ElevatedButton(
                        onPressed: isLogin ? _login : _register,
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(395, 55),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          isLogin ? 'Sign in' : 'Register',
                          style: const TextStyle(
                            color: Color.fromARGB(204, 255, 255, 255),
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(
                  isLogin
                      ? "Don't have an account? Register"
                      : "Already have an account? Login",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _yearController.dispose();
    super.dispose();
  }
}
