import 'package:flutter/material.dart';
import 'package:flutter_fyp/userAuth_pages/auth.dart';

class ForgetPwPage extends StatefulWidget {
  const ForgetPwPage({super.key});
  @override
  State<ForgetPwPage> createState() => _ForgetPwPageState();
}

class _ForgetPwPageState extends State<ForgetPwPage> {
  String? errorMsg = '';
  final _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  final Color _initEmailBorderColor = const Color.fromARGB(31, 150, 150, 150);
  late Color _emailBorderColor = _initEmailBorderColor;
  final ValueNotifier<bool> _isSubmitButtonEnabled = ValueNotifier(false);

  Future<void> sendPasswordResetEmail() async {
    String? customErrorMessage =
        await Auth().sendPasswordResetEmail(email: _emailController.text);
    setState(() {
      errorMsg = customErrorMessage ?? '';
    });
  }

  Widget _title() {
    return const Text('Forget PW');
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

  Widget _submitButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isSubmitButtonEnabled,
      builder: (context, isEnabled, child) {
        return TextButton(
          onPressed: isEnabled
              ? () async {
                  // Reset error message before calling the function
                  setState(() {
                    errorMsg = null;
                  });

                  await sendPasswordResetEmail();

                  // Check if the widget is still mounted
                  if (!mounted) return;

                  // Show success dialog if no error message is set
                  if (errorMsg == '') {
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => const PopupDialogWidget(),
                      );
                    }
                  } else {
                    // Handle the error, showing the specific error message
                    if (context.mounted) {
                      // Ensure the widget is still mounted before showing SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMsg!),
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
                  'Reset Password',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateSubmitButtonState() {
    _isSubmitButtonEnabled.value = _emailController.text.isNotEmpty;
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
        }
      });
    });

    _emailController.addListener(_updateSubmitButtonState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _isSubmitButtonEnabled.dispose();
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
              'Reset Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
            const SizedBox(height: 20),
            Container(
              alignment: Alignment.topLeft,
              child: Text(
                'No Worries ! \nEnter your email to reset your password.',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
            ),
            const SizedBox(height: 40),
            _emailEntryField(
              'Email',
              _emailController,
              _emailFocusNode,
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
            _submitButton(),
          ],
        ),
      ),
    );
  }
}

class PopupDialogWidget extends StatelessWidget {
  const PopupDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(
                  16.0), // Adjust the padding value as needed
              child: Text(
                'A password reset link has been sent to your email. \n\nPlease check your inbox to reset your password.',
                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
              ),
            ),
            Container(
              width: double.infinity, // Make the button take the full width
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey, // Change the color as needed
                    width: 1.0, // Thickness of the border
                  ),
                ),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    // Add padding or styling if needed
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white
                    // Adjust vertical padding
                    // You can add more styles here
                    ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                },
                child: Text(
                  'Ok',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ), // Label of the button
              ),
            ),
          ],
        ),
      ),
    );
  }
}
