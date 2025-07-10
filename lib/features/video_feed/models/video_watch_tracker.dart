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

  Duration _watched = Duration.zero;
  Duration _lastPosition = Duration.zero;
  DateTime? _lastPlayTimestamp;

  void onPlay(Duration position) {
    _lastPosition = position;
    _segmentStart ??= position;

    _lastPlayTimestamp ??= DateTime.now(); // only set if not playing
  }

  void onPause(Duration position) {
    if (_lastPlayTimestamp != null) {
      final elapsed = DateTime.now().difference(_lastPlayTimestamp!);
      _watched += elapsed;
      _lastPlayTimestamp = null;
    }   if (_segmentStart != null) {
      if (position > _segmentStart!) {
        _segments.add(WatchSegment(start: _segmentStart!, end: position));
      }
      _segmentStart = null;
    }
    _lastPosition = position;
  }
  void onSeek(Duration newPosition) {
    // If currently tracking, end current segment and start new
    if (_segmentStart != null) {
      _segments.add(WatchSegment(start: _segmentStart!, end: newPosition));
    }
    _segmentStart = newPosition;
  }
  void stop(Duration position) {
    if (_lastPlayTimestamp != null) {
      final elapsed = DateTime.now().difference(_lastPlayTimestamp!);
      _watched += elapsed;
      _lastPlayTimestamp = null;
    }
    _lastPosition = position;
  }
  void reset() {
    _segmentStart = null;
    _segments.clear();
  }
  Map<String, dynamic> toJson({required String postId, required Duration finalPosition}) {
    return {
      "postId": postId,
      "totalWatchTime": _watched.inSeconds,
      "finalPosition": finalPosition.inSeconds,
      'segments': segments.map((s) => s.toJson()).toList(),

    };
  }
}
