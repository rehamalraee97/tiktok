// video_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiktok_clone_app/features/video_feed/models/video_watch_tracker.dart';
import 'package:video_player/video_player.dart';
import 'package:like_button/like_button.dart';
 import 'package:tiktok_clone_app/core/constants/app_colors.dart';
import 'package:tiktok_clone_app/features/video_feed/controllers/video_feed_provider.dart';
import 'package:tiktok_clone_app/features/video_feed/controllers/video_doc_provider.dart';
import 'package:tiktok_clone_app/features/video_feed/models/post.dart';

class VideoItem extends ConsumerStatefulWidget {
  final Post video;
  final bool isCurrent;
  final VideoPlayerController? preloadedController;

  const VideoItem({
    Key? key,
    required this.video,
    required this.isCurrent,
    this.preloadedController,
  }) : super(key: key);

  @override
  ConsumerState<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends ConsumerState<VideoItem> {
  late VideoPlayerController _videoController;
  late final VideoWatchTracker _tracker;
  bool _initDone = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tracker = VideoWatchTracker();

    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      if (widget.preloadedController != null &&
          widget.preloadedController!.value.isInitialized) {
        _videoController = widget.preloadedController!;
      } else {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.video.videoUrl),
        );
        await _videoController.initialize();
      }
      _videoController.setLooping(true);
      _videoController.addListener(_videoListener);

      if (widget.isCurrent) {
        _videoController.play();
      }

      if (mounted) setState(() => _initDone = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _initDone = true;
        });
      }
    }
  }
  void _videoListener() {
    if (!_videoController.value.isInitialized) return;
    final position = _videoController.value.position;

    if (_videoController.value.isPlaying) {
      _tracker.onPlay(position);
    } else {
      _tracker.onPause(position);
    }
  }
  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_initDone) return;

    if (widget.isCurrent && !_videoController.value.isPlaying) {
      _videoController.play();
    } else if (!widget.isCurrent && _videoController.value.isPlaying) {
      _videoController.pause();
    }

    if (oldWidget.isCurrent && !widget.isCurrent) {
      _sendWatchDataSafely();
    }
  }
  void _sendWatchDataSafely() {
    final finalPosition = _videoController.value.position;
    _tracker.stop(finalPosition);

    final body = _tracker.toJson(
      postId: widget.video.id.toString(),
      finalPosition: finalPosition,
    );

    ref
        .read(videoFeedProvider.notifier)
        .sendViewData(widget.video.id.toString(), body)
        .catchError((e) {
      debugPrint('Error sending watch data: $e');
    });
  }
  void _togglePlayPause() {
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
    setState(() {});
  }

  @override
  void dispose() {
    if (widget.preloadedController == null) {
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoSnapshot = ref.watch(videoDocProvider(widget.video.id.toString()));

    return videoSnapshot.when(
      data: (doc) {
        final data = doc.data();
        final likesCount = data?['likes']?['count'] ?? 0;
        final isLiked = data?['likes']?['isSelected'] ?? false;
        final bookmarksCount = data?['bookmarks']?['count'] ?? 0;

        if (!_initDone) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
          return Center(child: Text('Error: $_error'));
        }

        return GestureDetector(
          onTap: _togglePlayPause,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 20,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        await ref.read(videoFeedProvider.notifier).likeVideo(widget.video);
                      },
                      child: LikeButton(
                        isLiked: isLiked,
                        likeCount: likesCount,
                        countPostion: CountPostion.bottom,
                        likeBuilder: (liked) => Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          color: liked ? AppColors.accent : Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: Icon(
                        widget.video.isSaved? Icons.bookmark:Icons.bookmark_border,
                        color: widget.video.isSaved  ? AppColors.accent : Colors.white  ,
                      ),
                      onPressed: () async {
                        setState(() {
                          widget.video.isSaved=!widget.video.isSaved;
                        });
                        await ref.read(videoFeedProvider.notifier).bookmarkVideo(widget.video);
                      },
                    ),
                    Text(
                      '$bookmarksCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.send_outlined, color: Colors.white),
                      onPressed: () async {
                        await ref.read(videoFeedProvider.notifier).shareVideo(widget.video);
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VideoProgressIndicator(
                  _videoController,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    backgroundColor: Colors.white30,
                    playedColor: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
