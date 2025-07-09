// Video Item Widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chewie/chewie.dart';
import 'package:tiktok_clone_app/features/video_feed/controllers/video_feed_provider.dart';
import 'package:tiktok_clone_app/features/video_feed/models/post.dart';
import 'package:tiktok_clone_app/features/video_feed/models/video_watch_tracker.dart';
import 'package:video_player/video_player.dart';


class VideoWatchTracker {
  Duration? _segmentStart;
  final List<WatchSegment> _segments = [];

  Duration get totalWatchTime => _segments.fold(
    Duration.zero,
        (total, segment) => total + (segment.end - segment.start),
  );

  List<WatchSegment> get segments => List.unmodifiable(_segments);

  void onPlay(Duration position) {
    _segmentStart ??= position;
  }

  void onPause(Duration position) {
    if (_segmentStart != null) {
      if (position > _segmentStart!) {
        _segments.add(WatchSegment(start: _segmentStart!, end: position));
      }
      _segmentStart = null;
    }
  }

  void onSeek(Duration newPosition) {
    if (_segmentStart != null) {
      _segments.add(WatchSegment(start: _segmentStart!, end: newPosition));
    }
    _segmentStart = newPosition;
  }

  void stop(Duration finalPosition) {
    onPause(finalPosition);
  }

  Map<String, dynamic> toJson(String postId) => {
    'postId': postId,
    'watchTime': totalWatchTime.inSeconds,
    'segments': segments.map((s) => s.toJson()).toList(),
  };
}

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
  late VideoPlayerController _ctrl;
  ChewieController? _chewieCtrl;
  bool _initDone = false;
  late final VideoWatchTracker _tracker;

  @override
  void initState() {
    super.initState();
    _tracker = VideoWatchTracker();
    _initializeController();
  }

  void _initializeController() {
    if (widget.preloadedController != null &&
        widget.preloadedController!.value.isInitialized &&
        !widget.preloadedController!.value.isCompleted) {
      _ctrl = widget.preloadedController!;
      _setupChewie();
    } else {
      _ctrl = VideoPlayerController.network(widget.video.videoUrl)
        ..initialize().then((_) {
          _ctrl.setLooping(true);
          _setupChewie();
        });
    }
    _ctrl.addListener(_videoListener);
  }

  void _videoListener() {
    if (!_ctrl.value.isInitialized) return;
    final position = _ctrl.value.position;

    if (_ctrl.value.isPlaying) {
      _tracker.onPlay(position);
    } else {
      _tracker.onPause(position);
    }
  }

  void _setupChewie() {
    _chewieCtrl = ChewieController(
      videoPlayerController: _ctrl,
      autoPlay: widget.isCurrent,
      looping: true,
      showControls: false,
    );
    if (widget.isCurrent) _ctrl.play();
    setState(() => _initDone = true);
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_initDone) {
      widget.isCurrent ? _ctrl.play() : _ctrl.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initDone) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        if (_ctrl.value.isPlaying) {
          _ctrl.pause();
        } else {
          _ctrl.play();
        }
        setState(() {});
      },
      child: Stack(
        children: [
          Chewie(controller: _chewieCtrl!),
          if (!_ctrl.value.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, size: 60, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Future<void> _sendWatchData() async {
    if (!_ctrl.value.isInitialized) return;
    _tracker.stop(_ctrl.value.position);
    final body = _tracker.toJson(widget.video.id.toString());

    try {
      await ref.read(videoFeedProvider.notifier)
          .sendViewData(widget.video.id.toString(), body);
    } catch (e) {
      debugPrint('Error sending watch data: $e');
    }
  }

  @override
  void dispose() {
    _chewieCtrl?.dispose();
    _ctrl.removeListener(_videoListener);

    // Only dispose controller if it's not preloaded
    if (widget.preloadedController == null) {
      _ctrl.dispose();
    }

    _sendWatchData();
    super.dispose();
  }
}