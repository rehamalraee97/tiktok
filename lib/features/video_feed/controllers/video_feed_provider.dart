// Provider File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_clone_app/features/video_feed/models/post.dart';
import 'package:tiktok_clone_app/features/video_feed/services/video_feed_repository.dart';
import 'package:video_player/video_player.dart';

class VideoFeedState {
  final List<Post> posts;
  final bool isLoading;
  final bool hasNextPage;
  final String? error;
  final int postType;
  final Map<String, VideoPlayerController> videoControllers;

  VideoFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasNextPage = true,
    this.error,
    this.postType = 1,
    this.videoControllers = const {},
  });

  VideoFeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? hasNextPage,
    String? error,
    int? postType,
    Map<String, VideoPlayerController>? videoControllers,
  }) {
    return VideoFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      error: error ?? this.error,
      postType: postType ?? this.postType,
      videoControllers: videoControllers ?? this.videoControllers,
    );
  }
}

final videoFeedProvider = StateNotifierProvider<VideoFeedNotifier, VideoFeedState>(
      (ref) => VideoFeedNotifier(),
);

class VideoFeedNotifier extends StateNotifier<VideoFeedState> {
  final _repo = VideoFeedRepository();
  String? _nextCursor;

  VideoFeedNotifier() : super(VideoFeedState()) {
    getPosts();
  }

