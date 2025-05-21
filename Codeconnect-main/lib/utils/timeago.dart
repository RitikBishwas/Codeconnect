class TimeAgoUtil {
  static String timeAgo(dynamic date) {
    DateTime parsedDate = (date is String) ? DateTime.parse(date) : date;
    Duration diff = DateTime.now().difference(parsedDate);

    if (diff.inSeconds < 60) {
      return "${diff.inSeconds} sec ago";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes} min ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} hr ago";
    } else if (diff.inDays < 30) {
      return "${diff.inDays} days ago";
    } else if (diff.inDays < 365) {
      return "${(diff.inDays / 30).floor()} months ago";
    } else {
      return "${(diff.inDays / 365).floor()} years ago";
    }
  }
}
