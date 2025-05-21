import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'contest_create_page.dart';
import 'contest_problem_list_page.dart';

class ContestAdminListPage extends StatefulWidget {
  const ContestAdminListPage({super.key});

  @override
  _ContestAdminListPageState createState() => _ContestAdminListPageState();
}

class _ContestAdminListPageState extends State<ContestAdminListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteContest(String contestId) async {
    await _firestore.collection('contests').doc(contestId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Contest deleted successfully")),
    );
  }

  void _navigateToCreateContest([String? contestId]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContestCreatePage(contestId: contestId),
      ),
    );
  }

  void _navigateToManageProblems(String contestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContestProblemListPage(contestId: contestId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(24, 24, 32, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(24, 24, 32, 1),
        title: const Text(
          "Manage Contests",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Tooltip(
            message: "Add",
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.pinkAccent),
              onPressed: () => _navigateToCreateContest(),
              hoverColor: Colors.pink.withOpacity(0.1),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('contests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            );
          }

          final contests = snapshot.data!.docs;
          if (contests.isEmpty) {
            return const Center(
              child: Text(
                "No contests available.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: contests.length,
            itemBuilder: (context, index) {
              var contest = contests[index];
              final data = contest.data() as Map<String, dynamic>;

              // Safely parse startTime
              final rawStartTime = data['startTime'];
              String formattedStartTime;

              if (rawStartTime is Timestamp) {
                formattedStartTime = rawStartTime
                    .toDate()
                    .toLocal()
                    .toString()
                    .substring(0, 16);
              } else if (rawStartTime is String) {
                final parsed = DateTime.tryParse(rawStartTime);
                formattedStartTime = parsed != null
                    ? parsed.toLocal().toString().substring(0, 16)
                    : "Invalid Date";
              } else {
                formattedStartTime = "No Date";
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(42, 42, 60, 1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color.fromRGBO(251, 109, 169, 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'Untitled Contest',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Starts: $formattedStartTime",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: "Edit",
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                            onPressed: () => _navigateToCreateContest(contest.id),
                            hoverColor: Colors.orangeAccent.withOpacity(0.1),
                          ),
                        ),
                        Tooltip(
                          message: "Delete",
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteContest(contest.id),
                            hoverColor: Colors.redAccent.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromRGBO(187, 63, 221, 1),
                                Color.fromRGBO(251, 109, 169, 1),
                                Color.fromRGBO(255, 159, 124, 1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            onPressed: () => _navigateToManageProblems(contest.id),
                            child: const Text(
                              "Manage Problems",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
