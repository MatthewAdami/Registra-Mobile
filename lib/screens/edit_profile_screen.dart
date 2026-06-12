import 'dart:io';
import 'package:final_project/config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class EditProfileScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String userType;
  final String contactNumber;
  final String icpepId;
  final String aboutMe;
  final String profileImage;

  const EditProfileScreen({
    super.key,
    required this.fullName,
    required this.email,
    required this.userType,
    required this.contactNumber,
    required this.icpepId,
    required this.aboutMe,
    required this.profileImage,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController middleNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController aboutMeController;
  String? phoneError;

  XFile? _image;
  String? profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  /// Splits a stored full name (e.g. "Juan dela Cruz" or "Juan M. dela Cruz")
  /// into first, middle, and last parts as best as possible.
  Map<String, String> _splitFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty) {
      return {'first': '', 'middle': '', 'last': ''};
    } else if (parts.length == 1) {
      return {'first': parts[0], 'middle': '', 'last': ''};
    } else if (parts.length == 2) {
      return {'first': parts[0], 'middle': '', 'last': parts[1]};
    } else {
      // first = first word, last = last word, middle = everything in between
      final first = parts.first;
      final last = parts.last;
      final middle = parts.sublist(1, parts.length - 1).join(' ');
      return {'first': first, 'middle': middle, 'last': last};
    }
  }

  @override
  void initState() {
    super.initState();

    final nameParts = _splitFullName(widget.fullName);
    firstNameController = TextEditingController(text: nameParts['first']);
    middleNameController = TextEditingController(text: nameParts['middle']);
    lastNameController = TextEditingController(text: nameParts['last']);

    phoneNumberController = TextEditingController(text: widget.contactNumber);
    aboutMeController = TextEditingController(text: widget.aboutMe);
    profileImageUrl = widget.profileImage;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    phoneNumberController.dispose();
    aboutMeController.dispose();
    super.dispose();
  }

  /// Combines the three name fields into a single full name string.
  String get _combinedFullName {
    final first = firstNameController.text.trim();
    final middle = middleNameController.text.trim();
    final last = lastNameController.text.trim();

    if (middle.isEmpty) {
      return '$first $last'.trim();
    }
    return '$first $middle $last'.trim();
  }

  Future<void> _uploadProfileImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            backgroundColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Uploading image..."),
                ],
              ),
            ),
          );
        },
      );

      // Wait for 5 seconds before uploading
      await Future.delayed(const Duration(seconds: 5));

      // Upload image to Cloudinary
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/dqbnc38or/image/upload'),
        );

        request.fields['upload_preset'] = 'event_preset';
        request.files
            .add(await http.MultipartFile.fromPath('file', _image!.path));

        var response = await request.send();

        Navigator.pop(context); // Close the loading dialog

        if (response.statusCode == 200) {
          var responseData = await response.stream.toBytes();
          var result = jsonDecode(String.fromCharCodes(responseData));

          setState(() {
            profileImageUrl = result['secure_url'];
          });
        } else {
          _showErrorSnackbar("Failed to upload image");
        }
      } catch (e) {
        Navigator.pop(context);
        _showErrorSnackbar("Error uploading image");
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> updateProfile() async {
    // Validate required name fields
    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('First name and last name are required.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(update),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'fullName': _combinedFullName,
          'contactNumber': phoneNumberController.text.trim(),
          'aboutMe': aboutMeController.text.trim(),
          'profileImage': profileImageUrl,
        }),
      );

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullName', _combinedFullName);
        await prefs.setString(
            'contactNumber', phoneNumberController.text.trim());
        await prefs.setString('aboutMe', aboutMeController.text.trim());
        await prefs.setString('profileImage', profileImageUrl ?? '');

        _showSuccessDialog();

        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pushNamedAndRemoveUntil(
              context, '/navbar', (route) => false);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 40),
                SizedBox(height: 16),
                Text(
                  'Profile updated successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Profile Image ──────────────────────────────────────────────
            GestureDetector(
              onTap: _uploadProfileImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImageUrl != null &&
                        profileImageUrl!.isNotEmpty
                    ? NetworkImage(profileImageUrl!)
                    : const NetworkImage('https://via.placeholder.com/150'),
                child: const Icon(Icons.camera_alt,
                    size: 30, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),

            // ── First Name ─────────────────────────────────────────────────
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name *',
                border: OutlineInputBorder(),
                filled: true,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // ── Middle Name (optional) ─────────────────────────────────────
            TextField(
              controller: middleNameController,
              decoration: const InputDecoration(
                labelText: 'Middle Name (Optional)',
                border: OutlineInputBorder(),
                filled: true,
                hintText: 'Leave blank if none',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // ── Last Name ──────────────────────────────────────────────────
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name *',
                border: OutlineInputBorder(),
                filled: true,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // ── Read-only fields ───────────────────────────────────────────
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: widget.userType,
                hintText: widget.userType,
                border: const OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: widget.email,
                hintText: widget.email,
                border: const OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: widget.icpepId,
                hintText: widget.icpepId,
                border: const OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            // ── Phone Number ───────────────────────────────────────────────
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: const OutlineInputBorder(),
                filled: true,
                hintText: '09XXXXXXXXX',
                errorText: phoneError,
              ),
              keyboardType: TextInputType.phone,
              maxLength: 11,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                setState(() {
                  phoneError = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // ── About Me ───────────────────────────────────────────────────
            TextField(
              controller: aboutMeController,
              decoration: const InputDecoration(
                labelText: 'About Me',
                border: OutlineInputBorder(),
                filled: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ── Update Button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Update',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),

            // ── Reset Password Button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/edit_resetpassword');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  side: const BorderSide(color: Colors.red),
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}