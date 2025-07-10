import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiktok_clone_app/features/video_feed/controllers/video_feed_provider.dart';
import '../widgets/video_item.dart';

class VideoFeedScreen extends ConsumerStatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  ConsumerState<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends ConsumerState<VideoFeedScreen> {
  late final PreloadPageController _pageController;
  int _currentPageIndex = 0;
  int _currentTab = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PreloadPageController(initialPage: 0);
    _pageController.addListener(_pageListener);
    _currentTab = ref.read(videoFeedProvider).postType;
  }

  void _pageListener() {
    final page = _pageController.page ?? 0;
    final newIndex = page.round();
    final state = ref.read(videoFeedProvider);

    if (newIndex != _currentPageIndex) {
      setState(() => _currentPageIndex = newIndex);
    }

    // Pre-initialize next video
    if (newIndex < state.posts.length - 1) {
      final nextVideo = state.posts[newIndex + 1];
      final nextId = nextVideo.id.toString();

      if (!state.controllerInitialized.containsKey(nextId) ||
          state.controllerInitialized[nextId] == false) {
        ref.read(videoFeedProvider.notifier).getPosts();
      }
    }

    // Auto-fetch next page when reaching end
    if (state.hasNextPage && newIndex >= state.posts.length - 2) {
      ref.read(videoFeedProvider.notifier).getPosts();
    }
  }

  Future<void> _switchTab(int newTab) async {
    if (_currentTab == newTab) return;
    setState(() => _currentTab = newTab);
    await ref.read(videoFeedProvider.notifier).setPostType(newTab);
  }

  @override
  void dispose() {
    _pageController.removeListener(_pageListener);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoFeedProvider);
    final posts = state.posts;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 40),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, color: Colors.white),
                  onPressed: () => _switchTab(1),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _currentTab == 1 ? "Following" : "For You",
                    key: ValueKey<int>(_currentTab),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right, color: Colors.white),
                  onPressed: () => _switchTab(2),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                (state.posts.isEmpty)
                    ? Shimmer.fromColors(
                  baseColor: Colors.grey[800]!,
                  highlightColor: Colors.grey[700]!,
                  child: Column(
                    children: List.generate(
                      3,
                          (index) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                    : PreloadPageView.builder(
                  controller: _pageController,
                  preloadPagesCount: 5,
                  scrollDirection: Axis.vertical,
                  itemCount: posts.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return VideoItem(
                      video: post,
                      isCurrent: index == _currentPageIndex,
                    );
                  },
                ),
                if (state.isLoading)
                  Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[700]!,
                    child: Column(
                      children: List.generate(
                        3,
                            (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (posts.isEmpty && !state.isLoading)
                  const Center(
                    child: Text(
                      "No videos found",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}