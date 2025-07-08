// // lib/features/video_feed/presentation/widgets/video_item.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:tiktok_clone_app/features/video_feed/controllers/video_feed_provider.dart';
// import 'package:tiktok_clone_app/features/video_feed/models/post.dart';
// import 'package:video_player/video_player.dart';
//
//
// import '../../../../core/constants/app_colors.dart';
//
// class VideoItem extends ConsumerStatefulWidget {
//   final Post video;
//
//   const VideoItem({super.key, required this.video});
//
//   @override
//   ConsumerState<VideoItem> createState() => _VideoItemState();
// }
//
// class _VideoItemState extends ConsumerState<VideoItem> {
//   late VideoPlayerController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.network(widget.video.videoUrl)
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//       });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void _toggleLike() {
//     ref.read(videoFeedProvider.notifier).likePost(widget.video);
//     // Add sparkle animation here if needed
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height,
//       width: MediaQuery.of(context).size.width,
//       child: Stack(
//         children: [
//           VideoPlayer(_controller),
//           Positioned(
//             bottom: 10,
//             left: 10,
//             right: 60,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     CircleAvatar(backgroundImage: NetworkImage(widget.video.userImage)),
//                     SizedBox(width: 8),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(widget.video.username, style: TextStyle(color: Colors.white)),
//                         Text(widget.video.date.toString(), style: TextStyle(color: Colors.white, fontSize: 10)),
//                         Text("@${widget.video.username}", style: TextStyle(color: Colors.white, fontSize: 12)),
//                       ],
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   "widget.video.date.length > 50 && !showMore",
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 // GestureDetector(
//                 //   onTap: () => setState(() => ),
//                 //   child: Text(showMore ? "See Less" : "See More",
//                 //       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                 // ),
//               ],
//             ),
//           ),
//           Positioned(
//             right: 10,
//             bottom: 50,
//             child: Column(
//               children: [
//                 IconButton(icon: Icon(Icons.favorite, color: AppColors.accent), onPressed: () {}),
//                 IconButton(icon: Icon(Icons.bookmark, color: Colors.white), onPressed: () {}),
//                 IconButton(icon: Icon(Icons.share, color: Colors.white), onPressed: () {}),
//                 IconButton(icon: Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
//               ],
//             ),
//           ),
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: VideoProgressIndicator(
//               _controller,
//               allowScrubbing: true,
//               colors: VideoProgressColors(playedColor: Colors.orange),
//             ),
//           ),
//         ],
//       )
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_clone_app/features/video_feed/controllers/video_feed_provider.dart';
import 'package:tiktok_clone_app/features/video_feed/models/post.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';

class VideoItem extends ConsumerStatefulWidget {
  final Post video;
  final bool isCurrent;

  const VideoItem({super.key, required this.video, this.isCurrent = false});

  @override
  ConsumerState<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends ConsumerState<VideoItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.video.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          if (widget.isCurrent) _controller.play();
        }
      });
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle video playback when visibility changes
    if (widget.isCurrent && _isInitialized) {
      _controller.play();
    } else if (_controller.value.isPlaying) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLike() {
    ref.read(videoFeedProvider.notifier).likePost(widget.video);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          // Video player with fallback
          if (_isInitialized)
            VideoPlayer(_controller)
          else
            const Center(child: CircularProgressIndicator()),

          // Video overlay UI (unchanged)
          Positioned(
            bottom: 10,
            left: 10,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info section
                // ... (same as before)
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 50,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(Icons.favorite,
                      color: widget.video.isLiked ? AppColors.accent : Colors.white),
                  onPressed: _toggleLike,
                ),
                // ... other buttons
              ],
            ),
          ),
          // Progress bar
          if (_isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(playedColor: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }
}