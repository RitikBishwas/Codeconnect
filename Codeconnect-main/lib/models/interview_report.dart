class InterviewReport {
  final String dateTime;
  final List<String> questions;
  final List<String> answers;
  double rating; // ✅ Added rating
  String feedback; // ✅ Added feedback
  final String type; // ✅ Add type

  InterviewReport({
    required this.dateTime,
    required this.questions,
    required this.answers,
    required this.rating, // ✅ Initialize rating
    required this.feedback, // ✅ Initialize feedback
    required this.type, // ✅ Initialize type
  });

  Map<String, dynamic> toMap() {
    return {
      'dateTime': dateTime,
      'questions': questions,
      'answers': answers,
      'rating': rating,
      'feedback': feedback,
      'type': type, // ✅ Add type
    };
  }

  // ✅ Convert Map to InterviewReport object
  factory InterviewReport.fromMap(Map<String, dynamic> map) {
    return InterviewReport(
      dateTime: map['dateTime'] ?? '', // Provide a default value
      questions:
          map['questions'] != null ? List<String>.from(map['questions']) : [],
      answers: map['answers'] != null ? List<String>.from(map['answers']) : [],
      rating: (map['rating'] ?? 0.0).toDouble(),
      feedback: map['feedback'] ?? 'No feedback provided',
      type: map['type'] ?? 'Scheduled', // ✅ Added type with default value
    );
  }
}
