import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../core/utils/snackbar_utils.dart';

class PlayerController extends GetxController {
  VideoPlayerController? videoPlayerController;

  final isInitialized = false.obs;
  final isPlaying = false.obs;
  final isBuffering = false.obs;
  final currentPosition = Duration.zero.obs;
  final totalDuration = Duration.zero.obs;
  final errorMessage = ''.obs;

  String videoPath = '';
  String videoName = '';
  String resultTitle = '';
  String targetTimestampText = '00:00';
  Duration targetTimestamp = Duration.zero;

  /// False when the search hit carried no usable timestamp.
  bool hasTimestamp = true;

  /// True when the offset was derived from a baseline rather than reported
  /// directly, so it may be off by however far into the video the first hit is.
  bool isTimestampApproximate = false;

  /// Set when the requested offset had to be adjusted to fit the video, so the
  /// UI can say why playback didn't start where the card advertised.
  final seekNotice = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      videoPath = args['videoPath']?.toString() ?? '';
      videoName = args['videoName']?.toString() ?? 'Wildlife Footage';
      resultTitle = args['title']?.toString() ?? 'Matched Moment';
      targetTimestampText = args['timestampText']?.toString() ?? '00:00';
      hasTimestamp = args['hasTimestamp'] as bool? ?? true;
      isTimestampApproximate = args['isTimestampApproximate'] as bool? ?? false;

      final ts = args['timestamp'];
      if (ts is Duration) {
        targetTimestamp = ts;
      } else if (ts != null) {
        targetTimestamp = DurationUtils.parseTimestampToDuration(ts);
      }
    }

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (videoPath.isEmpty || !File(videoPath).existsSync()) {
      errorMessage.value = 'Video file could not be found at: $videoPath';
      return;
    }

    try {
      final controller = VideoPlayerController.file(File(videoPath));
      videoPlayerController = controller;

      await controller.initialize();
      isInitialized.value = true;
      totalDuration.value = controller.value.duration;

      await _seekToTarget(controller);

      // Auto play matching moment
      await controller.play();
      isPlaying.value = true;

      // Position listener
      controller.addListener(_videoListener);
    } catch (e) {
      errorMessage.value = 'Error initializing video player: ${e.toString()}';
      SnackbarUtils.showError(errorMessage.value);
    }
  }

  /// Seeks to the search hit, clamping into range.
  ///
  /// This used to skip the seek entirely whenever the target fell outside the
  /// video, which made every out-of-range hit play silently from 00:00 while
  /// the card still advertised a timestamp. Clamp and say so instead.
  Future<void> _seekToTarget(VideoPlayerController controller) async {
    final videoDuration = controller.value.duration;

    if (!hasTimestamp) {
      seekNotice.value =
          'This match has no timestamp, so playback starts at the beginning.';
      return;
    }

    if (videoDuration <= Duration.zero) {
      seekNotice.value = 'Video length is unknown, so the seek was skipped.';
      return;
    }

    var target = targetTimestamp;
    if (target.isNegative) target = Duration.zero;

    if (target > videoDuration) {
      seekNotice.value =
          'Match timestamp ($targetTimestampText) is past the end of this '
          'video, so playback was moved to the last frame.';
      target = videoDuration;
    } else if (isTimestampApproximate) {
      seekNotice.value =
          'Timestamp is approximate — V-Modal reports wall-clock times, so this '
          'offset is measured from the earliest match in the result set.';
    }

    if (target > Duration.zero) {
      await controller.seekTo(target);
      currentPosition.value = target;
    }
  }

  void _videoListener() {
    final vpc = videoPlayerController;
    if (vpc == null) return;

    currentPosition.value = vpc.value.position;
    isPlaying.value = vpc.value.isPlaying;
    isBuffering.value = vpc.value.isBuffering;
  }

  void togglePlayPause() {
    final vpc = videoPlayerController;
    if (vpc == null || !isInitialized.value) return;

    if (vpc.value.isPlaying) {
      vpc.pause();
    } else {
      vpc.play();
    }
  }

  void seekTo(Duration position) {
    videoPlayerController?.seekTo(position);
  }

  @override
  void onClose() {
    videoPlayerController?.removeListener(_videoListener);
    videoPlayerController?.dispose();
    super.onClose();
  }
}
