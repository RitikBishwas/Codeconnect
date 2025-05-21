class Post {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final String userName;
  final String userId;
  final DateTime date;
  final int votes;
  final int commentCount;
  final Map<String, int> votesMap;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.userId,
    required this.userName,
    required this.date,
    required this.votes,
    required this.commentCount,
    required this.votesMap,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'userId': userId,
      'date': date.toIso8601String(),
      'votes': votes,
      'commentCount': commentCount,
      'votesMap': votesMap,
      'userName': userName,
    };
  }

  static Post fromMap(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      title: data['title'],
      content: data['content'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      date: DateTime.parse(data['date']),
      votes: data['votes'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      votesMap: Map<String, int>.from(data['votesMap'] ?? {}),
    );
  }
}
