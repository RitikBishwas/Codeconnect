import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:nitd_code/models/user_model.dart';
import 'package:nitd_code/secret_manager.dart';
import 'package:nitd_code/ui/pallete.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _schoolController;
  late TextEditingController _yearController;
  late TextEditingController _nameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;
  late TextEditingController _locationController;

  File? _imageFile;
  Uint8List? _webImage;
  bool _isUploading = false;
  String? _uploadedImageUrl;
  bool _isDeleting = false;
  String? _publicId; // Cloudinary public ID for deletion
  bool _isUpdating = false;

  // Pick image for Mobile
  Future<void> _pickImageMobile() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _webImage = null;
      });
    }
  }

  // Pick image for Web
  Future<void> _pickImageWeb() async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*'; // Restrict to images
    uploadInput.click(); // Open file picker

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(files[0]); // Read as bytes

        reader.onLoadEnd.listen((event) {
          setState(() {
            _webImage = reader.result as Uint8List?;
          });
        });
      }
    });
  }

  // Upload to Cloudinary
  Future<void> _uploadImage() async {
    if (_imageFile == null && _webImage == null) return;

    await _deleteImage(); // Delete previous image
    setState(() {
      _isUploading = true;
    });

    String cloudName = SecretsManager().get("CLOUDINARY_CLOUD_NAME") ?? dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? "";
    String uploadPreset = SecretsManager().get("CLOUDINARY_UPLOAD_PRESET") ?? dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? "";
    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var request = http.MultipartRequest("POST", url);
    request.fields['upload_preset'] = uploadPreset;

    // Upload from Mobile
    if (_imageFile != null) {
      request.files
          .add(await http.MultipartFile.fromPath('file', _imageFile!.path));
    }
    // Upload from Web
    else if (_webImage != null) {
      request.files.add(http.MultipartFile.fromBytes('file', _webImage!,
          filename: 'image.jpg'));
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);
      setState(() {
        _uploadedImageUrl = jsonData["secure_url"];
        _publicId = jsonData["public_id"];
      });
      print("Image Uploaded: $_uploadedImageUrl");
    } else {
      print("Failed to upload image: ${response.statusCode}");
    }

    setState(() {
      _isUploading = false;
    });
  }

  /// Delete Image from Cloudinary
  Future<void> _deleteImage() async {
    if (widget.user.imagePublicId == null) return;
    String oldImgPublicId = widget.user.imagePublicId!;

    setState(() {
      _isDeleting = true;
    });

    String cloudName = SecretsManager().get("CLOUDINARY_CLOUD_NAME") ?? dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? "";
    String apiKey = SecretsManager().get("CLOUDINARY_API_KEY") ?? dotenv.env['CLOUDINARY_API_KEY'] ?? "";
    String apiSecret = SecretsManager().get("CLOUDINARY_API_SECRET") ??dotenv.env['CLOUDINARY_API_SECRET'] ?? "";

    // Generate a secure SHA1 signature (API requirement)
    int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String signatureBase =
        "public_id=$oldImgPublicId&timestamp=$timestamp$apiSecret";
    String signature = sha1.convert(utf8.encode(signatureBase)).toString();

    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/destroy");

    final response = await http.post(
      url,
      body: {
        'public_id': oldImgPublicId,
        'api_key': apiKey,
        'timestamp': timestamp.toString(),
        'signature': signature,
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      if (jsonResponse['result'] == 'ok') {
        print("✅ Image Deleted Successfully!");
      } else {
        print("⚠️ Error: ${jsonResponse['result']}");
      }
    } else {
      print("❌ Failed to delete image: ${response.statusCode}");
      print("Response: ${response.body}");
    }

    setState(() {
      _isDeleting = false;
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No authenticated user!");
      setState(() {
        _isUpdating = false;
      });
      return;
    }

    await _uploadImage(); // Upload new image

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String docId = querySnapshot.docs.first.id;

        String startYear = "";
        String endYear = "";
        String year = "";

        void saveData() {
          List<String> years = _yearController.text.split('-');

          if (years.length == 2) {
            startYear = years[0].trim();
            endYear = years[1].trim();
            year = "$startYear-$endYear";
          }
        }

        saveData();

        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'name': _nameController.text.trim(),
          'location': _locationController.text.trim(),
          'school': _schoolController.text.trim(),
          'github_url': _githubController.text.trim(),
          'company': _companyController.text.trim(),
          'linkedin_url': _linkedinController.text.trim(),
          'contactNumber': _contactNumberController.text.trim(),
          'profileImage': _uploadedImageUrl ?? widget.user.profileImage,
          'imagePublicId': _publicId ?? widget.user.imagePublicId,
          'year': year, // Store the combined year range
          'startingYear': startYear, // Store the start year
          'endYear': endYear, // Store the end year
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        final UserModel updatedData = UserModel(
          name: _nameController.text.trim(),
          location: _locationController.text.trim(),
          email: widget.user.email,
          company: _companyController.text.trim(),
          school: _schoolController.text.trim(),
          github_url: _githubController.text.trim(),
          linkedin_url: _linkedinController.text.trim(),
          contactNumber: _contactNumberController.text.trim(),
          profileImage: _uploadedImageUrl ?? widget.user.profileImage,
          imagePublicId: _publicId ?? widget.user.imagePublicId,
          createdAt: widget.user.createdAt,
          year: year, // Store the combined year range
          startingYear: startYear, // Store the start year
          endYear: endYear, // Store the end year
        );
        Navigator.pop(context, updatedData);
      } else {
        print("User not found in Firestore.");
      }
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile!')),
      );
    }
    setState(() {
      _isUpdating = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _yearController = TextEditingController(text: widget.user.year);
    // _yearController = TextEditingController(
    //     text: "${widget.user.startingYear}-${widget.user.endYear}");
    _schoolController = TextEditingController(text: widget.user.school);
    _nameController = TextEditingController(text: widget.user.name);
    _contactNumberController =
        TextEditingController(text: widget.user.contactNumber);
    _companyController = TextEditingController(text: widget.user.company);
    _githubController = TextEditingController(text: widget.user.github_url);
    _linkedinController = TextEditingController(text: widget.user.linkedin_url);
    _locationController = TextEditingController(text: widget.user.location);
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _yearController.dispose();
    _nameController.dispose();
    _companyController.dispose();
    _contactNumberController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor.withOpacity(0.95),
        elevation: 4,
        shadowColor: Pallete.gradient1.withOpacity(0.4),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Pallete.whiteColor),
          onPressed: () => Navigator.pop(context),
          splashRadius: 24,
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              // Pallete.gradient1,
              // Pallete.gradient2,
              // Pallete.gradient3,
              Pallete.whiteColor,
              Pallete.whiteColor
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Pallete.whiteColor, // Masked by shader
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Pallete.gradient1, Pallete.gradient2, Pallete.gradient3],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Pallete.backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Pallete.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Pallete.whiteColor,
                        backgroundImage: _webImage != null
                            ? MemoryImage(_webImage!)
                            : _imageFile != null
                                ? FileImage(_imageFile!) as ImageProvider
                                : NetworkImage(widget.user.profileImage ??
                                    'https://cdn-icons-png.flaticon.com/512/149/149071.png'),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Pallete.gradient2,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Pallete.whiteColor, size: 20),
                          onPressed: kIsWeb ? _pickImageWeb : _pickImageMobile,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField('Name', _nameController),
                          _buildTextField('School/College', _schoolController),
                          _buildTextField(
                              'Year (e.g., 2022-2026)', _yearController),
                          _buildTextField(
                              'Contact Number', _contactNumberController,
                              keyboardType: TextInputType.phone),
                          _buildTextField('Company', _companyController),
                          _buildTextField('Github URL', _githubController),
                          _buildTextField('LinkedIn URL', _linkedinController),
                          _buildTextField('Location', _locationController,
                              keyboardType: TextInputType.streetAddress),
                        ],
                      )),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Pallete.gradient1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        shadowColor: Pallete.borderColor,
                      ),
                      child: _isUpdating
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Update Profile',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Pallete.whiteColor),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Pallete.whiteColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Pallete.whiteColor.withOpacity(0.7)),
          filled: true,
          fillColor: Pallete.backgroundColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Pallete.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Pallete.gradient1),
          ),
        ),
      ),
    );
  }
}
