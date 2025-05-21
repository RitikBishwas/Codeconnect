import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_existing_problem_page.dart';
import 'contest_problem_create_page.dart';

class ContestProblemListPage extends StatelessWidget {
  final String contestId;

  const ContestProblemListPage({super.key, required this.contestId});

  @override
  Widget build(BuildContext context) {
    final problemsRef = FirebaseFirestore.instance
        .collection('contest_problems')
        .where('contestId', isEqualTo: contestId);

    Color getDifficultyColor(String diff) {
      switch (diff.toLowerCase()) {
        case 'easy':
          return Colors.green;
        case 'medium':
          return Colors.orange;
        case 'hard':
          return Colors.redAccent;
        default:
          return Colors.grey;
      }
    }

    const backgroundColor = Color.fromRGBO(24, 24, 32, 1);
    const cardColor = Color(0xFF2C2C3E);
    const borderColor = Color.fromRGBO(52, 51, 67, 1);
    const gradient1 = Color.fromRGBO(187, 63, 221, 1);
    const gradient2 = Color.fromRGBO(251, 109, 169, 1);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Manage Problems"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Add Existing"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddExistingProblemPage(contestId: contestId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFBB3FDD), // Updated for better contrast
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.create, color: Colors.white),
                  label: const Text("Create New"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateProblemPage(contestId: contestId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB6DA9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: problemsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: gradient2));
                }

                final problems = snapshot.data!.docs;

                if (problems.isEmpty) {
                  return const Center(
                    child: Text(
                      "No problems added yet.",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: problems.length,
                  itemBuilder: (context, index) {
                    final problemDoc = problems[index];
                    final data = problemDoc.data() as Map<String, dynamic>;

                    final problem = data.containsKey('problemData')
                        ? data['problemData']
                        : data;
                    final title = problem['title'] ?? '';
                    final difficulty = problem['difficulty'] ?? 'Unknown';
                    final tags = List<String>.from(problem['tags'] ?? []);
                    final description = problem['description'] ?? '';
                    final preview = description.length > 100
                        ? "${description.substring(0, 100)}..."
                        : description;

                    return GestureDetector(
                      onTap: () {
                        // Optional: Navigate to full problem view if needed
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C3E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color.fromRGBO(52, 51, 67, 1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Title + Delete Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor:
                                            const Color(0xFF2C2C3E),
                                        title: const Text("Delete Problem",
                                            style:
                                                TextStyle(color: Colors.white)),
                                        content: const Text(
                                          "Are you sure you want to delete this problem?",
                                          style:
                                              TextStyle(color: Colors.white70),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text("Cancel",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text("Delete",
                                                style: TextStyle(
                                                    color: Colors.redAccent)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('contest_problems')
                                          .doc(problemDoc.id)
                                          .delete();
                                    }
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            /// Difficulty & Tags
                            Row(
                              children: [
                                Chip(
                                  label: Text(difficulty),
                                  backgroundColor:
                                      getDifficultyColor(difficulty),
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: tags
                                        .map((tag) => Chip(
                                              label: Text(tag),
                                              backgroundColor:
                                                  const Color.fromRGBO(
                                                      187, 63, 221, 0.8),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            /// Description Preview
                            if (description.isNotEmpty)
                              Text(
                                preview,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
