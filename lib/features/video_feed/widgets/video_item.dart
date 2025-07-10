import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:like_button/like_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  VideoPlayerController? _videoController;
  bool _initDone = false;
  String? _error;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    final state = ref.read(videoFeedProvider);
    final idStr = widget.video.id.toString();

    // Use preloaded controller if available and initialized
    if (widget.preloadedController != null &&
        widget.preloadedController!.value.isInitialized) {
      _videoController = widget.preloadedController;
      _setupController();
      return;
    }

    // Check if controller exists in state
    if (state.videoControllers.containsKey(idStr)) {
      _videoController = state.videoControllers[idStr];

      // Check if controller is initialized
      if (state.controllerInitialized[idStr] == true) {
        _setupController();
      } else {
        // Listen for initialization status
        ref.listen<bool?>(
          videoFeedProvider.select((s) => s.controllerInitialized[idStr]),
              (_, isInitialized) {
            if (isInitialized == true && mounted) {
              setState(() {
                _initDone = true;
                _setupController();
              });
            }
          },
        );
      }
    } else {
      // Fallback: Initialize directly if not in state
      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.video.videoUrl),
        );
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        setState(() => _initDone = true);
      } catch (e) {
        setState(() {
          _error = e.toString();
          _initDone = true;
        });
      }
    }
  }

  void _setupController() {
    if (_videoController == null) return;

    if (widget.isCurrent &&
        !_videoController!.value.isPlaying) {
      _videoController!.play();
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else if (_videoController!.value.isInitialized) {
      _videoController!.play();
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_videoController == null) return;

    if (widget.isCurrent &&
        !_videoController!.value.isPlaying) {
      _videoController!.play();
    } else if (!widget.isCurrent && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }
  }

  @override
  void dispose() {
    if (_videoController != null &&
        widget.preloadedController == null) {
      _videoController!.dispose();
    }
    super.dispose();
  }

  void _toggleDescription() {
    setState(() {
      _showFullDescription = !_showFullDescription;
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoSnapshot = ref.watch(videoDocProvider(widget.video.id.toString()));
    final state = ref.watch(videoFeedProvider);
    final isControllerReady = state.controllerInitialized[widget.video.id.toString()] == true ||
        _videoController?.value.isInitialized == true;

    if (!_initDone || !isControllerReady) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return videoSnapshot.when(
      data: (doc) {
        final data = doc.data();
        final likesCount = data?['likes']?['count'] ?? 0;
        final isLiked = data?['likes']?['isSelected'] ?? false;
        final bookmarksCount = data?['bookmarks']?['count'] ?? 0;

        return GestureDetector(
          onTap: _togglePlayPause,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              Positioned(
                bottom: 25,
                left: 16,
                right: 70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(widget.video.userImage),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${widget.video.name} ${widget.video.date}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13
                              ),
                            ),
                            Text(
                              widget.video.username,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _toggleDescription,
                      child: Text(
                        widget.video.title,
                        style: const TextStyle(color: Colors.white),
                        maxLines: _showFullDescription ? null : 2,
                        overflow: _showFullDescription
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.video.title.length > 50)
                      GestureDetector(
                        onTap: _toggleDescription,
                        child: Text(
                          _showFullDescription ? 'See less' : 'See more',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
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
                  _videoController!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
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