  Future<void> getPosts() async {
    if (state.isLoading || !state.hasNextPage) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiData = await _repo.fetchPosts(
        cursor: _nextCursor != null ? int.tryParse(_nextCursor!) : null,
        postType: state.postType,
      );

      final newPosts = apiData[0];
      _nextCursor = apiData[1]?.toString();

      final newControllers = Map<String, VideoPlayerController>.from(state.videoControllers);

      // Initialize controllers only for new posts
      for (final post in newPosts) {
        final idStr = post.id.toString();
        if (!newControllers.containsKey(idStr)) {
          final ctrl = VideoPlayerController.network(post.videoUrl);
          await ctrl.initialize();
          ctrl.setLooping(true);
          newControllers[idStr] = ctrl;
        }
      }

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        videoControllers: newControllers,
        isLoading: false,
        hasNextPage: newPosts.isNotEmpty,
      );
    } catch (e, st) {
      debugPrint('getPosts error: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load videos: ${e.toString()}',
      );
    }
  }

  Future<void> setPostType(int newType) async {
    if (state.postType == newType) return;
    _disposeControllers();
    _nextCursor = null;
    state = VideoFeedState(postType: newType);
    await getPosts();
  }

  Future<void> likePost(Post post) async {
    try {
      final newIsLiked = !post.isLiked;
      final updatedPost = post.copyWith(
        isLiked: newIsLiked,
        likesCount: post.likesCount + (newIsLiked ? 1 : -1),
      );

      final updatedPosts = state.posts.map((p) => p.id == post.id ? updatedPost : p).toList();
      state = state.copyWith(posts: updatedPosts);

      await _repo.likePost(int.parse(post.id.toString()), newIsLiked);
    } catch (e) {
      debugPrint('Error liking post: $e');
      final originalPosts = state.posts.map((p) => p.id == post.id ? post : p).toList();
      state = state.copyWith(posts: originalPosts);
    }
  }

  Future<void> sendViewData(String postId, Map<String, dynamic> body) async {
    try {
      await _repo.viewPost(postId, body);
    } catch (e) {
      debugPrint('Failed to track view event: $e');
    }
  }

  void _disposeControllers() {
    for (final ctrl in state.videoControllers.values) {
      ctrl.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
}// // Provider File
//  import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:tiktok_clone_app/features/video_feed/models/post.dart';
// import 'package:tiktok_clone_app/features/video_feed/services/video_feed_repository.dart';
// import 'package:video_player/video_player.dart';
//
// // final videoFeedProvider = StateNotifierProvider<VideoFeedNotifier, VideoFeedState>((ref) {
// //   return VideoFeedNotifier();
// // });
// //
// class VideoFeedState {
//   final List<Post> posts;
//   final bool isLoading;
//   final bool hasNextPage;
//   final String? error;
//   final int postType;
//   final int? currentCursor;
//   final Map<String, VideoPlayerController> videoControllers;
//
//   VideoFeedState({
//     this.posts = const [],
//     this.isLoading = false,
//     this.hasNextPage = true,
//     this.error,
//     this.postType = 1,
//     this.currentCursor,
//     this.videoControllers = const {},
//   });
//
//   VideoFeedState copyWith({
//     List<Post>? posts,
//     bool? isLoading,
//     bool? hasNextPage,
//     String? error,
//     int? postType,
//     int? currentCursor,
//     Map<String, VideoPlayerController>? videoControllers,
//   }) {
//     return VideoFeedState(
//       posts: posts ?? this.posts,
//       isLoading: isLoading ?? this.isLoading,
//       hasNextPage: hasNextPage ?? this.hasNextPage,
//       error: error ?? this.error,
//       postType: postType ?? this.postType,
//       currentCursor: currentCursor ?? this.currentCursor,
//       videoControllers: videoControllers ?? this.videoControllers,
//     );
//   }
// }
//
// //
// // class VideoFeedNotifier extends StateNotifier<VideoFeedState> {
// //   final VideoFeedRepository _repo = VideoFeedRepository();
// //   int? _currentCursor;
// //   int postType = 1;
// //
// //   VideoFeedNotifier() : super(VideoFeedState());
// //
// //   Future<void> getPosts() async {
// //     if (state.isLoading || !state.hasNextPage) return;
// //
// //     state = state.copyWith(isLoading: true, error: null);
// //
// //     try {
// //       final apiData = await _repo.fetchPosts(
// //         cursor: _currentCursor,
// //         postType: postType,
// //       );
// //
// //       final List<Post> newPosts = apiData[0];
// //       _currentCursor = int.tryParse(apiData[1] ?? "0");
// //
// //       final Map<String, VideoPlayerController> newControllers = Map.from(state.videoControllers);
// //
// //       for (final post in newPosts) {
// //         final controller = VideoPlayerController.networkUrl(Uri.parse(post.videoUrl));
// //         await controller.initialize();
// //         controller.setLooping(true);
// //         newControllers[post.id.toString()] = controller;
// //       }
// //
// //       state = state.copyWith(
// //         posts: [...state.posts, ...newPosts],
// //         videoControllers: newControllers,
// //         isLoading: false,
// //         hasNextPage: newPosts.isNotEmpty,
// //         currentCursor: _currentCursor,
// //       );
// //     } catch (e) {
// //       state = state.copyWith(
// //         isLoading: false,
// //         error: e.toString(),
// //       );
// //     }
// //   }
// //
// //   void toggleTab(int newPostType) {
// //     if (postType == newPostType) return;
// //
// //     postType = newPostType;
// //     _currentCursor = null;
// //     _disposeControllers();
// //
// //     state = VideoFeedState();
// //     getPosts();
// //   }
// //
// //   Future<void> likePost(Post post) async {
// //     try {
// //       final newIsLiked = !post.isLiked;
// //       final updatedPost = post.copyWith(
// //         isLiked: newIsLiked,
// //         likesCount: post.likesCount + (newIsLiked ? 1 : -1),
// //       );
// //       final updatedPosts = state.posts.map((p) => p.id == post.id ? updatedPost : p).toList();
// //       state = state.copyWith(posts: updatedPosts);
// //
// //       await _repo.likePost(int.parse(post.id.toString()), newIsLiked);
// //     } catch (e) {
// //       print('Error liking post: $e');
// //       final originalPosts = state.posts.map((p) => p.id == post.id ? post : p).toList();
// //       state = state.copyWith(posts: originalPosts);
// //     }
// //   }
// //
// //   Future<void> savePost(Post post) async {
// //     try {
// //       final newIsSaved = !post.isSaved;
// //       // await _repo.savePost(int.parse(post.id.toString()), newIsSaved);
// //     } catch (e) {
// //       print('Error saving post: $e');
// //       rethrow;
// //     }
// //   }
// //
// //   Future<void> setPostType(int newPostType) async {
// //     if (state.postType == newPostType) return;
// //     _disposeControllers();
// //     _currentCursor = null;
// //     state = state.copyWith(
// //       postType: newPostType,
// //       posts: [],
// //       hasNextPage: true,
// //       currentCursor: null,
// //       videoControllers: {},
// //     );
// //   }
// //
// //   void updateLikeStatusLocally(String postId, bool isLiked, int likesCount) {
// //     final updatedPosts = state.posts.map((post) {
// //       if (post.id == postId) {
// //         return post.copyWith(isLiked: isLiked, likesCount: likesCount);
// //       }
// //       return post;
// //     }).toList();
// //
// //     state = state.copyWith(posts: updatedPosts);
// //   }
// //
// //   void updateSaveStatusLocally(String postId, bool isSaved) {
// //     final updatedPosts = state.posts.map((post) {
// //       if (post.id == postId) {
// //         return post.copyWith(
// //           isSaved: isSaved,
// //           commentCount: isSaved ? post.commentCount + 1 : post.commentCount - 1,
// //         );
// //       }
// //       return post;
// //     }).toList();
// //
// //     state = state.copyWith(posts: updatedPosts);
// //   }
// //
// //   void _disposeControllers() {
// //     for (final controller in state.videoControllers.values) {
// //       controller.dispose();
// //     }
// //   }
// //
// //   @override
// //   void dispose() {
// //     _disposeControllers();
// //     super.dispose();
// //   }
// // }
// final videoFeedProvider =
//     StateNotifierProvider<VideoFeedNotifier, VideoFeedState>(
//       (ref) => VideoFeedNotifier(),
//     );
//
// class VideoFeedNotifier extends StateNotifier<VideoFeedState> {
//   final _repo = VideoFeedRepository();
//   int? _currentCursor;
//   VideoFeedNotifier() : super(VideoFeedState()) {
//     getPosts();
//   }
//
//   Future<void> getPosts() async {
//     if (state.isLoading || !state.hasNextPage) return;
//
//     state = state.copyWith(isLoading: true, error: null);
//
//     try {
//       final apiData = await _repo.fetchPosts(
//         cursor: _currentCursor,
//         postType: state.postType,
//       );
//       final newPosts = apiData[0];
//       _currentCursor = int.tryParse(apiData[1] ?? '');
//
//       final newControllers = Map<String, VideoPlayerController>.from(
//         state.videoControllers,
//       );
//
//       for (final post in newPosts) {
//         final idStr = post.id.toString();
//         if (!newControllers.containsKey(idStr)) {
//           final ctrl = VideoPlayerController.network(post.videoUrl);
//           await ctrl.initialize();
//           ctrl.setLooping(true);
//           newControllers[idStr] = ctrl;
//         }
//       }
//
//       state = state.copyWith(
//         posts: [...state.posts, ...newPosts],
//         videoControllers: newControllers,
//         isLoading: false,
//         hasNextPage: newPosts.isNotEmpty,
//       );
//     } catch (e, st) {
//       debugPrint('getPosts error: $e\n$st');
//       state = state.copyWith(isLoading: false, error: e.toString());
//     }
//   }
//
//   Future<void> setPostType(int newType) async {
//     if (state.postType == newType) return;
//
//     _disposeControllers();
//     _currentCursor = null;
//
//     state = VideoFeedState(postType: newType); // resets
//     await getPosts();
//   }
//
//   Future<void> likePost(Post post) async {
//     try {
//       final newIsLiked = !post.isLiked;
//       final updatedPost = post.copyWith(
//         isLiked: newIsLiked,
//         likesCount: post.likesCount + (newIsLiked ? 1 : -1),
//       );
//       final updatedPosts =
//           state.posts.map((p) => p.id == post.id ? updatedPost : p).toList();
//       state = state.copyWith(posts: updatedPosts);
//
//       await _repo.likePost(int.parse(post.id.toString()), newIsLiked);
//     } catch (e) {
//       print('Error liking post: $e');
//       final originalPosts =
//           state.posts.map((p) => p.id == post.id ? post : p).toList();
//       state = state.copyWith(posts: originalPosts);
//     }
//   }
//
//   Future<void> sendViewData(String postId, Map<String, dynamic> body) async {
//     try {
//       await _repo.viewPost(postId, body);
//     } catch (e) {
//       debugPrint('Failed to track view event: $e');
//     }
//   }
//
//   Future<void> savePost(Post post) async {
//     try {
//       final newIsSaved = !post.isSaved;
//       // await _repo.savePost(int.parse(post.id.toString()), newIsSaved);
//     } catch (e) {
//       print('Error saving post: $e');
//       rethrow;
//     }
//   }
//
//   void updateLikeStatusLocally(String postId, bool isLiked, int likesCount) {
//     final updatedPosts =
//         state.posts.map((post) {
//           if (post.id == postId) {
//             return post.copyWith(isLiked: isLiked, likesCount: likesCount);
//           }
//           return post;
//         }).toList();
//
//     state = state.copyWith(posts: updatedPosts);
//   }
//
//   void updateSaveStatusLocally(String postId, bool isSaved) {
//     final updatedPosts =
//         state.posts.map((post) {
//           if (post.id == postId) {
//             return post.copyWith(
//               isSaved: isSaved,
//               commentCount:
//                   isSaved ? post.commentCount + 1 : post.commentCount - 1,
//             );
//           }
//           return post;
//         }).toList();
//
//     state = state.copyWith(posts: updatedPosts);
//   }
//
//   void _disposeControllers() {
//     for (final ctrl in state.videoControllers.values) {
//       try {
//         ctrl.dispose();
//       } catch (_) {}
//     }
//   }
//
//   @override
//   void dispose() {
//     _disposeControllers();
//     super.dispose();
//   }
// }
