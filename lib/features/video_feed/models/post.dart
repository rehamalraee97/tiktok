// lib/features/video_feed/data/models/post.dart
class Post {
  final int id;
  final String videoUrl;
  final String title;
  final String username;
  final String userImage;
  final DateTime date;
  int likesCount;
  bool isLiked;

  Post({
    required this.id,
    required this.videoUrl,
    required this.title,
    required this.username,
    required this.userImage,
    required this.date,
    required this.likesCount,
    required this.isLiked,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      videoUrl: json['video'],
      title: json['title'],
      username: json['user']['username'],
      userImage: json['user']['img'],
      date: DateTime.parse(json['date']),
      likesCount: json['likes']['count'],
      isLiked: json['likes']['isSelected'],
    );
  }
}
