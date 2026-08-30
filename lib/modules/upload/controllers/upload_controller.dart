import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:vmodal_sdk_flutter/vmodal_sdk_flutter.dart' hide Routes;

import '../../../app/routes/app_routes.dart';
import '../../../core/services/indexing_service.dart';
import '../../../core/services/video_service.dart';
import '../../../core/services/vmodal_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/models/video_model.dart';

class UploadController extends GetxController {
  final VModalService vmodalService = Get.find<VModalService>();
  final VideoService videoService = Get.find<VideoService>();
  final IndexingService indexingService = Get.find<IndexingService>();

  UploadTask<VideoUploadResponse>? _uploadTask;
  StreamSubscription<UploadProgress>? _progressSub;

  final uploadProgress = 0.0.obs;

  final _isUploading = false.obs;

  /// True while either half of the flow is running. Indexing state is read from
  /// the service, so returning to this screen mid-job still shows a busy UI.
  bool get isProcessing =>
      _isUploading.value || indexingService.isIndexing.value;

  /// Job id / status live on [IndexingService] so they survive navigation.
  RxString get jobId => indexingService.jobId;
  RxString get indexStatus => indexingService.indexStatus;

  final _localStatus = 'Select a wildlife video to analyze.'.obs;

  /// Prefers the indexing service's message while a job is active, so the
  /// Upload screen shows live progress even after being rebuilt.
  String get statusMessage {
    final indexMessage = indexingService.statusMessage.value;
    return indexMessage.isNotEmpty ? indexMessage : _localStatus.value;
  }

  VideoModel? get currentVideo => videoService.currentVideo;

  @override
  void onInit() {
    super.onInit();
    if (currentVideo != null) {
      _updateStatusFromVideo(currentVideo!);
    }
  }

  void _updateStatusFromVideo(VideoModel video) {
    switch (video.status) {
      case VideoStatus.idle:
      case VideoStatus.selected:
        _localStatus.value = 'Selected: ${video.fileName}. Ready to upload.';
        break;
      case VideoStatus.uploading:
        _localStatus.value = 'Uploading video footage...';
        break;
      case VideoStatus.indexing:
        _localStatus.value = 'Indexing video with V-Modal...';
        break;
      case VideoStatus.indexed:
        _localStatus.value = 'Indexing complete! Ready to search.';
        break;
      case VideoStatus.error:
        _localStatus.value = video.errorMessage ?? 'Operation failed.';
        break;
    }
  }

  Future<void> selectVideo() async {
    try {
      final video = await videoService.pickVideo();
      if (video != null) {
        uploadProgress.value = 0.0;
        indexingService.reset();
        _localStatus.value =
            'Selected: ${video.fileName} (${video.formattedSize})';
      }
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    }
  }

  Future<void> startUploadAndIndex() async {
    final video = currentVideo;
    if (video == null) {
      SnackbarUtils.showInfo('Please select a video file first.');
      return;
    }

    if (!vmodalService.isConfigured) {
      SnackbarUtils.showInfo('Please configure your V-Modal API Key first.');
      return;
    }

    final file = File(video.filePath);
    if (!file.existsSync()) {
      SnackbarUtils.showError('Video file path does not exist on disk.');
      return;
    }

    try {
      _isUploading.value = true;
      uploadProgress.value = 0.0;
      _localStatus.value = 'Uploading...';
      videoService.updateVideoStatus(
        video.id,
        VideoStatus.uploading,
        progress: 0.0,
      );

      // Start V-Modal Upload. Upload, index and search must all target the
      // same per-video stream, so they all read it off the model.
      _uploadTask = vmodalService.uploadVideo(
        file,
        collectionName: video.collectionName,
        streamName: video.streamName,
      );

      await _progressSub?.cancel();
      _progressSub = _uploadTask!.progress.listen((progress) {
        uploadProgress.value = progress.percent.toDouble();
        videoService.updateVideoStatus(
          video.id,
          VideoStatus.uploading,
          progress: progress.percent.toDouble(),
        );
      });

      // Await upload completion
      await _uploadTask!.result;
      uploadProgress.value = 100.0;

      // Start Indexation
      _localStatus.value =
          'Indexing video... Submitting indexing job to V-Modal.';
      videoService.updateVideoStatus(
        video.id,
        VideoStatus.indexing,
        progress: 100.0,
      );

      await _submitIndexing(video);
    } on OperationCanceled {
      _isUploading.value = false;
      _localStatus.value = 'Upload canceled by user.';
      videoService.updateVideoStatus(video.id, VideoStatus.selected);
      SnackbarUtils.showInfo('Upload operation canceled.');
    } catch (e) {
      _isUploading.value = false;
      _localStatus.value = 'Upload failed: ${e.toString()}';
      videoService.updateVideoStatus(
        video.id,
        VideoStatus.error,
        error: e.toString(),
      );
      SnackbarUtils.showError('Upload failed: ${e.toString()}');
    }
  }

