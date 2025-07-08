import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tiktok_clone_app/features/video_feed/models/post.dart';
import 'package:tiktok_clone_app/features/video_feed/services/video_feed_repository.dart';

// T
final videoFeedProvider = ChangeNotifierProvider((ref) => VideoFeedNotifier());

class VideoFeedNotifier extends ChangeNotifier {
  final VideoFeedRepository _repo = VideoFeedRepository();
  PagingState<int, Post> _state = PagingState();
  PagingState<int, Post> get state => _state;

  late final _pagingController = PagingController<int, Post>(
    getNextPageKey:
        (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
    fetchPage: (pageKey) => getPosts(),
  );
  PagingController<int, Post> get pagingController => _pagingController;

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
  Future<void> getNextPosts(int index) async {
    if (index >= (state.items?.length ??0)- 3 && !state.isLoading) {
      await getPosts();
    }
  }
  int postType = 1; // 1 = Following, 2 = For You
  int? _currentCursor; // Internal cursor for API calls

  getPosts() async {
    if (_state.isLoading) return;

    _state = _state.copyWith(isLoading: true, error: null);
    try {
      // Determine the cursor for the API call
      final apiData = await _repo.fetchPosts(
        cursor: _currentCursor,
        postType: postType,
      );
      List<Post> newPosts = apiData[0];
      _currentCursor = int.tryParse(apiData[1] ?? "0");
      final isLastPage = newPosts.isEmpty;

      _state = _state.copyWith(
        pages: [...?_state.pages, newPosts],
        keys: [...?_state.keys, _currentCursor!],
        hasNextPage: !isLastPage,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e, isLoading: false);
    }
  }

  void toggleTab(int newPostType) {
    if (postType == newPostType) return;
    postType = newPostType;
    _currentCursor = null; // Reset cursor when changing tabs

    _state = _state.copyWith(pages: [], keys: [], error: null);
    // Alternatively, you can use pagingController.refresh();
    // if you want to trigger a fetch for the current page key (which will be _firstPageKey after resetting)
  }

  Future<void> likePost(Post post) async {
    final newIsLiked = !post.isLiked;
    post.isLiked = newIsLiked;
    post.likesCount += newIsLiked ? 1 : -1;

    final updatedPages =
        _state.pages?.map((page) {
          // Check if this page contains the post we just updated
          if (page.any((p) => p.id == post.id)) {
            // If it does, create a new list for this page with the updated post
            return page.map((p) {
              if (p.id == post.id) {
                return post;
              }
              return p;
            }).toList();
          }
          return page; // Return the page as is if it doesn't contain the post
        }).toList();

    _state = _state.copyWith(pages: updatedPages);
    // Call the repository to update the like status on the backend
    await _repo.likePost(post.id);
  }
}
