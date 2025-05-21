import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nitd_code/pages/problems_page/solve_problem_page.dart';
import 'package:nitd_code/ui/pallete.dart';

class ProblemsPage extends StatefulWidget {
  final String userId;
  const ProblemsPage({super.key, required this.userId});

  @override
  _ProblemsPageState createState() => _ProblemsPageState();
}

class _ProblemsPageState extends State<ProblemsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedDifficulty = 'All';

  final List<String> _difficultyLevels = ['All', 'Easy', 'Medium', 'Hard'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            bottom: Radius.circular(16),
          ),
        ),
        title: const Text(
          '🧩 Problems',
          style: TextStyle(
            color: Pallete.whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Pallete.backgroundColor,
        child: Column(
          children: [
            // 🔍 Search and Filter Row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // 🔍 Search Field
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      style: const TextStyle(color: Pallete.whiteColor),
                      decoration: InputDecoration(
                        hintText: "Search by name or tag...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon:
                            const Icon(Icons.search, color: Pallete.whiteColor),
                        filled: true,
                        fillColor: Pallete.borderColor.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 🎯 Difficulty Dropdown (Fixed width)
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Pallete.borderColor,
                      iconEnabledColor: Pallete.whiteColor,
                      value: _selectedDifficulty,
                      items: _difficultyLevels.map((level) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(
                            level,
                            style: const TextStyle(color: Pallete.whiteColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Pallete.borderColor.withOpacity(0.5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 📦 Filtered Problems List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('problems').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allProblems = snapshot.data!.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .toList();

                  final filteredProblems = allProblems.where((problem) {
                    final title = (problem['title'] ?? '').toLowerCase();
                    final tags = (problem['tags'] as List<dynamic>?)
                            ?.map((tag) => tag.toString().toLowerCase())
                            .toList() ??
                        [];
                    final difficulty =
                        (problem['difficulty'] ?? '').toLowerCase();

                    final matchesSearch = title.contains(_searchQuery) ||
                        tags.any((tag) => tag.contains(_searchQuery));
                    final matchesDifficulty = _selectedDifficulty == 'All' ||
                        difficulty == _selectedDifficulty.toLowerCase();

                    return matchesSearch && matchesDifficulty;
                  }).toList();

                  if (filteredProblems.isEmpty) {
                    return const Center(
                      child: Text(
                        "No problems found.",
                        style: TextStyle(color: Pallete.whiteColor),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredProblems.length,
                    itemBuilder: (context, index) {
                      final problem = filteredProblems[index];
                      return Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Pallete.borderColor,
                              Color.fromRGBO(30, 30, 45, 1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Pallete.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // 🧠 Problem Title
                            Expanded(
                              flex: 4,
                              child: Text(
                                problem['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Pallete.whiteColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 🟣 Difficulty Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                problem['difficulty'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Pallete.whiteColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 🧪 Solve Button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  colors: [
                                    Pallete.gradient1,
                                    Pallete.gradient2,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SolveProblemPage(
                                          problem: problem,
                                          submissionTime: 'all'),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Solve",
                                  style: TextStyle(
                                    color: Pallete.whiteColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