  /// Re-indexes an already uploaded video without uploading the local file.
  /// The backend rejects this when the stream does not exist, and the error is
  /// kept visible on the video instead of being reported as a false success.
  Future<void> reindexCurrentVideo() async {
    final video = currentVideo;
    if (video == null) {
      SnackbarUtils.showInfo('Please select a video file first.');
      return;
    }
    if (!vmodalService.isConfigured) {
      SnackbarUtils.showInfo('Please configure your V-Modal API Key first.');
      return;
    }
    if (isProcessing) return;

    try {
      _isUploading.value = true;
      await _submitIndexing(video);
      _isUploading.value = false;
    } catch (e) {
      _isUploading.value = false;
      _localStatus.value = 'Re-index failed: ${e.toString()}';
      videoService.updateVideoStatus(
        video.id,
        VideoStatus.error,
        error: e.toString(),
      );
      SnackbarUtils.showError('Re-index failed: ${e.toString()}');
    }
  }

  Future<void> _submitIndexing(VideoModel video) async {
    videoService.updateVideoStatus(
      video.id,
      VideoStatus.indexing,
      progress: 100.0,
    );
    _localStatus.value = 'Submitting indexing job to V-Modal...';

    final indexResponse = await vmodalService.createIndex(
      collectionName: video.collectionName,
      streamName: video.streamName,
    );
    if (indexResponse.jobId.trim().isEmpty) {
      throw StateError('V-Modal returned an empty indexing job ID.');
    }

    indexStatus.value = indexResponse.status.isEmpty
        ? 'queued'
        : indexResponse.status;
    videoService.updateVideoStatus(
      video.id,
      VideoStatus.indexing,
      jobId: indexResponse.jobId,
    );

    // Keep polling in the permanent service so navigation does not interrupt
    // the long-running indexing job.
    indexingService.startPolling(
      videoId: video.id,
      jobIdToPoll: indexResponse.jobId,
      collectionName: video.collectionName,
      streamName: video.streamName,
    );
  }

  void cancelUpload() {
    _uploadTask?.cancel();
    indexingService.stopPolling();
    _isUploading.value = false;
  }

  void removeCurrentVideo() {
    _uploadTask?.cancel();
    _progressSub?.cancel();
    _uploadTask = null;
    _progressSub = null;
    _isUploading.value = false;
    uploadProgress.value = 0.0;
    indexingService.reset();
    _localStatus.value = 'Select a wildlife video to analyze.';
    videoService.clearCurrentVideo();
  }

  void goToSearch() {
    Get.offNamed(AppRoutes.search);
  }

  @override
  void onClose() {
    // Only the upload is tied to this screen. Indexing intentionally keeps
    // running on IndexingService after this controller is disposed.
    _uploadTask?.cancel();
    _progressSub?.cancel();
    super.onClose();
  }
}
