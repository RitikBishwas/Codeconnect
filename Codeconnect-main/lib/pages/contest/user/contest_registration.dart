import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContestRegistrationPage extends StatefulWidget {
  final String contestId;
  final String userId;

  const ContestRegistrationPage({super.key, required this.contestId, required this.userId});

  @override
  _ContestRegistrationPageState createState() => _ContestRegistrationPageState();
}

class _ContestRegistrationPageState extends State<ContestRegistrationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser() async {
    await _firestore.collection('contest_registrations').add({
      'userId': widget.userId,
      'contestId': widget.contestId,
      'registeredAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Registration Successful!'),
    ));

    Navigator.pop(context); // Go back after registration
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register for Contest')),
      body: Center(
        child: ElevatedButton(
          onPressed: registerUser,
          child: const Text('Register'),
        ),
      ),
    );
  }
}
