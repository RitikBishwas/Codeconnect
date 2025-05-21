import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nitd_code/ui/pallete.dart';
import 'contest_problem_list_page.dart';

class AdminContestListPage extends StatelessWidget {
  const AdminContestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final contestRef = FirebaseFirestore.instance.collection('contests');

    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        title: const Text("Manage Contests"),
        backgroundColor: Pallete.backgroundColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: contestRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final contests = snapshot.data!.docs;

          if (contests.isEmpty) {
            return const Center(
              child: Text("No contests available.", style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index];
              final data = contest.data() as Map<String, dynamic>;

              final title = data['name'] ?? 'Untitled';
              final duration = data['duration']?.toString() ?? '';
              final startDate = data['startTime'] != null
                  ? (data['startTime'] as Timestamp).toDate()
                  : null;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(30, 30, 40, 1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Pallete.borderColor),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (startDate != null)
                          Text(
                            "Start: ${startDate.toLocal().toString().substring(0, 16)}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        if (duration.isNotEmpty)
                          Text(
                            "Duration: $duration minutes",
                            style: const TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContestProblemListPage(contestId: contest.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Pallete.gradient2,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Manage", style: TextStyle(color: Colors.white)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
