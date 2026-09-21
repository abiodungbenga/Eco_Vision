import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../shared/models/video_model.dart';
import '../errors/app_exception.dart';

class VideoService extends GetxService {
  /// Max length VModal accepts for a stream name.
  static const int _streamNameMax = 80;
  static const String _streamPrefix = 'vid_';

  /// Builds a per-video stream name that VModal will accept.
  ///
  /// Each video gets its own stream so a search only ever returns moments from
  /// the selected video. The SDK validates stream names against
  /// `^[A-Za-z0-9_]+$` (max 80 chars) and throws `ValidationException`
  /// otherwise, so dots, dashes and spaces in the filename must all be folded
  /// to underscores — `bear video.mp4` becomes `vid_bear_video_mp4_<id>`.
  static String buildStreamName(String fileName, String id) {
    final suffix = '_$id';
    final budget = _streamNameMax - _streamPrefix.length - suffix.length;

    var base = fileName
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (budget <= 0) return 'vid$suffix';
    if (base.length > budget) base = base.substring(0, budget);
    base = base.replaceAll(RegExp(r'_+$'), '');

    // Filenames that sanitize to nothing (e.g. "日本語.mp4") still need a
    // unique, valid stream.
    return base.isEmpty ? 'vid$suffix' : '$_streamPrefix$base$suffix';
  }

  final Rxn<VideoModel> _currentVideo = Rxn<VideoModel>();
  VideoModel? get currentVideo => _currentVideo.value;

  final RxList<VideoModel> _videoHistory = <VideoModel>[].obs;
  RxList<VideoModel> get videoHistory => _videoHistory;

  /// Pick a video file from local storage using file_picker.
  Future<VideoModel?> pickVideo() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.video);

      if (result.isEmpty) {
        return null; // User cancelled
      }

      final file = result.first;
      final path = file.path;
      if (path == null || path.trim().isEmpty || !File(path).existsSync()) {
        throw AppException(
          'The selected video file has no valid readable path.',
        );
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final video = VideoModel(
        id: id,
        fileName: file.name,
        filePath: path,
        sizeBytes: File(path).lengthSync(),
        status: VideoStatus.selected,
        streamName: buildStreamName(file.name, id),
      );

      setCurrentVideo(video);
      return video;
    } catch (e) {
      throw AppException('Error selecting video: ${e.toString()}');
    }
  }

  void setCurrentVideo(VideoModel video) {
    _currentVideo.value = video;
    if (!_videoHistory.any((v) => v.filePath == video.filePath)) {
      _videoHistory.add(video);
    }
  }

  void clearCurrentVideo() {
    final currentId = _currentVideo.value?.id;
    _currentVideo.value = null;
    if (currentId != null) {
      _videoHistory.removeWhere((video) => video.id == currentId);
    }
  }

  void updateVideoStatus(
    String id,
    VideoStatus status, {
    String? jobId,
    String? error,
    double? progress,
  }) {
    if (_currentVideo.value?.id == id) {
      _currentVideo.value = _currentVideo.value!.copyWith(
        status: status,
        indexJobId: jobId ?? _currentVideo.value?.indexJobId,
        errorMessage: error,
        uploadProgress: progress ?? _currentVideo.value?.uploadProgress,
      );
    }

    final index = _videoHistory.indexWhere((v) => v.id == id);
    if (index != -1) {
      _videoHistory[index] = _videoHistory[index].copyWith(
        status: status,
        indexJobId: jobId ?? _videoHistory[index].indexJobId,
        errorMessage: error,
        uploadProgress: progress ?? _videoHistory[index].uploadProgress,
      );
    }
  }
}
