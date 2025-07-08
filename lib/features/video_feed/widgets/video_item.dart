import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chewie/chewie.dart';
import 'package:like_button/like_button.dart';
import 'package:tiktok_clone_app/features/video_feed/controllers/video_feed_provider.dart';
import 'package:tiktok_clone_app/features/video_feed/models/post.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';

class VideoItem extends ConsumerStatefulWidget {
  final Post video;
  final bool isCurrent;
  final VideoPlayerController? preloadedController;

  const VideoItem({
    super.key,
    required this.video,
    this.isCurrent = false,
    this.preloadedController,
  });

  @override
  ConsumerState<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends ConsumerState<VideoItem> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedController != null) {
      _videoController = widget.preloadedController!;
      _initializeChewieController();
    } else {
      _hasError = true;
    }
  }

  void _initializeChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: widget.isCurrent,
      looping: true,
      showControls: false,
      allowFullScreen: false,
      allowMuting: false,
    );

    if (_videoController.value.isInitialized) {
      setState(() {
        _isInitialized = true;
        if (widget.isCurrent) _videoController.play();
      });
    }
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !_hasError) {
      _videoController.play();
    } else {
      _videoController.pause();
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || !_videoController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        if (_videoController.value.isPlaying) {
          _videoController.pause();
        } else {
          _videoController.play();
        }
        setState(() {});
      },
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),
          if (!_videoController.value.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, size: 60, color: Colors.white),
            ),
          // overlay UI: username, buttons, etc...
        ],
      ),
    );
  }
}
