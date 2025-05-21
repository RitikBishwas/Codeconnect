import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Make sure this is imported
import 'package:nitd_code/pages/problems_page/solve_problem_page.dart';

class ContestDetailsPage extends StatefulWidget {
  final String contestId;
  final String userId;

  const ContestDetailsPage({
    super.key,
    required this.contestId,
    required this.userId,
  });

  @override
  State<ContestDetailsPage> createState() => _ContestDetailsPageState();
}

class _ContestDetailsPageState extends State<ContestDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _timer;
  Duration? _remainingTime;
  String _status = 'loading';
  late DateTime _startTime;
  late DateTime _endTime;
  List<QueryDocumentSnapshot> _problems = [];
  Set<String> _solvedProblemIds = {}; // Changed to Set for quick lookup
    final Set<String> _expandedProblems = {};

    final Color backgroundColor = const Color.fromRGBO(24, 24, 32, 1);
  final Color cardColor = const Color.fromRGBO(36, 36, 50, 1);
  final Color borderColor = const Color.fromRGBO(52, 51, 67, 1);
  final List<Color> gradientColors = [
    const Color.fromRGBO(187, 63, 221, 1),
    const Color.fromRGBO(251, 109, 169, 1),
    const Color.fromRGBO(255, 159, 124, 1),
  ];
  

  @override
  void initState() {
    super.initState();
    _fetchContestDetails();
    _startCountdownUpdater();
    _fetchProblems();
  }

  void _fetchContestDetails() async {
    DocumentSnapshot snapshot =
        await _firestore.collection('contests').doc(widget.contestId).get();
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

    _startTime = (data['startTime'] as Timestamp).toDate();
    _endTime = (data['endTime'] as Timestamp).toDate();

    _updateStatusAndTimer();
  }

  void _fetchProblems() async {
    QuerySnapshot snapshot = await _firestore
        .collection('contest_problems')
        .where('contestId', isEqualTo: widget.contestId)
        .get();

    setState(() {
      _problems = snapshot.docs;
    });
    _fetchSolvedProblems(); // Fetch solved problems after getting the list
  }

  void _fetchSolvedProblems() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final problemIds = _problems
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['problemId'] as String?;
        })
        .whereType<String>()
        .toList();
    if (problemIds.isEmpty) return;

    final Timestamp submissionTimeFilter = Timestamp.fromDate(_startTime);
    final submissionsSnapshot = await FirebaseFirestore.instance
        .collection('submissions')
        .where('userId', isEqualTo: userId)
        .where('problemId', whereIn: problemIds)
        .where('submissionTime', isGreaterThan: submissionTimeFilter)
        .where('status', isEqualTo: 'Accepted')
        .get();

    setState(() {
      _solvedProblemIds = submissionsSnapshot.docs
          .map((doc) => doc['problemId'] as String)
          .toSet();
    });
  }

  void _startCountdownUpdater() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStatusAndTimer();
    });
  }

  void _updateStatusAndTimer() {
    final now = DateTime.now();
    setState(() {
      if (now.isBefore(_startTime)) {
        _status = 'upcoming';
        _remainingTime = _startTime.difference(now);
      } else if (now.isAfter(_endTime)) {
        _status = 'ended';
        _remainingTime = Duration.zero;
      } else {
        _status = 'ongoing';
        _remainingTime = _endTime.difference(now);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildSectionTitle(String text) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(colors: gradientColors).createShader(bounds);
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('contests').doc(widget.contestId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme:
                const IconThemeData(color: Colors.white), // Back button color
            title: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: [
                    Color.fromRGBO(187, 63, 221, 1),
                    Color.fromRGBO(251, 109, 169, 1),
                    Color.fromRGBO(255, 159, 124, 1),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                "Contest Details",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(colors: gradientColors)
                        .createShader(bounds);
                  },
                  child: Text(
                    data['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data['description'] ?? 'No description available.',
                  style: const TextStyle(
                      fontSize: 15, color: Colors.white70, height: 1.4),
                ),
                const Divider(height: 32, color: Colors.white24),
                Row(
                  children: [
                    const Icon(Icons.play_arrow,
                        color: Colors.greenAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Start: ${_startTime.toLocal().toString().substring(0, 16)}",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.stop, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "End:   ${_endTime.toLocal().toString().substring(0, 16)}",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text("Status: ",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(
                      _status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        color: _status == 'upcoming'
                            ? Colors.orange
                            : _status == 'ongoing'
                                ? Colors.green
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_status != 'ended') ...[
                  const Text("⏱ Time Remaining:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(
                    _formatDuration(_remainingTime!),
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ],
                const SizedBox(height: 24),
                _buildSectionTitle("Instructions"),
                const SizedBox(height: 12),
                _buildBullet("One user submitting with multiple accounts during a contest."),
                _buildBullet("All problems are algorithmic.Multiple accounts submitting similar code for the same problem."),
                _buildBullet("No plagiarism is allowed.Submit before time ends."),
                _buildBullet("Creating unwanted disturbances which interrupt other users' participation in a contest."),
                _buildBullet("Disclosing contest solutions in public discuss posts before the end of a contest."),
                _buildBullet("The use of code generation tools or any external assistance for solving problems is strictly prohibited."),
                _buildBullet("This includes, but is not limited to, actions such as inputting problem statements, test cases, or solution code into external assistance tools."),
                const SizedBox(height: 28),
                if (_status == 'ongoing') ...[
                  _buildSectionTitle("Available Problems"),
                  const SizedBox(height: 12),
                  ..._problems.map((problemDoc) {
                    final data = problemDoc.data();
                    if (data == null || data is! Map<String, dynamic>)
                      return const SizedBox.shrink();

                    final problemId = data['problemId'];
                    final title = data['title'];
                    final difficulty = data['difficulty'];
                    final isSolved = _solvedProblemIds.contains(problemId);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSolved ? Colors.green[400] : cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListTile(
                        title: Text(
                          title ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          isSolved
                              ? "Accepted ✅"
                              : "Difficulty: ${difficulty ?? 'N/A'}",
                          style: TextStyle(
                              color: isSolved ? Colors.white : Colors.white70),
                        ),
                        onTap: () async {
                          try {
                            final problemSnapshot = await _firestore
                                .collection('problems')
                                .doc(problemId)
                                .get();
                            if (!problemSnapshot.exists) return;

                            final fullProblemData = problemSnapshot.data();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SolveProblemPage(
                                  problem: fullProblemData!,
                                  submissionTime: _startTime.toIso8601String(),
                                  // contestId: widget.contestId,
                                  // isContestMode: true,
                                  
                                ),
                              ),
                            ).then((_) => _fetchSolvedProblems());
                          } catch (e) {
                            print("❌ Error opening problem: $e");
                          }
                        },
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
