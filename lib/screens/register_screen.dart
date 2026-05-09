import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:final_project/widgets/custom_dialogs.dart';
import 'package:final_project/screens/login_screen.dart';
import 'package:final_project/config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController icpepIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool agreedToTerms = false;
  String membership = "non-member";
  String userType = "student";

  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasSpecialChar = false;

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    contactNumberController.dispose();
    icpepIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordCriteria(String value) {
    setState(() {
      _hasLowercase = RegExp(r"[a-z]").hasMatch(value);
      _hasUppercase = RegExp(r"[A-Z]").hasMatch(value);
      _hasSpecialChar = RegExp(r"[^A-Za-z0-9]").hasMatch(value);
    });
  }

  void registerUser() async {
    String firstName = firstNameController.text.trim();
    String middleName = middleNameController.text.trim();
    String lastName = lastNameController.text.trim();

    // Combine into fullName — this is what gets sent to the backend (same as web)
    String fullName = middleName.isNotEmpty
        ? "$firstName $middleName $lastName"
        : "$firstName $lastName";

    String email = emailController.text.trim();
    String contactNumber = contactNumberController.text.trim();
    String icpepId = icpepIdController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        contactNumber.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        (membership == "member" && icpepId.isEmpty) ||
        !agreedToTerms) {

      List<String> missingFields = [];
      if (firstName.isEmpty) missingFields.add('First Name');
      if (lastName.isEmpty) missingFields.add('Last Name');
      if (email.isEmpty) missingFields.add('Email');
      if (contactNumber.isEmpty) missingFields.add('Contact Number');
      if (password.isEmpty) missingFields.add('Password');
      if (confirmPassword.isEmpty) missingFields.add('Confirm Password');
      if (membership == "member" && icpepId.isEmpty) missingFields.add('ICPEP ID');
      if (!agreedToTerms) missingFields.add('Terms and Conditions Agreement');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Required Fields Missing'),
            content: Text('Please fill in all required fields:\n\n${missingFields.join('\n')}'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          );
        },
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Email Format Error'),
            content: const Text('Please enter a valid email address. Check your email format.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          );
        },
      );
      return;
    }

    if (contactNumber.length != 11 || !RegExp(r'^\d{11}$').hasMatch(contactNumber)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Contact Number Error'),
            content: const Text('Contact number must be exactly 11 digits. Please check your phone number.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          );
        },
      );
      return;
    }

    if (!contactNumber.startsWith('0')) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Phone Number Error'),
            content: const Text('Contact number must start with 0. Please check your phone number input.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          );
        },
      );
      return;
    }

    if (password.length < 6) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Password Length Error'),
            content: const Text('Password must be at least 6 characters long. Please make your password longer.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          );
        },
      );
      return;
    }

    final bool meetsStrength =
        RegExp(r"[a-z]").hasMatch(password) &&
        RegExp(r"[A-Z]").hasMatch(password) &&
        RegExp(r"[^A-Za-z0-9]").hasMatch(password);

    if (!meetsStrength) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Password too weak'),
            content: const Text('Password must include at least one number, one lowercase letter, one uppercase letter, and one special character.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          );
        },
      );
      return;
    }

    if (password != confirmPassword) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Password Mismatch Error'),
            content: const Text('Passwords do not match. Please make sure both password fields are identical.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          );
        },
      );
      return;
    }

    try {
      var emailCheckResponse = await http.post(
        Uri.parse(checkEmailExists),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (emailCheckResponse.statusCode == 200) {
        var emailCheckBody = jsonDecode(emailCheckResponse.body);
        if (emailCheckBody['exists'] == true) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Email Already Exists'),
                content: const Text('This email is already associated with an account. Please use a different email address.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                ],
              );
            },
          );
          return;
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Email Check Error'),
              content: const Text('Failed to check email. Please try again.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
              ],
            );
          },
        );
        return;
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Connection Error'),
            content: const Text('An error occurred while checking the email. Please check your internet connection.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          );
        },
      );
      return;
    }

    // Send to backend — only fullName, same as web. No firstName/lastName sent.
    var regBody = {
      "fullName": fullName,
      "contactNumber": contactNumber,
      "email": email,
      "password": password,
      "confirmPassword": confirmPassword,
      "userType": userType,
      "membership": membership,
      "icpepId": membership == "member" ? icpepId : "",
    };

    try {
      var response = await http.post(
        Uri.parse(registration),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regBody),
      );

      if (response.statusCode == 200) {
        CustomDialogs.showSuccessRegisterDialog(
          context,
          "Registration Successful!",
          onConfirmed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        );
      } else {
        var responseBody = jsonDecode(response.body);
        String errorMessage = responseBody['message'] ?? "Registration failed. Please try again.";
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Registration Error'),
              content: Text(errorMessage),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Connection Error'),
            content: const Text('An error occurred. Please check your connection and try again.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
            ],
          );
        },
      );
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms and Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('By using Registra, you agree to the following terms and conditions:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                const Text('1. Account Registration:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• You must provide accurate and complete information during registration\n• You are responsible for maintaining the confidentiality of your account\n'),
                const SizedBox(height: 8),
                const Text('2. Event Registration:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• Event registrations are subject to availability\n'),
                const SizedBox(height: 8),
                const Text('3. Data Privacy:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• We collect and process your personal data for event management\n• Your data is stored securely and used only for app functionality\n• We do not share your personal information with third parties\n'),
                const SizedBox(height: 8),
                const Text('4. User Conduct:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• You agree to use the app for lawful purposes only\n• You will not attempt to gain unauthorized access to the system\n• You will not interfere with the app\'s functionality\n'),
                const SizedBox(height: 8),
                const Text('5. Limitation of Liability:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• Registra is not liable for any damages arising from app use\n• We reserve the right to modify or discontinue services\n• Event organizers are responsible for their own events\n'),
                const SizedBox(height: 8),
                const Text('6. Contact Information:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('For questions about these terms or data privacy, contact us at:\nEmail: support@registra.com\nPhone: +63 969 469 9669'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Text("Sign up", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // First Name (frontend only — combined into fullName before sending)
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  hintText: "First name *",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),

              // Middle Name (optional — frontend only)
              TextField(
                controller: middleNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  hintText: "Middle name (optional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),

              // Last Name (frontend only — combined into fullName before sending)
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  hintText: "Last name *",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: contactNumberController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone),
                  hintText: "Contact number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: userType,
                items: ["student", "professional"].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (String? newValue) => setState(() => userType = newValue!),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.work_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: membership,
                items: ["member", "non-member"].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (String? newValue) => setState(() => membership = newValue!),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),

              if (membership == "member")
                TextField(
                  controller: icpepIdController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge),
                    hintText: "ICPEP ID",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              if (membership == "member") const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "Your password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                  ),
                ),
                onChanged: _updatePasswordCriteria,
              ),
              const SizedBox(height: 15),

              TextField(
                controller: confirmPasswordController,
                obscureText: !isConfirmPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "Confirm password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Builder(
                builder: (context) {
                  final bool allMet = _hasLowercase && _hasUppercase && _hasSpecialChar;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!allMet)
                        const Text('Password too weak', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(_hasLowercase ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: _hasLowercase ? Colors.green : Colors.grey),
                          const SizedBox(width: 8),
                          Text('Contains a lowercase letter (a-z)', style: TextStyle(fontSize: 12, color: _hasLowercase ? Colors.green : Colors.black87, fontWeight: _hasLowercase ? FontWeight.w600 : FontWeight.normal)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(_hasUppercase ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: _hasUppercase ? Colors.green : Colors.grey),
                          const SizedBox(width: 8),
                          Text('Contains an uppercase letter (A-Z)', style: TextStyle(fontSize: 12, color: _hasUppercase ? Colors.green : Colors.black87, fontWeight: _hasUppercase ? FontWeight.w600 : FontWeight.normal)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(_hasSpecialChar ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: _hasSpecialChar ? Colors.green : Colors.grey),
                          const SizedBox(width: 8),
                          Text('Contains a special character (!@#…)', style: TextStyle(fontSize: 12, color: _hasSpecialChar ? Colors.green : Colors.black87, fontWeight: _hasSpecialChar ? FontWeight.w600 : FontWeight.normal)),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: agreedToTerms,
                    onChanged: (bool? value) => setState(() => agreedToTerms = value ?? false),
                    activeColor: Colors.blue,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => agreedToTerms = !agreedToTerms),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: _showTermsAndConditions,
                                child: const Text('Terms and Conditions', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: _showTermsAndConditions,
                                child: const Text('Privacy Policy', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: registerUser,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("SIGN UP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                    child: const Text("Sign in", style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}