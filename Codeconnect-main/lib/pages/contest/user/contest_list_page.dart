import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'contest_details_page.dart';
import 'package:nitd_code/ui/pallete.dart';

class ContestListPage extends StatefulWidget {
  final String userId;
  const ContestListPage({super.key, required this.userId});

  @override
  State<ContestListPage> createState() => _ContestListPageState();
}

class _ContestListPageState extends State<ContestListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String getStatus(dynamic start, dynamic end) {
    final now = DateTime.now();
    DateTime startTime = (start is Timestamp)
        ? start.toDate()
        : DateTime.tryParse(start ?? '') ?? DateTime(2000);
    DateTime endTime = (end is Timestamp)
        ? end.toDate()
        : DateTime.tryParse(end ?? '') ?? DateTime(2000);

    if (now.isBefore(startTime)) return 'upcoming';
    if (now.isAfter(endTime)) return 'ended';
    return 'ongoing';
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toString();
    } else if (value is String) {
      try {
        return DateTime.parse(value).toString();
      } catch (e) {
        return 'Invalid date';
      }
    } else {
      return 'Invalid date';
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.orangeAccent;
      case 'ongoing':
        return Colors.greenAccent;
      case 'ended':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Pallete.gradient1,
              Pallete.gradient2,
              Pallete.gradient3,
            ],
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: const Text(
            "Available Contests",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream:
            _firestore.collection('contests').orderBy('startTime').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No available contests.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          var contestDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: contestDocs.length,
            itemBuilder: (context, index) {
              var contest = contestDocs[index];
              return _buildContestCard(contest);
            },
          );
        },
      ),
    );
  }

  Widget _buildContestCard(QueryDocumentSnapshot contest) {
    Map<String, dynamic> data = contest.data() as Map<String, dynamic>;
    var start = data['startTime'];
    var end = data['endTime'];
    var status = getStatus(start, end);

    return FutureBuilder(
      future: _firestore
          .collection('contest_registrations')
          .where('userId', isEqualTo: widget.userId)
          .where('contestId', isEqualTo: contest.id)
          .get(),
      builder: (context, AsyncSnapshot<QuerySnapshot> regSnapshot) {
        bool isRegistered =
            regSnapshot.hasData && regSnapshot.data!.docs.isNotEmpty;

        return GestureDetector(
          onTap: () {
            if (isRegistered) {
              _navigateToContestDetails(contest.id);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please register to view contest details.')),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(36, 36, 48, 1),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, color: Pallete.whiteColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['name'] ?? 'Unnamed Contest',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Pallete.whiteColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data['description'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  "Starts: ${_formatTimestamp(start)}",
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (status == 'ended')
                      const Text(
                        "ENDED",
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold),
                      )
                    else if (isRegistered && status == 'upcoming')
                      _buildGradientButton("Unregister", Colors.redAccent,
                          () => _unregisterFromContest(contest.id))
                    else if (!isRegistered)
                      _buildGradientButton("Register", null,
                          () => _registerForContest(contest.id))
                    else
                      const Text(
                        "REGISTERED",
                        style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientButton(
      String text, Color? solidColor, VoidCallback onPressed) {
    if (solidColor != null) {
      // Solid color (e.g., for Unregister button)
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: solidColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text),
      );
    } else {
      // Gradient background
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Pallete.gradient1, Pallete.gradient2],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Future<void> _unregisterFromContest(String contestId) async {
    var regSnapshot = await _firestore
        .collection('contest_registrations')
        .where('userId', isEqualTo: widget.userId)
        .where('contestId', isEqualTo: contestId)
        .get();

    for (var doc in regSnapshot.docs) {
      await _firestore.collection('contest_registrations').doc(doc.id).delete();
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unregistered Successfully!')));
  }

  Future<void> _registerForContest(String contestId) async {
    await _firestore.collection('contest_registrations').add({
      'userId': widget.userId,
      'contestId': contestId,
      'registeredAt': Timestamp.now(),
    });

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered Successfully!')));
  }

  void _navigateToContestDetails(String contestId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ContestDetailsPage(contestId: contestId, userId: widget.userId),
      ),
    );
  }
}
