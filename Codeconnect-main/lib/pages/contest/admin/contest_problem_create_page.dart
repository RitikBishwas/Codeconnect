import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nitd_code/ui/pallete.dart';

class CreateProblemPage extends StatefulWidget {
  final String contestId;
  const CreateProblemPage({super.key, required this.contestId});

  @override
  State<CreateProblemPage> createState() => _CreateProblemPageState();
}

class _CreateProblemPageState extends State<CreateProblemPage> {
  final _formKey = GlobalKey<FormState>();
  String title = '', description = '', difficulty = '', constraints = '';
  List<String> tags = [];
  List<Map<String, String>> sampleIO = [];
  List<Map<String, String>> testCases = [];

  final tagController = TextEditingController();
  final sampleInput = TextEditingController();
  final sampleOutput = TextEditingController();
  final testInput = TextEditingController();
  final testOutput = TextEditingController();

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

  void _submitProblem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final problemData = {
        'title': title,
        'description': description,
        'difficulty': difficulty,
        'tags': tags,
        'constraints': constraints,
        'sampleIO': sampleIO,
        'testCases': testCases,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final globalProblemRef =
          await FirebaseFirestore.instance.collection('problems').add(problemData);

      await FirebaseFirestore.instance.collection('contest_problems').add({
        'contestId': widget.contestId,
        'problemId': globalProblemRef.id,
        'title': title,
        'difficulty': difficulty,
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Problem created and added to contest")),
      );
      Navigator.pop(context);
    }
  }

  void _addTag() {
    if (tagController.text.trim().isNotEmpty) {
      setState(() {
        tags.add(tagController.text.trim());
        tagController.clear();
      });
    }
  }

  void _addSampleIO() {
    if (sampleInput.text.isNotEmpty && sampleOutput.text.isNotEmpty) {
      setState(() {
        sampleIO.add({
          'input': sampleInput.text,
          'inputDisplay': sampleInput.text,
          'output': sampleOutput.text,
          'outputDisplay': sampleOutput.text,
        });
        sampleInput.clear();
        sampleOutput.clear();
      });
    }
  }

  void _addTestCase() {
    if (testInput.text.isNotEmpty && testOutput.text.isNotEmpty) {
      setState(() {
        testCases.add({'input': testInput.text, 'output': testOutput.text});
        testInput.clear();
        testOutput.clear();
      });
    }
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                child: const Text(
                  "Create Problem",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(30, 30, 40, 1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Pallete.borderColor),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: _buildInputDecoration("Title"),
                        onSaved: (val) => title = val!,
                        validator: (val) => val!.isEmpty ? "Enter title" : null,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: _buildInputDecoration("Description"),
                        onSaved: (val) => description = val!,
                        validator: (val) => val!.isEmpty ? "Enter description" : null,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: _buildInputDecoration("Difficulty"),
                        onSaved: (val) => difficulty = val!,
                        validator: (val) => val!.isEmpty ? "Enter difficulty" : null,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: _buildInputDecoration("Constraints"),
                        onSaved: (val) => constraints = val!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: tagController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration("Add Tag"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addTag,
                            icon: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            backgroundColor: Pallete.gradient2.withOpacity(0.8),
                            labelStyle: const TextStyle(color: Colors.white),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Sample I/O", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: sampleInput,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration("Input"),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: sampleOutput,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration("Output"),
                      ),
                      const SizedBox(height: 12),

                      // Custom Gradient Button for Sample IO
                      GestureDetector(
                        onTap: _addSampleIO,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Pallete.gradient1, Pallete.gradient2],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              "Add Sample I/O",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Test Cases", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: testInput,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration("Input"),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: testOutput,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration("Output"),
                      ),
                      const SizedBox(height: 12),

                      // Custom Gradient Button for Test Cases
                      GestureDetector(
                        onTap: _addTestCase,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Pallete.gradient2, Pallete.gradient3],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              "Add Test Case",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
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
                          onPressed: _submitProblem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Submit Problem",
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
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
