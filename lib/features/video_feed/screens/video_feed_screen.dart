import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiktok_clone_app/features/video_feed/controllers/video_feed_provider.dart';
import 'package:tiktok_clone_app/features/video_feed/models/post.dart';
import '../widgets/video_item.dart';

class VideoFeedScreen extends ConsumerStatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  ConsumerState<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends ConsumerState<VideoFeedScreen> with TickerProviderStateMixin {
  late PreloadPageController _pageController;
  int _currentPageIndex = 0;
  double _indicatorPosition = 0.0;
  bool _showShimmer = false;
  late AnimationController _tabAnimationController;
  late Animation<Offset> _tabLabelAnimation;
  late Animation<Offset> _tabArrowAnimation;
  int _currentTab = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PreloadPageController(initialPage: 0);
    _pageController.addListener(_pageListener);

    _tabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _tabLabelAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_tabAnimationController);

    _currentTab = ref.read(videoFeedProvider).postType;
    _indicatorPosition = _currentTab == 1 ? 0.0 : 1.0;
  }

  void _pageListener() {
    final newIndex = _pageController.page?.round() ?? 0;
    if (newIndex != _currentPageIndex) {
      setState(() => _currentPageIndex = newIndex);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_pageListener);
    _pageController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _switchTab(int newTab) async {
    if (_tabAnimationController.isAnimating || _currentTab == newTab) return;

    final notifier = ref.read(videoFeedProvider.notifier);
    setState(() {
      _showShimmer = true;

      _tabLabelAnimation = Tween<Offset>(
        begin: Offset(newTab == 2 ? 1.0 : -1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeOut));

      _tabArrowAnimation = Tween<Offset>(
        begin: Offset(newTab == 2 ? 0.5 : -0.5, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeOut));

      _currentTab = newTab;
    });

    _tabAnimationController.reset();
    await _tabAnimationController.forward();

    await notifier.setPostType(newTab);
    await notifier.getPosts();

    setState(() => _showShimmer = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoFeedProvider);
    final posts = state.posts;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.only(top: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, color: Colors.white),
                  onPressed: () => _switchTab(1),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: _tabLabelAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Text(
                    _currentTab == 1 ? "Following" : "For You",
                    key: ValueKey<int>(_currentTab),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                if (posts.isNotEmpty && !_showShimmer)
                  PreloadPageView.builder(
                    preloadPagesCount: 3,
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final controller = state.videoControllers[post.id];
                      return VideoItem(
                        video: post,
                        isCurrent: index == _currentPageIndex,
                        preloadedController: controller,
                      );
                    },
                  ),
                if (_showShimmer)
                  Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(
                      color: Colors.black,
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
                  ),
                if (posts.isEmpty && !_showShimmer && !state.isLoading)
                  const Center(child: Text("No videos found", style: TextStyle(color: Colors.white))),
                if (posts.isEmpty && state.isLoading && !_showShimmer)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
