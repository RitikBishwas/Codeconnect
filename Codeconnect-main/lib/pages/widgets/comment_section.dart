import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nitd_code/ui/pallete.dart';
import 'package:nitd_code/utils/timeago.dart';

class CommentSection extends StatefulWidget {
  final String postId;
  const CommentSection({super.key, required this.postId});

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _hoveringSend = false; // Added variable to track hover state

  Future<void> _addComment() async {
    if (_commentController.text.isNotEmpty) {
      var user = await _firestore
          .collection('users')
          .where("uid", isEqualTo: _auth.currentUser?.uid)
          .get();

      await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'content': _commentController.text,
        'author': user.docs[0].data()['name'] ?? 'Anonymous',
        'userId': _auth.currentUser?.uid,
        'timestamp': DateTime.now(),
      });
      await _firestore.collection('posts').doc(widget.postId).update({
        'commentCount': FieldValue.increment(1),
      });
      _commentController.clear();
    }
  }

  Future<void> _editComment(String commentId, String content) async {
    _commentController.text = content;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor:
              Colors.transparent, // Transparent background for better styling
          child: Container(
            width: MediaQuery.of(context).size.width *
                0.85, // Max width (85% of screen width)
            constraints: const BoxConstraints(maxWidth: 400), // Hard max width
            decoration: BoxDecoration(
              color: Pallete.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Prevents unnecessary expansion
              children: [
                const Text(
                  'Edit Comment',
                  style: TextStyle(
                    color: Pallete.whiteColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Pallete.whiteColor),
                  decoration: InputDecoration(
                    labelText: 'Comment',
                    labelStyle:
                        TextStyle(color: Pallete.whiteColor.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Pallete.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Pallete.gradient1, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _commentController.clear();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            color: Pallete.gradient2,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (_commentController.text.isNotEmpty) {
                          await _firestore
                              .collection('posts')
                              .doc(widget.postId)
                              .collection('comments')
                              .doc(commentId)
                              .update({
                            'content': _commentController.text,
                          });
                          Navigator.of(context).pop();
                          _commentController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Pallete.gradient1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white)),
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

  Future<void> _deleteComment(String commentId) async {
    await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .delete();

    await _firestore.collection('posts').doc(widget.postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, right: 8.0, bottom: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: "Write a comment...",
                    hintStyle:
                        TextStyle(color: Pallete.whiteColor.withOpacity(0.6)),
                    filled: true,
                    fillColor: Pallete.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Pallete.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Pallete.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Pallete.gradient1, width: 2),
                    ),
                  ),
                  style: const TextStyle(color: Pallete.whiteColor),
                ),
              ),
              const SizedBox(width: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hoveringSend = true),
                onExit: (_) => setState(() => _hoveringSend = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hoveringSend
                        ? Pallete.gradient3.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                  padding: EdgeInsets.all(_hoveringSend ? 2.0 : 0.0),
                  child: IconButton(
                    icon: Icon(Icons.send,
                        color: _hoveringSend
                            ? Pallete.gradient3
                            : Pallete.gradient2),
                    onPressed: _addComment,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('posts')
                .doc(widget.postId)
                .collection('comments')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var comments = snapshot.data!.docs
                  .map((doc) => {
                        'id': doc.id,
                        'content': doc['content'],
                        'author': doc['author'],
                        'userId': doc['userId'],
                        'timestamp': (doc['timestamp'] as Timestamp).toDate(),
                      })
                  .toList();
              return Column(
                children: comments.map((comment) {
                  bool isCurrentUserComment =
                      comment['userId'] == _auth.currentUser?.uid;

                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore
                        .collection('users')
                        .where("uid", isEqualTo: comment['userId'])
                        .get()
                        .then((value) => value.docs.first),
                    builder: (context, userSnapshot) {
                      String? userImage;
                      if (userSnapshot.connectionState ==
                              ConnectionState.done &&
                          userSnapshot.hasData) {
                        userImage = userSnapshot.data!['profileImage'];
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Pallete.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Pallete.borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Pallete.gradient1.withOpacity(0.2),
                                blurRadius: 6,
                                spreadRadius: 2,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          userImage ??
                                              'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.person,
                                                      size: 24,
                                                      color: Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        comment['author'],
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Pallete.whiteColor
                                                .withOpacity(0.9)),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.access_time,
                                          size: 14,
                                          color: Pallete.whiteColor
                                              .withOpacity(0.7)),
                                      const SizedBox(width: 4),
                                      Text(
                                        TimeAgoUtil.timeAgo(
                                            comment['timestamp']),
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Pallete.whiteColor
                                                .withOpacity(0.7)),
                                      ),
                                    ],
                                  ),
                                  if (isCurrentUserComment)
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              size: 20,
                                              color: Pallete.gradient2),
                                          onPressed: () => _editComment(
                                              comment['id'],
                                              comment['content']),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 20,
                                              color: Pallete.gradient3),
                                          onPressed: () =>
                                              _deleteComment(comment['id']),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment['content'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Pallete.whiteColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(), // Converts the list into widgets
              );
            },
          )
        ],
      ),
    );
  }
}
