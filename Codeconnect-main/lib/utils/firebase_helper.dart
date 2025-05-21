import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  final CollectionReference _reportsCollection =
      FirebaseFirestore.instance.collection('interview_reports');

  // ✅ Save Interview Report to Firestore
  Future<void> saveInterviewReport({
    required List<String> questions,
    required List<String> answers,
    required double rating,
    required String feedback,
  }) async {
    try {
      await _reportsCollection.add({
        'questions': questions,
        'answers': answers,
        'rating': rating,
        'feedback': feedback,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving report: $e');
    }
  }

  // ✅ Fetch All Interview Reports
  Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      QuerySnapshot querySnapshot = await _reportsCollection.get();
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }
}
