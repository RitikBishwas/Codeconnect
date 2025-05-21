import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'contest_problem_create_page.dart';

class ManageProblemsPage extends StatefulWidget {
  final String contestId;

  const ManageProblemsPage({super.key, required this.contestId});

  @override
  State<ManageProblemsPage> createState() => _ManageProblemsPageState();
}

class _ManageProblemsPageState extends State<ManageProblemsPage> {
  final Set<String> _selectedProblems = {};

  void _toggleSelection(String problemId) {
    setState(() {
      if (_selectedProblems.contains(problemId)) {
        _selectedProblems.remove(problemId);
      } else {
        _selectedProblems.add(problemId);
      }
    });
  }

  void _addSelectedProblemsToContest() async {
    for (String problemId in _selectedProblems) {
      await FirebaseFirestore.instance.collection('contest_problems').add({
        'contestId': widget.contestId,
        'problemId': problemId,
        'addedAt': Timestamp.now(),
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Problems added to contest')),
    );
    setState(() {
      _selectedProblems.clear();
    });
  }

  void _navigateToCreateProblem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProblemPage(contestId: widget.contestId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color.fromRGBO(24, 24, 32, 1);
    const cardColor = Color.fromRGBO(42, 42, 60, 1);
    const gradient1 = Color.fromRGBO(187, 63, 221, 1);
    const gradient2 = Color.fromRGBO(251, 109, 169, 1);
    const gradient3 = Color.fromRGBO(255, 159, 124, 1);
    const borderColor = Color.fromRGBO(52, 51, 67, 1);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Manage Problems"),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('problems').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                }

                final problems = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: problems.length,
                  itemBuilder: (context, index) {
                    final problem = problems[index];
                    final problemId = problem.id;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: CheckboxListTile(
                        title: Text(problem['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text("Difficulty: ${problem['difficulty']}", style: TextStyle(color: Colors.grey.shade400)),
                        value: _selectedProblems.contains(problemId),
                        onChanged: (_) => _toggleSelection(problemId),
                        activeColor: Colors.pinkAccent,
                        checkColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Add Selected Button with Gradient Background
                _selectedProblems.isNotEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [gradient1, gradient2, gradient3]),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Add Selected"),
                          onPressed: _addSelectedProblemsToContest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Add Selected"),
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                // Create New Button with Gradient Background
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [gradient1, gradient2, gradient3]),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.create),
                    label: const Text("Create New"),
                    onPressed: _navigateToCreateProblem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
