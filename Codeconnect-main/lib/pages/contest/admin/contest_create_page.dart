import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nitd_code/ui/pallete.dart';

class ContestCreatePage extends StatefulWidget {
  final String? contestId;

  const ContestCreatePage({super.key, this.contestId});

  @override
  _ContestCreatePageState createState() => _ContestCreatePageState();
}

class _ContestCreatePageState extends State<ContestCreatePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  DateTime? selectedDateTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contestId != null) {
      _loadContestDetails();
    }
  }

  void _loadContestDetails() async {
    DocumentSnapshot contestDoc =
        await _firestore.collection('contests').doc(widget.contestId).get();

    if (contestDoc.exists) {
      DateTime start = (contestDoc['startTime'] as Timestamp).toDate();
      DateTime end = (contestDoc['endTime'] as Timestamp).toDate();
      Duration duration = end.difference(start);

      setState(() {
        selectedDateTime = start;
        _nameController.text = contestDoc['name'];
        _descriptionController.text = contestDoc['description'];
        _startTimeController.text = start.toString();
        _durationController.text = duration.inMinutes.toString();
      });
    }
  }

  void _pickDateTime() async {
    DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final combined = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          selectedDateTime = combined;
          _startTimeController.text = combined.toString();
        });
      }
    }
  }

  void _saveContest() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _startTimeController.text.isEmpty ||
        _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final startTime = selectedDateTime!;
      final duration = Duration(minutes: int.parse(_durationController.text));
      final endTime = startTime.add(duration);

      Map<String, dynamic> contestData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'status': 'upcoming',
      };

      if (widget.contestId == null) {
        await _firestore.collection('contests').add(contestData);
      } else {
        await _firestore
            .collection('contests')
            .doc(widget.contestId)
            .update(contestData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.contestId == null
              ? "Contest Created!"
              : "Contest Updated!"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Pallete.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Pallete.gradient2),
        borderRadius: BorderRadius.circular(10),
      ),
      filled: true,
      fillColor: const Color.fromRGBO(36, 36, 45, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        elevation: 0,
        leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
        // toolbarHeight: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important for vertical centering
            children: [
              // Gradient Heading
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [
                      Pallete.gradient1,
                      Pallete.gradient2,
                      Pallete.gradient3,
                    ],
                  ).createShader(bounds);
                },
                child: Text(
                  widget.contestId == null ? "Create Contest" : "Edit Contest",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Form Container
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(30, 30, 40, 1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Pallete.borderColor),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration("Contest Name"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: _buildInputDecoration("Description"),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _startTimeController,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _buildInputDecoration("Start Date & Time"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          _buildInputDecoration("Duration (in minutes)"),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Pallete.gradient1,
                            Pallete.gradient2,
                            Pallete.gradient3,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveContest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Save Contest",
                                style: TextStyle(
                                  color: Pallete.whiteColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
