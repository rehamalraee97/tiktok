// lib/features/video_feed/data/models/post.dart
class Post {
  final int id;
  final String videoUrl;
  final String title;
  final String username;
  final String userImage;
  final DateTime date;
  int likesCount;
  int commentCount;
  bool isLiked;
  bool isSaved;

  Post({
    required this.id,
    required this.videoUrl,
    required this.title,
    required this.username,
    required this.userImage,
    required this.date,
    required this.likesCount,
    required this.commentCount,
    required this.isLiked,
    required this.isSaved,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      videoUrl: json['video'],
      commentCount: json['bookmarks']['count'],
      title: json['title'],
      username: json['user']['username'],
      userImage: json['user']['img'],
      date: DateTime.parse(json['date']),
      likesCount: json['likes']['count'],
      isLiked: json['likes']['isSelected'],
      isSaved: json['bookmarks']['isSelected'],
    );
  }
  // Add this copyWith method
  Post copyWith({
    int? id,
    String? videoUrl,
    String? title,
    String? username,
    String? userImage,
    DateTime? date,
    int? likesCount,
    int? commentCount,
    bool? isLiked,   bool? isSaved,
  }) {
    return Post(
      id:  id?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      title:this.title , username: this.username, userImage: this.userImage, date: this.date, commentCount: this.commentCount,
    );
  }
}
