class WatchSegment {
  final Duration start;
  final Duration end;

  WatchSegment({required this.start, required this.end});

  Map<String, dynamic> toJson() => {
    'start': start.inSeconds,
    'end': end.inSeconds,
  };
}

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
    // If currently tracking, end current segment and start new
    if (_segmentStart != null) {
      _segments.add(WatchSegment(start: _segmentStart!, end: newPosition));
    }
    _segmentStart = newPosition;
  }

  void stop(Duration finalPosition) {
    onPause(finalPosition);
  }

  void reset() {
    _segmentStart = null;
    _segments.clear();
  }

  Map<String, dynamic> toJson(String postId) => {
    'postId': postId,
    'watchTime': totalWatchTime.inSeconds,
    'segments': segments.map((s) => s.toJson()).toList(),
  };
}
