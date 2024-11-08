import 'package:flutter/material.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';
import 'package:flutter_fyp/userAuth_pages/forgetpw.dart';
import 'package:flutter_fyp/userAuth_pages/register.dart';
import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMsg = '';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool isObscured = true;
  final ValueNotifier<bool> _isLoginButtonEnabled = ValueNotifier(false);

  final Color _initEmailBorderColor = const Color.fromARGB(31, 150, 150, 150);
  final Color _initPasswordBorderColor =
      const Color.fromARGB(31, 150, 150, 150);
  late Color _emailBorderColor = _initEmailBorderColor;
  late Color _passwordBorderColor = _initPasswordBorderColor;

  Future<void> signInWithEmailAndPassword() async {
    String? customErrorMessage = await Auth().signInWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    // Update the error message in the state if there's an error
    setState(() {
      errorMsg = customErrorMessage ??
          ''; // Display error if exists, else empty string
    });
  }

  Widget _title() {
    return const Text('Mental');
  }

  Widget _emailEntryField(
    String title,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    return Container(
      padding: const EdgeInsets.only(right: 15, left: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _emailBorderColor,
        border: Border.all(
          color: Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        focusNode: _emailFocusNode,
        controller: _emailController,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: title,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _passwordEntryField(
    String title,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    return Container(
      padding: const EdgeInsets.only(right: 15, left: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _passwordBorderColor,
        border: Border.all(
          color: Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        focusNode: _passwordFocusNode,
        controller: _passwordController,
        obscureText: isObscured,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              isObscured ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[800],
            ),
            onPressed: () {
              setState(() {
                isObscured = !isObscured; // Toggle password visibility
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _loginButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoginButtonEnabled,
      builder: (context, isEnabled, child) {
        return TextButton(
          onPressed: isEnabled
              ? () async {
                  await signInWithEmailAndPassword();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isEnabled ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Sign In',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _forgetPwButton() {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'Forget Password? ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click, // Changes cursor to click
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ForgetPwPage()),
                );
              },
              child: const Text(
                'Click Here',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerButton() {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'Not a member? ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click, // Changes cursor to click
            child: GestureDetector(
              onTap: () {
                Route route =
                    MaterialPageRoute(builder: (context) => RegisterPage());
                Navigator.pushReplacement(context, route);
              },
              child: const Text(
                'Register now',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateLoginButtonState() {
    // Enable button only if both fields are not empty
    _isLoginButtonEnabled.value =
        _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    Color focusedColor = const Color.fromARGB(255, 204, 194, 194);

    // Add focus listeners to change border color
    _emailFocusNode.addListener(() {
      setState(() {
        if (_emailFocusNode.hasFocus) {
          _emailBorderColor = focusedColor; // Color when focused
          _passwordBorderColor =
              _initPasswordBorderColor; // Default color when focus is lost
        }
      });
    });

    _passwordFocusNode.addListener(() {
      setState(() {
        if (_passwordFocusNode.hasFocus) {
          _passwordBorderColor = focusedColor; // Color when focused
          _emailBorderColor =
              _initEmailBorderColor; // Default color when focus is lost
        }
      });
    });

    _emailController.addListener(_updateLoginButtonState);
    _passwordController.addListener(_updateLoginButtonState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _isLoginButtonEnabled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      resizeToAvoidBottomInset: false,
      body: Container(
        padding: const EdgeInsets.only(right: 30, left: 30, top: 0, bottom: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
              radius: 60,
              backgroundColor: Colors.black,
            ),
            const SizedBox(height: 20),
            const Text(
              'Login',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
            const SizedBox(height: 40),
            _emailEntryField(
              'Email',
              _emailController,
              _emailFocusNode,
            ),
            const SizedBox(height: 20),
            _passwordEntryField(
              'Password',
              _passwordController,
              _passwordFocusNode,
            ),
            const SizedBox(height: 10),
            if (errorMsg!.isNotEmpty)
              Text(
                errorMsg!,
                style: const TextStyle(
                  color: Color.fromARGB(255, 255, 52, 38),
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 20),
            _forgetPwButton(),
            const SizedBox(height: 30),
            _loginButton(),
            _registerButton(),
          ],
        ),
      ),
    );
  }
}
