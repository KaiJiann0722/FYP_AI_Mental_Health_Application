import 'package:flutter/material.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';
import 'package:flutter_fyp/userAuth_pages/login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String? errorMsg = '';
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPwController = TextEditingController();
  final FocusNode _fnameFocusNode = FocusNode();
  final FocusNode _lnameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPwFocusNode = FocusNode();
  bool isObscured = true;
  final ValueNotifier<bool> _isLoginButtonEnabled = ValueNotifier(false);

  final Color _initBorderColor = const Color.fromARGB(31, 150, 150, 150);
  late Color _emailBorderColor = _initBorderColor;
  late Color _passwordBorderColor = _initBorderColor;
  late Color _fnameBorderColor = _initBorderColor;
  late Color _lnameBorderColor = _initBorderColor;
  late Color _confirmPwBorderColor = _initBorderColor;
  final RegExp _alphaRegExp = RegExp(r'^[a-zA-Z]+$');
  String? _fnameError;
  String? _lnameError;
  String? _confirmPwError;

  Future<void> registerUser() async {
    String? errorMessage = await Auth().createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
      firstName: _fnameController.text,
      lastName: _lnameController.text,
    );

    setState(() {
      errorMsg = errorMessage; // Display error message if there's an error
    });

    if (errorMessage == null) {
      // Registration successful
      // Navigate to the next screen or show success message
      print('Sucessfully store data in firestore');
    }
  }

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
    return const Text('Registration');
  }

  Widget _fnameEntryField(
    String title,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    return Container(
      padding: const EdgeInsets.only(right: 15, left: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _fnameBorderColor,
        border: Border.all(
          color: Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        focusNode: _fnameFocusNode,
        controller: _fnameController,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: title,
          border: InputBorder.none,
          errorText: _fnameError,
        ),
        onChanged: (value) => _validateFname(),
      ),
    );
  }

  Widget _lnameEntryField(
    String title,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    return Container(
      padding: const EdgeInsets.only(right: 15, left: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _lnameBorderColor,
        border: Border.all(
          color: Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        focusNode: _lnameFocusNode,
        controller: _lnameController,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: title,
          border: InputBorder.none,
          errorText: _lnameError,
        ),
        onChanged: (value) => _validateLname(),
      ),
    );
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

  Widget _confirmPwEntryField(
    String title,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    return Container(
      padding: const EdgeInsets.only(right: 15, left: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _confirmPwBorderColor,
        border: Border.all(
          color: Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        focusNode: _confirmPwFocusNode,
        controller: _confirmPwController,
        obscureText: isObscured,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: title,
          border: InputBorder.none, // This removes the underline
          errorText: _confirmPwError,
        ),
      ),
    );
  }

  Widget _registerButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoginButtonEnabled,
      builder: (context, isEnabled, child) {
        return TextButton(
          onPressed: isEnabled
              ? () async {
                  // Reset the error message before validation
                  setState(() {
                    errorMsg = null;
                  });

                  // Run validation and set errorMsg if needed
                  if (!_validateConfirmPassword()) {
                    setState(() {
                      errorMsg = "Passwords do not match.";
                    });
                    return; // Exit early if there's a password confirmation error
                  }

                  if (errorMsg == null) {
                    // Proceed with user registration
                    await registerUser();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Registration successful!"),
                          duration:
                              Duration(seconds: 2), // Duration of the SnackBar
                        ),
                      );
                    }
                  }
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
                  'Create an account',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _loginPageButton() {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'Already have an account? ',
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
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              child: const Text(
                'Login now',
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
    _isLoginButtonEnabled.value = _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _fnameController.text.isNotEmpty &&
        _lnameController.text.isNotEmpty &&
        _confirmPwController.text.isNotEmpty &&
        _validateFname() &&
        _validateLname();
  }

  bool _validateFname() {
    setState(() {
      String fname = _fnameController.text;

      if (fname.length < 4) {
        _fnameError = "First name must be at least 4 characters.";
      } else if (!_alphaRegExp.hasMatch(fname)) {
        _fnameError =
            "First name must contain only alphabetic characters\n(no spaces or numbers).";
      } else {
        _fnameError = null; // Clear error if valid
      }
    });

    return _fnameError == null;
  }

// Validate last name
  bool _validateLname() {
    setState(() {
      String lname = _lnameController.text;

      if (lname.length < 4) {
        _lnameError = "Last name must be at least 4 characters.";
      } else if (!_alphaRegExp.hasMatch(lname)) {
        _lnameError =
            "Last name must contain only alphabetic characters\n(no spaces or numbers).";
      } else {
        _lnameError = null; // Clear error if valid
      }
    });

    return _lnameError == null;
  }

// Validate password confirmation
  bool _validateConfirmPassword() {
    setState(() {
      if (_confirmPwController.text != _passwordController.text) {
        _confirmPwError = "Passwords do not match.";
      } else {
        _confirmPwError = null; // Clear error if valid
      }
    });

    return _confirmPwError == null;
  }

  @override
  void initState() {
    super.initState();

    Color focusedColor = const Color.fromARGB(255, 204, 194, 194);

    // Function to set border color based on the focused field
    void updateBorderColors(FocusNode currentFocusNode) {
      setState(() {
        _fnameBorderColor = currentFocusNode == _fnameFocusNode
            ? focusedColor
            : _initBorderColor;
        _lnameBorderColor = currentFocusNode == _lnameFocusNode
            ? focusedColor
            : _initBorderColor;
        _emailBorderColor = currentFocusNode == _emailFocusNode
            ? focusedColor
            : _initBorderColor;
        _passwordBorderColor = currentFocusNode == _passwordFocusNode
            ? focusedColor
            : _initBorderColor;
        _confirmPwBorderColor = currentFocusNode == _confirmPwFocusNode
            ? focusedColor
            : _initBorderColor;
      });
    }

    // List of focus nodes for each field
    List<FocusNode> focusNodes = [
      _fnameFocusNode,
      _lnameFocusNode,
      _emailFocusNode,
      _passwordFocusNode,
      _confirmPwFocusNode,
    ];

    // Add listener to each focus node
    for (var focusNode in focusNodes) {
      focusNode.addListener(() => updateBorderColors(focusNode));
    }

    _emailController.addListener(_updateLoginButtonState);
    _passwordController.addListener(_updateLoginButtonState);
    _fnameController.addListener(_updateLoginButtonState);
    _lnameController.addListener(_updateLoginButtonState);
    _confirmPwController.addListener(_updateLoginButtonState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fnameController.dispose();
    _lnameController.dispose();
    _confirmPwController.dispose();
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
            const Text(
              'Registration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _fnameEntryField(
                    'First Name',
                    _fnameController,
                    _fnameFocusNode,
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(width: 15),
                Expanded(
                  child: _lnameEntryField(
                    'Last Name',
                    _lnameController,
                    _lnameFocusNode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            _confirmPwEntryField(
              'Re-enter Password',
              _confirmPwController,
              _confirmPwFocusNode,
            ),
            const SizedBox(height: 10),
            if (errorMsg != null && errorMsg!.isNotEmpty)
              Text(
                errorMsg!,
                style: const TextStyle(
                  color: Color.fromARGB(255, 255, 52, 38),
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 20),
            _registerButton(),
            const SizedBox(height: 10),
            _loginPageButton(),
          ],
        ),
      ),
    );
  }
}

// class PopupDialogWidget extends StatelessWidget {
//   final Future<void> Function() onSignIn;

//   const PopupDialogWidget({super.key, required this.onSignIn});

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(50),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(
//                   16.0), // Adjust the padding value as needed
//               child: Text(
//                 'Registered Sucessfully !',
//                 style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
//               ),
//             ),
//             Container(
//               width: double.infinity, // Make the button take the full width
//               decoration: BoxDecoration(
//                 border: Border(
//                   top: BorderSide(
//                     color: Colors.grey, // Change the color as needed
//                     width: 1.0, // Thickness of the border
//                   ),
//                 ),
//               ),
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                     // Add padding or styling if needed
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     backgroundColor: Colors.white
//                     // Adjust vertical padding
//                     // You can add more styles here
//                     ),
//                 onPressed: () async {
//                   await onSignIn(); // Call the function here
//                   if (context.mounted) {
//                     // Check if context is still mounted
//                     Navigator.of(context).pop(); // Close dialog
//                   }
//                 },
//                 child: Text(
//                   'Ok',
//                   style: TextStyle(
//                       color: Colors.black, fontWeight: FontWeight.bold),
//                 ), // Label of the button
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
