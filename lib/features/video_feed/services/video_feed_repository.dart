// lib/features/video_feed/data/repository/video_feed_repository.dart
import '../../../../core/helpers/api_base_helper.dart';
import '../models/post.dart';

class VideoFeedRepository {
  final ApiBaseHelper _api = ApiBaseHelper();

  Future<List<dynamic>> fetchPosts({int? cursor, required int postType}) async {
    final response = await _api.get(
      '/api/v1/public/app/posts/feed${cursor != null ? '?cursor=$cursor' : ''}',
    );
    try {
      final data = response.data["data"];
      final postsJson = data['posts'] as List<dynamic>;

      final posts = postsJson.map<Post>((item) => Post.fromJson(item)).toList();

      return [posts, data['nextCursor']];

     } catch (e, st) {
      print(e);
      print(st);
    }
    return [];
  }

  Future<void> likePost(int postId) async {
    await _api.post('/api/v1/app/posts/$postId/reaction/like', {});
  }
}
