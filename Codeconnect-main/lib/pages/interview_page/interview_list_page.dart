import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nitd_code/ui/pallete.dart';
class InterviewListPage extends StatelessWidget {
  const InterviewListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Pallete.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Interview List',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Pallete.whiteColor,
            ),
          ),
          centerTitle: true,
          backgroundColor: Pallete.borderColor,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Pallete.gradient1, Pallete.gradient2, Pallete.gradient3],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const TabBar(
                indicator: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    bottom: BorderSide(color: Pallete.whiteColor, width: 2),
                  ),
                ),
                labelColor: Pallete.whiteColor,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            UpcomingInterviewsTab(),
            CompletedInterviewsTab(),
          ],
        ),
      ),
    );
  }
}

class UpcomingInterviewsTab extends StatelessWidget {
  const UpcomingInterviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('interviews')
          .where('status', whereIn: ['pending', 'accepted'])
          .orderBy('dateTime')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Pallete.gradient1)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No upcoming interviews',
              style: TextStyle(
                color: Pallete.whiteColor.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            var interview = snapshot.data!.docs[index];
            final dateData = interview['dateTime'] ?? interview['date'];
            
            if (dateData == null) {
              return Container(); // Skip if no date found
            }

            DateTime dateTime;
            try {
              dateTime = dateData is Timestamp 
                  ? dateData.toDate()
                  : DateTime.parse(dateData);
            } catch (e) {
              return Container(); // Skip if date parsing fails
            }

            String formattedDate =
                DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);

            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Pallete.borderColor, Pallete.backgroundColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                title: Text(
                  interview['type'] ?? 'Interview',
                  style: const TextStyle(
                    color: Pallete.whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Pallete.whiteColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: interview['status'] == 'pending'
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        interview['status'].toString().toUpperCase(),
                        style: TextStyle(
                          color: interview['status'] == 'pending'
                              ? Colors.orange
                              : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  interview['status'] == 'pending'
                      ? Icons.access_time
                      : Icons.check_circle,
                  color: interview['status'] == 'pending'
                      ? Colors.orange
                      : Colors.green,
                  size: 28,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CompletedInterviewsTab extends StatelessWidget {
  const CompletedInterviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('interviews')
          .where('status', isEqualTo: 'completed')
          .orderBy('dateTime', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Pallete.gradient1)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No completed interviews',
              style: TextStyle(
                color: Pallete.whiteColor.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            var interview = snapshot.data!.docs[index];
            final dateData = interview['dateTime'] ?? interview['date'];
            
            if (dateData == null) {
              return Container(); // Skip if no date found
            }

            DateTime dateTime;
            try {
              dateTime = dateData is Timestamp 
                  ? dateData.toDate()
                  : DateTime.parse(dateData);
            } catch (e) {
              return Container(); // Skip if date parsing fails
            }

            String formattedDate =
                DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);

            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Pallete.borderColor, Pallete.backgroundColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                title: Text(
                  interview['type'] ?? 'Interview',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Pallete.whiteColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (interview['rating'] != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${interview['rating']}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                trailing: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        );
      },
    );
  }
}