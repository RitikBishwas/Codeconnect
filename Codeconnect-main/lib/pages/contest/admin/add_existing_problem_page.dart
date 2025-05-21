import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddExistingProblemPage extends StatefulWidget {
  final String contestId;

  const AddExistingProblemPage({super.key, required this.contestId});

  @override
  State<AddExistingProblemPage> createState() => _AddExistingProblemPageState();
}

class _AddExistingProblemPageState extends State<AddExistingProblemPage> {
  String _searchQuery = '';
  String _selectedDifficulty = 'All';

  void _addProblemToContest(BuildContext context, String problemId, String title, String difficulty) async {
    await FirebaseFirestore.instance.collection('contest_problems').add({
      'contestId': widget.contestId,
      'problemId': problemId,
      'title': title,
      'difficulty': difficulty,
      'addedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Problem added to contest')),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    final title = data['title']?.toString().toLowerCase() ?? '';
    final difficulty = data['difficulty']?.toString().toLowerCase() ?? '';

    final matchesSearch = title.contains(_searchQuery.toLowerCase());
    final matchesDifficulty = _selectedDifficulty == 'All' || difficulty == _selectedDifficulty.toLowerCase();

    return matchesSearch && matchesDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text("Add Existing Problem"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search problems...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2C2C3E),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.pinkAccent),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // 🧩 Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              children: ['All', 'Easy', 'Medium', 'Hard'].map((level) {
                final isSelected = _selectedDifficulty == level;
                return ChoiceChip(
                  label: Text(level),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedDifficulty = level;
                    });
                  },
                  selectedColor: const Color(0xFFBB3FDD),
                  backgroundColor: const Color(0xFF2C2C3E),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // 🧠 Problem List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('problems').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  );
                }

                final problems = snapshot.data!.docs
                    .where((doc) => _matchesFilter(doc.data() as Map<String, dynamic>))
                    .toList();

                if (problems.isEmpty) {
                  return const Center(
                    child: Text(
                      "No problems match your filters.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: problems.length,
                  itemBuilder: (context, index) {
                    final problem = problems[index];
                    final data = problem.data() as Map<String, dynamic>;

                    final problemId = problem.id;
                    final title = data['title'] ?? 'Untitled';
                    final difficulty = data['difficulty'] ?? 'N/A';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C3E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.pinkAccent),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(difficulty),
                            backgroundColor: _getDifficultyColor(difficulty),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text("Add"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBB3FDD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _addProblemToContest(
                                  context, problemId, title, difficulty),
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
    );
  }
}
