import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nitd_code/models/post_model.dart';
import 'package:nitd_code/pages/post_page/post_page.dart';
import 'package:nitd_code/pages/widgets/contentinputbox.dart';
import 'package:nitd_code/pages/widgets/edit_post_dialog.dart';
import 'package:nitd_code/pages/widgets/titleinputbox.dart';
import 'package:nitd_code/ui/pallete.dart';
import 'package:nitd_code/utils/timeago.dart';

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, this.height = 60.0});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // The header should respect the declared height.
    return SizedBox(
      height: height,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

class DiscussionPage extends StatefulWidget {
  const DiscussionPage({super.key});

  @override
  _DiscussionPageState createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  final TextEditingController _tagController = TextEditingController();
  String _sortingOption = 'Date';
  List<String> sortingOptions = ['Date', 'Popularity'];
  String? _selectedTag;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';
  final List<String> postViewOptions = ["All Posts", "My Posts"];
  String _selectedView = "All Posts"; // Default selection
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final List<String> _tags = [];
  bool _isSidebarVisible = true;

  String? currentUserId;

  @override
  void initState() {
    super.initState();
  }

  Future<void> addPost(String title, String tags, String content) async {
    if (title.isNotEmpty && content.isNotEmpty && tags.isNotEmpty) {
      final docRef =
          _firestore.collection('posts').doc(); // Generate a new doc reference
      var user = await _firestore
          .collection('users')
          .where("uid", isEqualTo: _auth.currentUser?.uid)
          .get();

      final post = Post(
        id: docRef.id, // Assign the generated ID
        title: title,
        content: content,
        tags: tags.split(','),
        userId: _auth.currentUser?.uid ?? 'unknown',
        date: DateTime.now(),
        votes: 0,
        commentCount: 0,
        votesMap: {},
        userName: user.docs[0]['name'],
      );

      try {
        await docRef.set(post.toMap()); // Store post with ID
      } catch (e) {
        throw Exception(e.toString());
      }
    } else {
      throw Exception('Title, content and tags cannot be empty.');
    }
  }

  Future<void> deletePost(BuildContext context, String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<Post>> fetchPosts() async {
    final snapshot = await _firestore.collection('posts').get();
    return snapshot.docs
        .map((doc) => Post.fromMap(doc.data(), doc.id))
        .toList();
  }

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

  void showEditPostDialog(BuildContext context, String postId, String title,
      String content, List<String> tags, FirebaseFirestore firestore) {
    showDialog(
      context: context,
      builder: (context) => EditPostDialog(
        postId: postId,
        initialTitle: title,
        initialContent: content,
        initialTags: tags,
        firestore: firestore,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(126, 30, 30, 40),
        centerTitle: true,
        title: const Text(
          'Discussion Forum',
          style: TextStyle(color: Pallete.whiteColor),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSidebarVisible ? Icons.menu : Icons.menu_open, // New icons
              color: Pallete.whiteColor,
            ),
            onPressed: () {
              setState(() {
                _isSidebarVisible = !_isSidebarVisible;
              });
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Discussion Posts
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomScrollView(
                slivers: [
                  // Post Submission
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Pallete
                            .borderColor, // Darker background for contrast
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TitleInputField(
                            controller: _titleController,
                          ),
                          const SizedBox(height: 12),
                          ContentInputField(controller: _contentController),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _tagController,
                                  decoration: InputDecoration(
                                    labelText: 'Enter Tag',
                                    labelStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Pallete.whiteColor,
                                    ),
                                    hintText: "Add relevant tags...",
                                    hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade400),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Pallete.gradient1, width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Pallete.gradient2, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Pallete.gradient3, width: 1.5),
                                    ),
                                    filled: true,
                                    fillColor: Pallete.backgroundColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    suffixIcon: const Icon(Icons.tag,
                                        color: Pallete.whiteColor),
                                  ),
                                  style: const TextStyle(
                                      fontSize: 14, color: Pallete.whiteColor),
                                  cursorColor: Pallete.gradient1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  if (_tagController.text.isNotEmpty) {
                                    setState(() {
                                      if (!_tags
                                          .contains(_tagController.text)) {
                                        _tags.add(_tagController.text);
                                      }
                                      _tagController.clear();
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Pallete.gradient2,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  fixedSize: const Size.fromHeight(40),
                                ),
                                child: const Text('Add Tag',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: _tags.map((tag) {
                              return Chip(
                                label: Text(tag,
                                    style: const TextStyle(
                                        color: Pallete.whiteColor)),
                                backgroundColor: Pallete.gradient1,
                                deleteIcon: const Icon(Icons.close,
                                    color: Colors.white),
                                onDeleted: () {
                                  setState(() {
                                    _tags.remove(tag);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _titleController.clear();
                                    _contentController.clear();
                                    _tagController.clear();
                                    _tags.clear();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Cancel',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  addPost(
                                    _titleController.text,
                                    _tags.join(','),
                                    _contentController.text,
                                  ).then((_) {
                                    setState(() {
                                      _titleController.clear();
                                      _contentController.clear();
                                      _tagController.clear();
                                      _tags.clear();
                                    });
                                  }).catchError((error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error.toString()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Pallete.gradient3,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Post',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      height: 60.0, // Specify the required height
                      child: Container(
                        color: Pallete.backgroundColor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildToggleButtons(postViewOptions, _selectedView,
                                (index) {
                              setState(() {
                                _selectedView = postViewOptions[index];
                              });
                            }),
                            _buildToggleButtons(sortingOptions, _sortingOption,
                                (index) {
                              setState(() {
                                _sortingOption = sortingOptions[index];
                              });
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Real-time Post Stream
                  StreamBuilder<QuerySnapshot>(
                    stream: _selectedView == 'My Posts'
                        ? _firestore
                            .collection('posts')
                            .where('userId', isEqualTo: _auth.currentUser?.uid)
                            .orderBy(
                                _sortingOption == 'Date' ? 'date' : 'votes',
                                descending: true)
                            .snapshots()
                        : _firestore
                            .collection('posts')
                            .orderBy(
                                _sortingOption == 'Date' ? 'date' : 'votes',
                                descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      final userId = _auth.currentUser?.uid ?? '';

                      if (!snapshot.hasData) {
                        return const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 100, // fixed height; adjust as needed
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      List<Post> posts = snapshot.data!.docs
                          .map((doc) => Post.fromMap(
                              doc.data() as Map<String, dynamic>, doc.id))
                          .toList();

                      if (_selectedTag != null) {
                        posts = posts
                            .where((post) => post.tags.contains(_selectedTag))
                            .toList();
                      }

                      return SliverList(
                          delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          final userVote = post.votesMap[userId] ?? 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 4,
                            color: Pallete.borderColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween, // Ensures right alignment for edit & delete
                                    children: [
                                      FutureBuilder<DocumentSnapshot>(
                                        future: _firestore
                                            .collection('users')
                                            .where("uid",
                                                isEqualTo: post.userId)
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
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12), // Circular image
                                                child: Image.network(
                                                  userImage ??
                                                      'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                                                  width: 24, // Small size
                                                  height: 24,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      const Icon(Icons.person,
                                                          size: 24,
                                                          color: Colors.grey),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                post.userName,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Pallete.whiteColor
                                                      .withOpacity(0.9),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(Icons.access_time,
                                                  size: 14,
                                                  color: Pallete.whiteColor
                                                      .withOpacity(0.7)),
                                              const SizedBox(width: 4),
                                              Text(
                                                TimeAgoUtil.timeAgo(post.date),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Pallete.whiteColor
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      if (_selectedView == "My Posts")
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                // Edit post dialog popup.
                                                showEditPostDialog(
                                                    context,
                                                    post.id,
                                                    post.title,
                                                    post.content,
                                                    post.tags,
                                                    _firestore);
                                              },
                                              icon: const Icon(Icons.edit,
                                                  color: Pallete.gradient1,
                                                  size: 20),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      backgroundColor: Pallete
                                                          .backgroundColor,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                      title: const Text(
                                                        'Delete Post',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Pallete
                                                              .whiteColor,
                                                        ),
                                                      ),
                                                      content: Text(
                                                        'Are you sure you want to delete this post?',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors
                                                              .grey.shade400,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                          style: TextButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                Pallete
                                                                    .gradient2,
                                                          ),
                                                          child: const Text(
                                                              'Cancel'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              deletePost(
                                                                  context,
                                                                  post.id),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Pallete
                                                                    .gradient2,
                                                            foregroundColor:
                                                                Pallete
                                                                    .whiteColor,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                              'Delete'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              icon: Icon(Icons.delete,
                                                  color: Colors.redAccent
                                                      .withOpacity(0.75),
                                                  size: 22),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    post.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Pallete.whiteColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    (post.content.length > 100)
                                        ? '${post.content.substring(0, 100)}...'
                                        : post.content,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Pallete.whiteColor.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.thumb_up,
                                                color: userVote == 1
                                                    ? Pallete.gradient1
                                                    : Colors.grey),
                                            onPressed: () =>
                                                _votePost(post.id, true),
                                          ),
                                          Text(
                                            '${post.votes}',
                                            style: const TextStyle(
                                                color: Pallete.whiteColor),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.thumb_down,
                                                color: userVote == -1
                                                    ? Pallete.gradient2
                                                    : Colors.grey),
                                            onPressed: () =>
                                                _votePost(post.id, false),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('${post.commentCount}',
                                              style: const TextStyle(
                                                  color: Pallete.whiteColor)),
                                          Tooltip(
                                            message: "Comment",
                                            child: IconButton(
                                              icon: const Icon(Icons.comment,
                                                  color: Pallete.gradient3),
                                              onPressed: () {
                                                setState(() {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            PostPage(
                                                                postId:
                                                                    post.id)),
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: posts.length,
                      ));
                    },
                  ),
                ],
              ),
            ),
          ),

          // Right Side: Tags Sidebar
          Visibility(
              visible: _isSidebarVisible,
              child: Container(
                width: 250,
                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Pallete.backgroundColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Pallete.borderColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              color: Pallete.whiteColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(
                                  color: Pallete.whiteColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search tags...',
                                hintStyle: TextStyle(
                                    color: Pallete.whiteColor.withOpacity(0.6),
                                    fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (query) {
                                setState(() {
                                  _searchQuery = query.toLowerCase();
                                });
                              },
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Pallete.whiteColor, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tags List
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Pallete.borderColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore.collection('posts').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            // Counting Tags
                            Map<String, int> tagCount = {};
                            for (var doc in snapshot.data!.docs) {
                              List<String> tags =
                                  (doc['tags'] as List<dynamic>).cast<String>();
                              for (var tag in tags) {
                                tagCount[tag] = (tagCount[tag] ?? 0) + 1;
                              }
                            }

                            // Filtering Tags
                            List<String> filteredTags = tagCount.keys
                                .where((tag) =>
                                    tag.toLowerCase().contains(_searchQuery))
                                .toList();

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filteredTags.length,
                              itemBuilder: (context, index) {
                                String tag = filteredTags[index];
                                bool isSelected = _selectedTag == tag;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTag = isSelected ? null : tag;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? const LinearGradient(
                                              colors: [
                                                Pallete.gradient1,
                                                Pallete.gradient2,
                                                Pallete.gradient3,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: isSelected
                                          ? null
                                          : Pallete.backgroundColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? Pallete.gradient2
                                            : Pallete.borderColor,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: Pallete.gradient1
                                                .withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '#$tag',
                                          style: const TextStyle(
                                            color: Pallete.whiteColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '(${tagCount[tag]})',
                                          style: TextStyle(
                                            color: Pallete.whiteColor
                                                .withOpacity(0.8),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ))
        ],
      ),
    );
  }

  Widget _buildToggleButtons(
      List<String> options, String selectedOption, Function(int) onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Pallete.borderColor, width: 1.5),
        gradient: const LinearGradient(
          colors: [Pallete.gradient1, Pallete.gradient2, Pallete.gradient3],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Pallete.gradient2.withOpacity(0.3),
            blurRadius: 2,
            spreadRadius: 0.5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: ToggleButtons(
        isSelected: options.map((option) => option == selectedOption).toList(),
        onPressed: onPressed,
        selectedColor: Pallete.whiteColor,
        color: const Color.fromRGBO(220, 208, 255, 1),
        fillColor: Pallete.gradient2.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        borderWidth: 0,
        renderBorder: false,
        constraints: const BoxConstraints(minHeight: 40),
        children: options
            .map((option) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
