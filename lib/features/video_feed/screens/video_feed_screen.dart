// // lib/features/video_feed/screens/video_feed_screen.dart
//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
//  import 'package:tiktok_clone_app/features/video_feed/controllers/video_feed_provider.dart';
// import 'package:tiktok_clone_app/features/video_feed/models/post.dart';
//
// import '../../../../core/localization/app_localizations.dart';
//
// import '../widgets/video_item.dart';
//
// class VideoFeedScreen extends ConsumerWidget {
//   const VideoFeedScreen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final notifier = ref.read(videoFeedProvider.notifier);
//
//     return Scaffold(
//       body: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.arrow_left),
//                 onPressed: () => notifier.toggleTab(1),
//               ),
//               Text(context.translate(notifier.postType == 1 ? "following" : "for_you")),
//               IconButton(
//                 icon: const Icon(Icons.arrow_right),
//                 onPressed: () => notifier.toggleTab(2),
//               ),
//             ],
//           ),
//           Expanded(
//             child:
//             PagedListView<int, Post>(
//               state: ref.watch(videoFeedProvider).state,
//               fetchNextPage: ref.watch(videoFeedProvider).getPosts,
//               builderDelegate: PagedChildBuilderDelegate(
//                 noItemsFoundIndicatorBuilder: (_) =>
//                     Center(child: Text(context.translate("no_items"))),
//                 itemBuilder: (context, item, index) => VideoItem(video: item),
//               ),
//             ),
//
//
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:tiktok_clone_app/features/video_feed/controllers/video_feed_provider.dart';
import 'package:tiktok_clone_app/features/video_feed/models/post.dart';
import '../../../../core/localization/app_localizations.dart';
import '../widgets/video_item.dart';

class VideoFeedScreen extends ConsumerStatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  ConsumerState<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends ConsumerState<VideoFeedScreen> {
  late PreloadPageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PreloadPageController(initialPage: 0);
    _pageController.addListener(_pageListener);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(videoFeedProvider).state.items;
    final notifier = ref.read(videoFeedProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: () => notifier.toggleTab(1),
              ),
              Text(context.translate(notifier.postType == 1 ? "following" : "for_you")),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: () => notifier.toggleTab(2),
              ),
            ],
          ),
          Expanded(
            child: PreloadPageView.builder(
              preloadPagesCount: 3, // Preload 3 pages ahead
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: posts?.length ?? 0,
              itemBuilder: (context, index) => VideoItem(
                video: (posts?[index])!,
                isCurrent: index == _currentPageIndex,
              ),
              onPageChanged: (index) {
                ref.read(videoFeedProvider.notifier).getNextPosts(index);
              },
            ),
          ),
        ],
      ),
    );
  }
}