import 'package:intl/intl.dart';

class Post {
  final int id;
  final String videoUrl;
  final String title;
  final String username;
  final String name;
  final String userImage;
  final String date;
  int likesCount;
  int commentCount;
  bool isLiked;
  bool isSaved;

  Post({
    required this.id,
    required this.videoUrl,
    required this.title,
    required this.username,
    required this.name,
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
      name: json['user']['name'],
      userImage: json['user']['img'],
      date: DateFormat("yyyy-MM-dd").format(DateTime.parse(json['date'])),
      likesCount: json['likes']['count'],
      isLiked: json['likes']['isSelected'],
      isSaved: json['bookmarks']['isSelected'],
    );
  }

  Post copyWith({
    int? id,
    String? videoUrl,
    String? title,
    String? username,
    String? name,
    String? userImage,
    DateTime? date,
    int? likesCount,
    int? commentCount,
    bool? isLiked,
    bool? isSaved,
  }) {
    return Post(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      name: name ?? this.name,
      title: title ?? this.title,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      date: this.date,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video': videoUrl,
      'title': title,
      'date': date,
      'likes': {
        'count': likesCount,
        'isSelected': isLiked,
      },
      'bookmarks': {
        'count': commentCount,
        'isSelected': isSaved,
      },
      'user': {
        'username': username,
        'name': name,
        'img': userImage,
      },
    };
  }
}
