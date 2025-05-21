import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nitd_code/models/interview_report.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewReportsPage extends StatelessWidget {
  final List<DocumentSnapshot> interviews;
const ViewReportsPage({Key? key, required this.interviews}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser!.uid;  // Get current user's UID

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white, // 🎨 Change the color here
        ),
        title: const Text(
          'Interview Reports',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        color: Colors.black,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')  // User-specific collection
              .doc(uid)  // Filter by current user's UID
              .collection('interviews')  // Subcollection for interviews
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No reports available.',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              );
            }

            List<InterviewReport> reports = snapshot.data!.docs.map((doc) {
              return InterviewReport.fromMap(
                  doc.data() as Map<String, dynamic>);
            }).toList();

            return ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                InterviewReport report = reports[index];
                return _buildReportCard(report);
              },
            );
          },
        ),
      ),
    );
  }

  // 🔥 Build Report Card with Hover & Expansion Effect
  Widget _buildReportCard(InterviewReport report) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        bool isExpanded = false;

        return MouseRegion(
          onEnter: (_) => setState(() {
            isHovered = true;
          }),
          onExit: (_) => setState(() {
            isHovered = false;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: isHovered
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFA933FF), // Purple-Pink
                        Color(0xFFFF8C6B), // Peach-Orange
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isHovered ? null : Colors.black54,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: const Color(0xFFA933FF).withOpacity(0.6),
                        spreadRadius: 2,
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              iconColor: Colors.white,
              backgroundColor: isExpanded ? Colors.black87 : Colors.black54,
              onExpansionChanged: (value) {
                setState(() => isExpanded = value);
              },
              title: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Interview on ${report.dateTime.split(' ')[0]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              subtitle: Row(
                children: [
                  _buildRatingStars(report.rating),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Feedback: ${report.feedback.isEmpty ? "No Feedback" : report.feedback}',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              children: [
                _buildFeedbackCard(report),
                _buildQuestionsAndAnswers(report),
              ],
            ),
          ),
        );
      },
    );
  }

  // ⭐ Build Star Rating
  Widget _buildRatingStars(double rating) {
    return Row(
      children: [
        const Text(
          'Rating Given: ', // Added label here
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, index) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          itemCount: 5,
          itemSize: 18,
          direction: Axis.horizontal,
        ),
      ],
    );
  }

  // 📝 Build Feedback Card
  Widget _buildFeedbackCard(InterviewReport report) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFA933FF), // Purple-Pink
              Color(0xFFFF8C6B), // Peach-Orange
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white70, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.feedback, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                report.feedback.isEmpty
                    ? 'No feedback provided.'
                    : 'Feedback: ${report.feedback}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📚 Build Questions & Answers Section
  Widget _buildQuestionsAndAnswers(InterviewReport report) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          report.questions.isNotEmpty ? report.questions.length : 0,
          (index) {
            String answer =
                (report.answers.isNotEmpty && index < report.answers.length)
                    ? report.answers[index]
                    : "No answer provided"; // Updated fallback text

            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '❓ Q${index + 1}: ${report.questions[index]}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '💬 A: $answer',
                    style: const TextStyle(
                      color: Colors.white70,
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
}
