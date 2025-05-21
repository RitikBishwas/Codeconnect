import 'package:flutter/material.dart';
import 'contest_problem_list_page.dart'; // Import problem list page

class ContestAdminDetailsPage extends StatelessWidget {
  final String contestId;
  const ContestAdminDetailsPage({super.key, required this.contestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contest Details")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to the Contest Problem List Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContestProblemListPage(contestId: contestId),
                  ),
                );
              },
              child: const Text("Manage Problems"),
            ),
          ],
        ),
      ),
    );
  }
}
