import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

/// GolodoliAudioHandler — wraps just_audio inside audio_service.
/// Provides system-level background playback, lock screen controls,
/// and Android status bar notification with full media controls.
class GolodoliAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // Current episode queue for next/prev
  List<MediaItem> _queue = [];
  int _currentIndex = 0;

  GolodoliAudioHandler() {
    _setupPlayerListeners();
  }

  // ─────────────────────────────────────────────
  // Exposed Streams for direct controller listening
  // ─────────────────────────────────────────────
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;

  // ─────────────────────────────────────────────
  // Internal Setup
  // ─────────────────────────────────────────────

  void _setupPlayerListeners() {
    // 1. Playback event stream (position, buffering, processingState changes)
    _player.playbackEventStream.listen(
      (event) => _broadcastState(),
      onError: (Object e, StackTrace st) {
        debugPrint('playbackEventStream error: $e');
      },
    );

    // 2. Duration listener
    _player.durationStream.listen((duration) {
      if (duration != null && _queue.isNotEmpty && _currentIndex < _queue.length) {
        final updated = _queue[_currentIndex].copyWith(duration: duration);
        _queue[_currentIndex] = updated;
        mediaItem.add(updated);
      }
      _broadcastState();
    });

    // 3. Player state listener (playing & completion)
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleCompletion();
      }
      _broadcastState();
    });
  }

  void _broadcastState() {
    final isPlaying = _player.playing;
    final pState = _player.processingState;
    final processingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[pState] ?? AudioProcessingState.idle;

    final controls = [
      if (_currentIndex > 0) MediaControl.skipToPrevious,
      MediaControl.rewind,
      isPlaying ? MediaControl.pause : MediaControl.play,
      MediaControl.fastForward,
      if (_currentIndex < _queue.length - 1) MediaControl.skipToNext,
    ];

    playbackState.add(PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.fastForward,
        MediaAction.rewind,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.playPause,
      },
      androidCompactActionIndices: controls.length >= 3
          ? [0, 2, 4 < controls.length ? 4 : 2]
          : List.generate(controls.length, (i) => i),
      processingState: processingState,
      playing: isPlaying,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
      updateTime: DateTime.now(),
    ));
  }

  Future<void> _handleCompletion() async {
    customEvent.add({'action': 'episodeCompleted', 'index': _currentIndex});
  }

  // ─────────────────────────────────────────────
  // Public API — called from AudioPlayerController
  // ─────────────────────────────────────────────

  /// Load a new episode URL and start playing cleanly.
  Future<void> loadAndPlay({
    required String url,
    required MediaItem item,
    List<MediaItem>? queue,
    int queueIndex = 0,
    Duration startPosition = Duration.zero,
  }) async {
    try {
      _queue = queue ?? [item];
      _currentIndex = queueIndex;
      mediaItem.add(item);
      this.queue.add(_queue);

      // Cleanly stop any existing stream first to avoid AbortError
      await _player.stop();

      // Load into just_audio (supports local offline files & remote URLs)
      Duration? resolvedDuration;
      if (!url.startsWith('http://') && !url.startsWith('https://') && File(url).existsSync()) {
        resolvedDuration = await _player.setFilePath(url);
      } else {
        resolvedDuration = await _player.setUrl(url);
      }

      if (resolvedDuration != null) {
        final updated = item.copyWith(duration: resolvedDuration);
        mediaItem.add(updated);
      }

      if (startPosition > Duration.zero) {
        await _player.seek(startPosition);
      }

      await _player.play();
    } catch (e) {
      debugPrint('GolodoliAudioHandler.loadAndPlay error: $e');
    }
  }

  /// Get current position as Duration
  Duration get position => _player.position;

  /// Get total duration
  Duration? get duration => _player.duration;

  /// Is currently playing
  bool get isPlaying => _player.playing;

  // ─────────────────────────────────────────────
  // audio_service BaseAudioHandler overrides
  // ─────────────────────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> fastForward() async {
    final newPos = _player.position + const Duration(seconds: 10);
    final max = _player.duration ?? Duration.zero;
    await _player.seek(newPos > max ? max : newPos);
  }

  @override
  Future<void> rewind() async {
    final newPos = _player.position - const Duration(seconds: 10);
    await _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  @override
  Future<void> skipToNext() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      final nextItem = _queue[_currentIndex];
      mediaItem.add(nextItem);
      customEvent.add({'action': 'skipToNext', 'index': _currentIndex});
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      final prevItem = _queue[_currentIndex];
      mediaItem.add(prevItem);
      customEvent.add({'action': 'skipToPrevious', 'index': _currentIndex});
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      mediaItem.add(_queue[_currentIndex]);
      customEvent.add({'action': 'skipToQueueItem', 'index': _currentIndex});
    }
  }

  int get currentIndex => _currentIndex;

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
}
