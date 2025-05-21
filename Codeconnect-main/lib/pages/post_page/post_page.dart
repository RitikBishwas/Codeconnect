import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nitd_code/pages/widgets/comment_section.dart';
import 'package:nitd_code/ui/pallete.dart';
import 'package:nitd_code/utils/timeago.dart';

class PostPage extends StatefulWidget {
  final String postId; // Receive the post ID
  const PostPage({super.key, required this.postId});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;

  Future<void> _votePost(String postId, bool isUpvote) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final userId = _auth.currentUser?.uid;

    if (userId == null) return;

    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (postDoc.exists) {
        Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
        Map<String, int> votesMap =
            Map<String, int>.from(postData['votesMap'] ?? {});

        int currentVote = votesMap[userId] ?? 0;
        int newVoteValue = isUpvote ? 1 : -1;
        int newVotes = postData['votes'];

        if (currentVote == newVoteValue) {
          newVotes -= newVoteValue;
          votesMap.remove(userId);
        } else {
          newVotes += newVoteValue - currentVote;
          votesMap[userId] = newVoteValue;
        }

        transaction.update(postRef, {'votes': newVotes, 'votesMap': votesMap});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurUserId();
  }

  Future<void> _getCurUserId() async {
    userId = _auth.currentUser?.uid ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Pallete.whiteColor),
        title: const Text("Post Details",
            style: TextStyle(color: Pallete.whiteColor)),
        backgroundColor: Pallete.borderColor.withOpacity(0.5),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('posts').doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Pallete.gradient1));
          }

          var post = snapshot.data!;
          if (!post.exists) {
            return const Center(
              child: Text("Post not found!",
                  style: TextStyle(color: Colors.white)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 4,
              color: Pallete.borderColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username + TimeAgo with profile picture
                    FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('users')
                          .where("uid", isEqualTo: post['userId'])
                          .get()
                          .then((value) => value.docs.first),
                      builder: (context, userSnapshot) {
                        String? userImage;
                        if (userSnapshot.connectionState ==
                                ConnectionState.done &&
                            userSnapshot.hasData) {
                          userImage = userSnapshot.data![
                              'profileImage']; // Assuming 'image' is the field for profile picture
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      12), // Circular image
                                  child: Image.network(
                                    userImage ??
                                        'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                                    width: 24, // Small size
                                    height: 24,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.person,
                                                size: 24, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  post['userName'],
                                  style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Pallete.whiteColor.withOpacity(0.9)),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.access_time,
                                    size: 14,
                                    color: Pallete.whiteColor.withOpacity(0.7)),
                                const SizedBox(width: 4),
                                Text(
                                  TimeAgoUtil.timeAgo(post['date']),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Pallete.whiteColor.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Text(
                      post['title'],
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Pallete.whiteColor),
                    ),
                    const SizedBox(height: 8),
                    // Content
                    Text(
                      post['content'],
                      style: TextStyle(
                          fontSize: 14,
                          color: Pallete.whiteColor.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 8),
                    // Content
                    Text(
                      post['tags'].map((tag) => '#$tag').join(' '),
                      style: TextStyle(
                          fontSize: 14,
                          color: Pallete.whiteColor.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 10),
                    // Vote & Comment Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.thumb_up,
                                  color: (post['votesMap'] is Map &&
                                          post['votesMap']!
                                              .containsKey(userId) &&
                                          post['votesMap'][userId] == 1)
                                      ? Pallete.gradient1
                                      : Colors.grey),
                              onPressed: () => _votePost(post.id, true),
                            ),
                            Text('${post['votes']}',
                                style:
                                    const TextStyle(color: Pallete.whiteColor)),
                            IconButton(
                              icon: Icon(Icons.thumb_down,
                                  color: (post['votesMap'] is Map &&
                                          post['votesMap']!
                                              .containsKey(userId) &&
                                          post['votesMap'][userId] == -1)
                                      ? Pallete.gradient2
                                      : Colors.grey),
                              onPressed: () => _votePost(post.id, false),
                            ),
                            const SizedBox(width: 8),
                            Text('${post['commentCount']}',
                                style:
                                    const TextStyle(color: Pallete.whiteColor)),
                            IconButton(
                              icon: const Icon(Icons.comment,
                                  color: Pallete.gradient3),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Comments Section
                    CommentSection(postId: post.id),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
