import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, FieldValue;
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

final videoFeedProvider =
    StateNotifierProvider<VideoFeedNotifier, VideoFeedState>(
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

      final newControllers = Map<String, VideoPlayerController>.from(
        state.videoControllers,
      );
      await syncVideosToFireStore(newPosts);
      for (final post in newPosts) {
        final idStr = post.id.toString();
        if (!newControllers.containsKey(idStr)) {
          final ctrl = VideoPlayerController.network(post.videoUrl);
          try {
            await ctrl.initialize();
            ctrl.setLooping(true);
            newControllers[idStr] = ctrl;
          } catch (e) {
            debugPrint('Video initialization failed for ${post.videoUrl}: $e');
            await ctrl.dispose();
          }
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

      final updatedPosts =
          state.posts.map((p) => p.id == post.id ? updatedPost : p).toList();
      state = state.copyWith(posts: updatedPosts);

      await _repo.likePost(int.parse(post.id.toString()), newIsLiked);
    } catch (e) {
      debugPrint('Error liking post: $e');
      final originalPosts =
          state.posts.map((p) => p.id == post.id ? post : p).toList();
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

  final db = FirebaseFirestore.instance;
  Future<void> syncVideosToFireStore(List<Post> videos) async {
    final db = FirebaseFirestore.instance;

    for (final video in videos) {
      final docRef = db.collection('videos').doc(video.id.toString());
      await docRef.set(video.toJson());
    }

    debugPrint('✅ Synced ${videos.length} videos to Firestore');
  }

  Future<void> likeVideo(Post video) async {
    final docRef = db.collection('videos').doc(video.id.toString());

    await docRef.update({
      'likes.count': video.isLiked
          ? FieldValue.increment(-1)  // if currently liked, decrement on unlike
          : FieldValue.increment(1),  // if currently not liked, increment on like
      'likes.isSelected': !video.isLiked, // toggle the bool
    });
  }

  Future<void> bookmarkVideo(Post video) async {
    final docRef = db.collection('videos').doc(video.id.toString());

    await docRef.update({
      'bookmarks.count': video.isSaved
          ? FieldValue.increment(-1)  // if currently saved, decrement on unsave
          : FieldValue.increment(1),  // if currently not saved, increment on save
      'bookmarks.isSelected': !video.isSaved, // toggle the bool
    });
  }

  Future<void> shareVideo(Post video) async {
    final docRef = db.collection('videos').doc(video.id.toString());
    await docRef.set(video.toJson()); // Optional: you can update/share count
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
}
