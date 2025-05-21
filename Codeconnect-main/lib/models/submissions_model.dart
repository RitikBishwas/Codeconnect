import 'package:cloud_firestore/cloud_firestore.dart';

class Submission {
  final String status;
  final String userId;
  final String language;
  final String problemId;
  final DateTime submissionTime;
  final Map<String, String> code;

  Submission({
    required this.userId,
    required this.problemId,
    required this.status,
    required this.language,
    required this.submissionTime,
    required this.code,
  });

  /// 🔁 Convert Firestore doc to Submission instance
  factory Submission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Submission(
      userId: data['userId'] ?? '',
      problemId: data['problemId'] ?? '',
      status: data['status'] ?? '',
      language: data['language'] ?? '',
      submissionTime: (data['submissionTime'] as Timestamp).toDate(),
      code: Map<String, String>.from(data['code'] ?? {}),
    );
  }

  /// 🔁 Convert Submission to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'problemId': problemId,
      'status': status,
      'language': language,
      'submissionTime': Timestamp.fromDate(submissionTime),
      'code': code,
    };
  }
}
