import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nitd_code/ui/pallete.dart';
import 'package:nitd_code/ui/interview_field.dart';
import 'package:nitd_code/ui/gradient_button.dart';
import 'package:nitd_code/pages/interview_page/ai_interview_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScheduleInterviewPage extends StatefulWidget {
  const ScheduleInterviewPage({super.key});

  @override
  _ScheduleInterviewPageState createState() => _ScheduleInterviewPageState();
}

class _ScheduleInterviewPageState extends State<ScheduleInterviewPage> {
  final TextEditingController _topicsController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _interviewType = 'Technical';
  bool isAIInterview = false;

  // ✅ File for Mobile/Desktop
  File? _selectedFile;

  // ✅ File for Web
  Uint8List? _webFileBytes;

  // ✅ Resume File Name
  String? _resumeFileName;

  // ✅ Schedule Regular or AI Interview
  Future<void> _scheduleInterview() async {
    if (!isAIInterview && (_selectedDate == null || _selectedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time.')),
      );
      return;
    }

    final interviewDateTime = isAIInterview
        ? DateTime.now()
        : DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('interviews').add({
        'intervieweeId': FirebaseAuth.instance.currentUser?.uid,
        'interviewerId': isAIInterview ? 'AI' : 'interviewer-id',
        'dateTime': interviewDateTime.toIso8601String(),
        'questions': [],
        'answers': [],
        'rating': 0.0,
        'feedback': '',
        'type': isAIInterview ? 'AI' : 'Scheduled',
        'status': isAIInterview ? 'completed' : 'pending',
        'isCurrent': isAIInterview, // ✅ Mark as current for AI
        // 'type': _interviewType,
        // 'topics': _topicsController.text.split(','),
        // 'status': 'pending',
      });

      _showSuccessDialog();
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to schedule interview.')),
      );
    }
  }

  // ✅ Start AI Interview and Parse Resume
  void _startAIInterview() async {
    if (_selectedFile != null || _webFileBytes != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIInterviewPage(
                selectedFile: _selectedFile,
                webFileBytes: _webFileBytes,
                isAI: true),
          ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a resume before starting AI Interview.'),
          backgroundColor: Color.fromARGB(255, 205, 201, 201),
        ),
      );
    }
  }

  // ✅ File Upload for Resume (Mobile/Desktop/Web)
  Future<void> _uploadResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'doc'],
    );

    if (result != null) {
      if (kIsWeb) {
        // Web file handling
        setState(() {
          _webFileBytes = result.files.single.bytes!;
          _selectedFile = null;
          _resumeFileName = result.files.single.name;
        });
      } else {
        // Mobile/Desktop file handling
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _webFileBytes = null;
          _resumeFileName = result.files.single.name;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume uploaded successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected.')),
      );
    }
  }

  // ✅ Show Success Dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Pallete.borderColor, Pallete.backgroundColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: SizedBox(
              height: 160,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 70,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Interview Scheduled Successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Reset Form
  void _resetForm() {
    _topicsController.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _interviewType = 'Technical';
      isAIInterview = false;
      _selectedFile = null;
      _webFileBytes = null;
      _resumeFileName = null;
    });
  }

  // ✅ Show Interview Options
  void _showInterviewOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.25,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Pallete.borderColor, Pallete.backgroundColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              _buildHoverTile(
                icon: Icons.event_available,
                title: 'Upcoming Interviews',
                onTap: () {
                  Navigator.pop(context);
                  _showInterviewList('upcoming');
                },
              ),
              const SizedBox(height: 10),
              _buildHoverTile(
                icon: Icons.history,
                title: 'Past Interviews',
                onTap: () {
                  Navigator.pop(context);
                  _showInterviewList('past');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Show Interview List
  void _showInterviewList(String type) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to view interviews')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('interviews')
                .where('intervieweeId', isEqualTo: currentUser.uid)
              .where('status',
                  isEqualTo: type == 'upcoming' ? 'pending' : 'completed')
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error fetching data'));
            }

            final interviews = snapshot.data?.docs ?? [];

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: ListView.builder(
                itemCount: interviews.length,
                itemBuilder: (context, index) {
                  final interview =
                      interviews[index].data() as Map<String, dynamic>;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    color: Pallete.borderColor,
                    child: ListTile(
                      title: Text(
                        'Type: ${interview['type']}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Date: ${interview['date']}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        '${interview['status']}',
                        style: TextStyle(
                          color: interview['status'] == 'pending'
                              ? Colors.orange
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ✅ Build UI
  Widget _buildHoverTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      hoverColor: Colors.transparent, // Disable default hover color
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Pallete.borderColor.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: onTap,
          tileColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Schedule Interview',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Pallete.borderColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showInterviewOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ✅ Interview Type Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInterviewTypeBox('Regular Interview', false),
                  const SizedBox(width: 20),
                  _buildInterviewTypeBox('AI Interview', true),
                ],
              ),
              const SizedBox(height: 20),

              // ✅ Date Picker (For Regular Interview)
              if (!isAIInterview) ...[
                GradientButton(
                  label: _selectedDate == null
                      ? 'Select Date'
                      : 'Date: ${_selectedDate!.day.toString().padLeft(2, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.year}',
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: _selectedTime == null
                      ? 'Select Time'
                      : 'Time: ${_selectedTime!.format(context)}',
                  onPressed: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _selectedTime = pickedTime;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],

              // ✅ Interview Type Dropdown
              Container(
                width: 400,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Pallete.borderColor,
                    width: 2,
                  ),
                ),
                child: DropdownButton<String>(
                  value: _interviewType,
                  dropdownColor: Pallete.backgroundColor,
                  isExpanded: true,
                  items: ['Technical', 'Behavioral', 'Mock']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _interviewType = value!;
                    });
                  },
                  underline: Container(),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Topics Input
              InterviewField(
                controller: _topicsController,
                hintText: 'Topics (comma separated)',
                isMultiline: true,
              ),
              const SizedBox(height: 20),

              // ✅ Show Uploaded File Name if Available
              if (_resumeFileName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Uploaded: $_resumeFileName',
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ),

              // ✅ Upload Resume or Start AI Interview Button
              GradientButton(
                label: isAIInterview
                    ? (_resumeFileName != null
                        ? 'Start AI Interview'
                        : 'Upload Resume')
                    : 'Schedule Interview',
                onPressed: isAIInterview
                    ? (_resumeFileName != null
                        ? _startAIInterview
                        : _uploadResume)
                    : _scheduleInterview,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Interview Type Selection Box
  Widget _buildInterviewTypeBox(String title, bool isAI) {
    bool isSelected = isAIInterview == isAI;
    return GestureDetector(
      onTap: () {
        setState(() {
          isAIInterview = isAI;
        });
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isAI ? Colors.green : Colors.blue)
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: (isAI ? Colors.green : Colors.blue).withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
