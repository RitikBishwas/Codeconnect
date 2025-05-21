import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/highlight_core.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/python.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nitd_code/models/submissions_model.dart';
import 'package:nitd_code/secret_manager.dart';
import 'dart:convert';
import 'package:nitd_code/ui/pallete.dart';
import 'package:nitd_code/utils/language.dart';

// flutter run -d chrome --web-browser-flag "--disable-web-security"

class SolveProblemPage extends StatefulWidget {
  final Map<String, dynamic> problem;
  final String submissionTime;
  const SolveProblemPage(
      {super.key, required this.problem, required this.submissionTime});

  @override
  _SolveProblemPageState createState() => _SolveProblemPageState();
}

class _SolveProblemPageState extends State<SolveProblemPage>
    with SingleTickerProviderStateMixin {
  String _output = '';
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _expectedOutputController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  String _selectedLanguage = 'C++';
  int _currentIndex = 0;
  bool _executingCode = false;
  final TextEditingController _errorController = TextEditingController();
  final CodeController _codeController = CodeController(
    text: LanguageTemplate.getTemplate('C++').defaultCode,
    // Ensure 'cpp' is imported from 'highlight/languages/cpp.dart'
    language: LanguageTemplate.getTemplate('C++').code,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _inputController.text =
        widget.problem['sampleIO'][0]['input'].replaceAll(r'\n', '\n');
    _expectedOutputController.text =
        widget.problem['sampleIO'][0]['output'].replaceAll(r'\n', '\n');

    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    _tabController.animateTo(index);
  }

  bool compareStrings(String str1, String str2) {
    List<String> lines1 = str1.split('\n');
    List<String> lines2 = str2.split('\n');
    if (lines1.length != lines2.length) {
      print("Strings are not identical. Different number of lines.");
      return false;
    }

    bool areEqual = true;

    for (int i = 0; i < lines1.length; i++) {
      String line1 = lines1[i].trim();
      String line2 = lines2[i].trim();

      if (line1 != line2) {
        print("Difference at line ${i + 1}:");
        print("String 1: $line1");
        print("String 2: $line2");
        areEqual = false;
      }
    }

    if (areEqual) {
      print("Strings are identical.");
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> fetchAPI(
      String code, String input, String expectedOutput, String language) async {
    try {
      final response = await http.post(
        Uri.parse('https://code-verse.onrender.com/api/execute'),
        headers: {
          'Content-Type': 'application/json',
          "x-api-key": SecretsManager().get("Editor_API_Key") ??
              dotenv.env["Editor_API_Key"] ?? "",
        },
        body: jsonEncode({
          'language': language,
          'code': code,
          'input': input,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Fetched Problems: $data');

        List<String> output = data['output'].trim().split('\n');
        int codeExecutionTime = int.parse(output.last.trim());
        String codeOutput = output.sublist(0, output.length - 1).join('\n');
        String status = "failure";

        if (compareStrings(codeOutput.trim(), expectedOutput.trim())) {
          status = "success";
        }
        print("codeExecutionTime: $codeExecutionTime ms");

        return {
          ...data,
          'status': status,
          'codeExecutionTime': codeExecutionTime,
          'output': codeOutput,
        };
      } else {
        print('Error: ${response.statusCode}');
        return {'status': 'error', 'error': 'Failed to fetch API'};
      }
    } catch (e) {
      print("Error: $e");
      return {'status': 'error', 'error': e.toString()};
    }
  }

  Future<void> _runCode(
      String code, String input, String expectedOutput) async {
    if (_executingCode) return; // Prevent multiple submissions
    setState(() {
      _executingCode = true;
    });

    var template = LanguageTemplate.getTemplate(_selectedLanguage);
    var language = template.lang;
    var appendCode = template.appendCode;
    var finalCode = code + appendCode;

    var response = await fetchAPI(finalCode, input, expectedOutput, language);
    _errorController.text = response['error'];

    if (response['status'] == 'success' || response['status'] == 'failure') {
      _output = response['output'];
      if (response['codeExecutionTime'] > 1000) {
        _errorController.text = "Time limit exceeded";
      } else {
        print('Code Output: ${response['output']}');
      }
    } else {
      print('Error: ${response['error']}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error occurred while running code!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _executingCode = false;
    });
  }

  void _submitCode(String code) async {
    if (_executingCode) return; // Prevent multiple submissions
    setState(() {
      _executingCode = true;
    });

    var template = LanguageTemplate.getTemplate(_selectedLanguage);
    var language = template.lang;
    var appendCode = template.appendCode;
    var finalCode = code + appendCode;

    bool isCorrect = true;
    String status = "Accepted";

    for (var testCase in widget.problem['testCases']) {
      String input = (testCase['input'] as String).replaceAll(r'\n', '\n');
      String expectedOutput =
          (testCase['output'] as String).replaceAll(r'\n', '\n');

      var response = await fetchAPI(finalCode, input, expectedOutput, language);
      _errorController.text = response['error'];

      if (response['status'] == 'success' || response['status'] == 'failure') {
        _output = response['output'];
        if (response['codeExecutionTime'] > 1000) {
          _errorController.text = "Time limit exceeded";
          status = "Time limit exceeded";
          isCorrect = false;
          break;
        } else {
          if (response['status'] == 'failure') {
            status = "Wrong answer";
            isCorrect = false;
            break;
          }
          print('Code Output: ${response['output']}');
        }
      } else {
        print('Error: ${response['error']}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error occurred while submitting!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );

        setState(() {
          _executingCode = false;
        });
        return; // Exit if there's an error
      }
    }

    await createSubmission(
        status: status,
        userId: _auth.currentUser!.uid,
        language: template.name,
        problemId: widget.problem['id'],
        submissionTime: DateTime.now(),
        code: {'solve': code, 'main': appendCode});

    if (isCorrect) {
      // Show success notice
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Submission Accepted!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _executingCode = false;
    });
  }

  Future<void> createSubmission({
    required String status,
    required String userId,
    required String language,
    required String problemId,
    required DateTime submissionTime,
    required Map<String, String> code,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('submissions').add({
        'status': status,
        'userId': userId,
        'language': language,
        'problemId': problemId,
        'submissionTime': Timestamp.fromDate(submissionTime),
        'code': code,
      });
      print('Submission added successfully!');
    } catch (e) {
      // print('Error adding submission: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error occurred while submitting!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Pallete.backgroundColor,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Pallete.gradient1,
                Pallete.gradient2,
                Pallete.gradient3,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Pallete.whiteColor, size: 26),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Text(
          widget.problem['title'],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Pallete.whiteColor,
            letterSpacing: 1.2,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Stack(children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildSection("Description", widget.problem['description']),
                (widget.problem['sampleIO'].length > 0
                    ? _buildSampleIO()
                    : const SizedBox()),
                _buildSection("Constraints", widget.problem['constraints']),
                _buildCodeEditor(),

                const SizedBox(width: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 8),
                    _buildTabButton("Run code result", 0),
                    const SizedBox(width: 16),
                    _buildTabButton("Submissions", 1),
                  ],
                ),

                // TabBarView inside a fixed-height container
                Container(
                  constraints:
                      const BoxConstraints(maxHeight: 400, minHeight: 0.0),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCard(
                          widget.problem['sampleIO'][0]['input']
                              .replaceAll(r'\n', '\n'),
                          (_output.isNotEmpty ? _output : "No Output"),
                          widget.problem['sampleIO'][0]['output']
                              .replaceAll(r'\n', '\n')),
                      _buildSubmissions(),
                    ],
                  ),
                ),

                // Error Field (Only show if an error exists)
                _errorController.text.isNotEmpty
                    ? Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildTextField("Error", _errorController,
                              isError: true),
                          const SizedBox(height: 20),
                        ],
                      )
                    : const SizedBox(),

                _buildButtons(),
              ],
            ),
          ),
        ),
        if (_executingCode)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Pallete.gradient1,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Running Code on Test Case...",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Container(
        //   color: Colors.black54,
        //   child: const Center(
        //     child: CircularProgressIndicator(
        //       color: Pallete.gradient1,
        //       strokeWidth: 2.5,
        //     ),
        //   ),
        // ),
      ]),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final bool isSelected = _currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Pallete.gradient1, Pallete.gradient2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Pallete.borderColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Pallete.gradient1.withOpacity(0.3),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                )
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: () => _switchTab(index),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Pallete.whiteColor : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String input, String output, String expectedOutput) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Pallete.borderColor,
        elevation: 6,
        shadowColor: Colors.black26,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Run Code Result:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Pallete.whiteColor.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),

                // Input Field
                _buildTextField("Input", _inputController),
                const SizedBox(height: 12),

                // Output Field
                _buildOutputField("Output", _output),
                const SizedBox(height: 12),

                // Expected Output Field
                _buildTextField("Expected Output", _expectedOutputController),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissions() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Pallete.borderColor,
        elevation: 6,
        shadowColor: Colors.black26,
        child: StreamBuilder<QuerySnapshot>(
          stream: (() {
            final userId = _auth.currentUser!.uid;
            final problemId = widget.problem['id'];
            final submissionTimeFilter =
                widget.submissionTime; // 'all' or ISO string

            var baseQuery = FirebaseFirestore.instance
                .collection('submissions')
                .where('userId', isEqualTo: userId)
                .where('problemId', isEqualTo: problemId);

            if (submissionTimeFilter == 'all') {
              return baseQuery
                  .orderBy('submissionTime', descending: true)
                  .snapshots();
            } else {
              final DateTime parsedDate = DateTime.parse(submissionTimeFilter);
              final Timestamp filterTimestamp = Timestamp.fromDate(parsedDate);
              return baseQuery
                  .where('submissionTime', isGreaterThan: filterTimestamp)
                  .orderBy('submissionTime', descending: true)
                  .snapshots();
            }
          })(),
          // stream: FirebaseFirestore.instance
          //     .collection('submissions')
          //     .where('userId', isEqualTo: _auth.currentUser!.uid)
          //     .where('problemId', isEqualTo: widget.problem['id'])
          //     .orderBy('submissionTime', descending: true)
          //     .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print("Firestore stream error: ${snapshot.error}");
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var submissions = snapshot.data!.docs.map((doc) {
              return Submission(
                userId: doc['userId'],
                problemId: doc['problemId'],
                status: doc['status'],
                language: doc['language'],
                submissionTime: (doc['submissionTime'] as Timestamp).toDate(),
                code: Map<String, String>.from(
                    doc['code']), // ✅ this ensures correct type
              );
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(10),
              child: submissions.isEmpty
                  ? const Center(
                      child: Text(
                        "You do not have any submissions for this problem.",
                        style:
                            TextStyle(color: Pallete.whiteColor, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Pallete.borderColor, width: 2)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text("Time",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Pallete.whiteColor),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text("Status",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Pallete.whiteColor),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text("Language",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Pallete.whiteColor),
                                      textAlign: TextAlign.center)),
                              Expanded(
                                  child: Text("Copy",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Pallete.whiteColor),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: submissions.length,
                            itemBuilder: (context, index) {
                              final submission = submissions[index];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Pallete.gradient1,
                                      Pallete.gradient2,
                                      Pallete.gradient3
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Text(
                                            DateFormat.yMMMd().add_jm().format(
                                                submission.submissionTime),
                                            style: const TextStyle(
                                                color: Pallete.whiteColor),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis)),
                                    Expanded(
                                        child: Text(submission.status,
                                            style: const TextStyle(
                                                color: Pallete.whiteColor),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis)),
                                    Expanded(
                                        child: Text(submission.language,
                                            style: const TextStyle(
                                                color: Pallete.whiteColor),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis)),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: submission.code['solve'] ??
                                                  ''));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Copied to clipboard!")),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Pallete.borderColor,
                                        ),
                                        child: const Text("Copy",
                                            maxLines: 1, // ✅ prevents wrapping
                                            overflow: TextOverflow
                                                .ellipsis, // ✅ handles overflow
                                            style: TextStyle(
                                                color: Pallete.whiteColor)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isError = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: isError ? 8.0 : 4.0, bottom: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: isError
                  ? Colors.redAccent
                  : Pallete.whiteColor.withOpacity(0.85),
            ),
          ),
        ),
        isError
            ? Container(
                width: double.infinity,
                constraints:
                    const BoxConstraints(maxHeight: 150, minHeight: 60),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Pallete.borderColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Text(
                    controller.text.isNotEmpty
                        ? controller.text
                        : "No Errors Found",
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            : TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                scrollPhysics: const BouncingScrollPhysics(),
                style: TextStyle(
                  color: Pallete.whiteColor.withOpacity(0.9),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: "Enter $label...",
                  hintStyle: TextStyle(
                    color: Pallete.whiteColor.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                  filled: true,
                  fillColor: Pallete.borderColor.withOpacity(0.3),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Pallete.whiteColor.withOpacity(0.25),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Pallete.gradient2.withOpacity(0.8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildOutputField(String label, String outputText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            color: Pallete.whiteColor.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
              maxHeight: 80, minWidth: 0.0), // Limits height
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Pallete.backgroundColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Pallete.whiteColor.withOpacity(0.2)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical, // Enables scrolling/
            child: Text(
              outputText.isNotEmpty ? outputText : "No Output",
              style: TextStyle(
                fontSize: 14,
                color: Pallete.whiteColor.withOpacity(0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Pallete.whiteColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          content.replaceAll(r'\n', '\n'),
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildSampleIO() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: (widget.problem['sampleIO'] as List<dynamic>)
          .asMap()
          .entries
          .map<Widget>((entry) {
        int index = entry.key + 1; // Get index
        var example = entry.value; // Get value
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
          decoration: BoxDecoration(
            // color: Pallete.borderColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8),
                child: Text(
                  "Example: $index",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Pallete.whiteColor.withOpacity(0.8),
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "Input: ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: Colors.grey,
                      ),
                    ),
                    TextSpan(
                      text: example['inputDisplay'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "Output: ",
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    TextSpan(
                      text: example['outputDisplay'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCodeEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Code Editor:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Pallete.whiteColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Pallete.borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Pallete.whiteColor.withOpacity(0.5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  dropdownColor: Pallete.backgroundColor,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Pallete.whiteColor.withOpacity(0.9),
                  ),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Pallete.whiteColor),
                  items: LanguageTemplate.getLanguages().map((String language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue == null) return; // Prevent null value

                    var template = LanguageTemplate.getTemplate(newValue);
                    setState(() {
                      _codeController.language = template.code;
                      _codeController.text = template.defaultCode;
                      _selectedLanguage = newValue;
                      _output = '';
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Pallete.borderColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade700),
          ),
          padding: const EdgeInsets.all(10),
          child: CodeTheme(
            data: const CodeThemeData(styles: monokaiSublimeTheme),
            child: CodeField(
              controller: _codeController,
              expands: false,
              maxLines: 25,
              minLines: 10,
              textStyle: TextStyle(
                  fontFamily: 'Fira Code',
                  fontSize: 14,
                  color: Pallete.whiteColor
                      .withOpacity(0.8) // Ensures text is visible
                  ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🚀 Run Button
        ElevatedButton.icon(
          icon:
              const Icon(Icons.play_arrow, color: Pallete.whiteColor, size: 20),
          label: const Text(
            'Run',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Pallete.whiteColor,
            ),
          ),
          onPressed: () => _runCode(
            _codeController.text,
            _inputController.text,
            _expectedOutputController.text,
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: Pallete.gradient2,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: Pallete.gradient2.withOpacity(0.4),
          ),
        ),

        const SizedBox(width: 16),

        // 📤 Submit Button
        ElevatedButton.icon(
          icon: const Icon(Icons.upload, color: Colors.white, size: 20),
          label: const Text(
            'Submit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          onPressed: () => _submitCode(_codeController.text),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: Pallete.gradient1,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: Pallete.gradient1.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
