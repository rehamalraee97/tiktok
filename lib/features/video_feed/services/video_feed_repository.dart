// lib/features/video_feed/data/repository/video_feed_repository.dart
import '../../../../core/helpers/api_base_helper.dart';
import '../models/post.dart';

class VideoFeedRepository {
  final ApiBaseHelper _api = ApiBaseHelper();

  Future<List<dynamic>> fetchPosts({int? cursor, required int postType}) async {
    final response = await _api.get(
      '/api/v1/public/app/posts/feed${cursor != null ? '?cursor=$cursor' : ''}',
    );

    // Handle API response structure more robustly
    if (response.data == null || response.data['data'] == null) {
      throw Exception('Invalid API response structure');
    }

    final data = response.data["data"];
    final postsJson = data['posts'] as List<dynamic>? ?? [];

    final posts = postsJson.map<Post>((item) => Post.fromJson(item)).toList();
    return [posts, data['nextCursor']];
  }

  Future<void> likePost(int postId, bool action) async {
    await _api.post(
      '/api/v1/app/posts/$postId/reaction/like',
      {'action': action.toString()},
    );
  }

  Future<void> viewPost(String postId, Map<String, dynamic> body) async {
    await _api.post('/api/v1/app/posts/$postId/view', body);
  }
}// // lib/features/video_feed/data/repository/video_feed_repository.dart
