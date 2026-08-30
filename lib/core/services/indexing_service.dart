import 'dart:async';
import 'dart:developer' as developer;

import 'package:get/get.dart';

import '../../shared/models/video_model.dart';
import '../utils/snackbar_utils.dart';
import 'video_service.dart';
import 'vmodal_service.dart';

/// Owns indexing-job polling for the lifetime of the app.
///
/// Polling deliberately lives in a permanent service rather than in
/// `UploadController`: GetX disposes route-bound controllers on navigation, so
/// a controller-owned timer was cancelled the moment the user left the Upload
/// screen. Because indexing takes minutes, that left the video pinned at
/// [VideoStatus.indexing] forever and permanently blocked search.
class IndexingService extends GetxService {
  IndexingService({required this.vmodalService, required this.videoService});

  final VModalService vmodalService;
  final VideoService videoService;

  /// How often to ask the backend for job status.
  static const Duration pollInterval = Duration(seconds: 3);

  /// Give up after this long so a stuck job cannot spin forever.
  static const Duration pollDeadline = Duration(minutes: 30);

  /// Consecutive failed status calls tolerated before failing the job.
  /// Transient network blips are expected; a revoked key or bad job id is not.
  static const int maxConsecutiveFailures = 5;

  /// How long to keep waiting, after the job reports success, for the backend
  /// to advertise a published index before accepting the job's word for it.
  ///
  /// The status flips to `success` before the group listing catches up, so
  /// marking the video searchable on the status alone sends the user to a
  /// search that finds nothing.
  static const Duration publishGrace = Duration(seconds: 90);

  static const Set<String> _successStates = {
    'success',
    'succeeded',
    'done',
    'completed',
    'ok',
  };
  static const Set<String> _failureStates = {'failed', 'error', 'canceled'};

  Timer? _timer;
  String? _videoId;
  String? _collectionName;
  String? _streamName;
  DateTime? _startedAt;

  /// When the backend first reported a success state, used to bound the wait
  /// for the index to be published.
  DateTime? _jobDoneAt;

  /// Guards against overlapping polls; see [_tick].
  bool _ticking = false;

  int _consecutiveFailures = 0;

  /// Latest job id being polled, or empty.
  final jobId = ''.obs;

  /// Latest raw backend status string.
  final indexStatus = ''.obs;

  /// Human-readable progress message for the UI.
  final statusMessage = ''.obs;

  /// True while a job is actively being polled.
  final isIndexing = false.obs;

  bool get isPolling => _timer?.isActive ?? false;

  /// Begins polling [jobIdToPoll] and reports terminal state onto [videoId].
  ///
  /// [collectionName] and [streamName] must be the scope the job was submitted
  /// against, since each video has its own stream.
  void startPolling({
    required String videoId,
    required String jobIdToPoll,
    required String collectionName,
    required String streamName,
  }) {
    stopPolling();

    _videoId = videoId;
    _collectionName = collectionName;
    _streamName = streamName;
    _startedAt = DateTime.now();
    _jobDoneAt = null;
    _ticking = false;
    _consecutiveFailures = 0;
    jobId.value = jobIdToPoll;
    isIndexing.value = true;
    statusMessage.value = 'Indexing video with V-Modal...';

    _timer = Timer.periodic(pollInterval, (_) => _tick(jobIdToPoll));
  }

  /// Stops polling without changing the video's status.
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    isIndexing.value = false;
  }

  /// Serializes polls. A status call can outlive its [pollInterval] slot on a
  /// slow connection, and overlapping ticks would double-count failures and
  /// race each other to write terminal state.
  Future<void> _tick(String jobIdToPoll) async {
    if (_ticking) return;
    _ticking = true;
    try {
      await _poll(jobIdToPoll);
    } finally {
      _ticking = false;
    }
  }

  Future<void> _poll(String jobIdToPoll) async {
    final videoId = _videoId;
    if (videoId == null) {
      stopPolling();
      return;
    }

    final startedAt = _startedAt;
    // Once the job has reported success the deadline no longer applies: what
    // remains is waiting for publication, which [publishGrace] bounds instead.
    if (_jobDoneAt == null &&
        startedAt != null &&
        DateTime.now().difference(startedAt) > pollDeadline) {
      _fail(
        videoId,
        'Indexing timed out after ${pollDeadline.inMinutes} minutes. '
        'The video may be too long to index.',
      );
      return;
    }

    try {
      final statusRes = await vmodalService.checkIndexStatus(
        jobIdToPoll,
        collectionName: _collectionName,
        streamName: _streamName,
      );
      _consecutiveFailures = 0;

      final raw = statusRes.status;
      indexStatus.value = raw;
      final state = raw.toLowerCase().trim();

      if (_successStates.contains(state)) {
        _jobDoneAt ??= DateTime.now();
        await _confirmPublished(videoId, jobIdToPoll, raw);
      } else if (_failureStates.contains(state)) {
        _fail(
          videoId,
          'Indexing failed on the V-Modal backend (status: $raw).',
        );
      } else {
        statusMessage.value = 'Indexing in progress... (Status: $raw)';
      }
    } catch (e) {
      _consecutiveFailures++;
      developer.log(
        'Index status poll failed '
        '($_consecutiveFailures/$maxConsecutiveFailures): $e',
        name: 'IndexingService',
      );

      // Tolerate transient errors, but surface a persistent one instead of
      // spinning behind "Indexing in progress..." indefinitely.
      if (_consecutiveFailures >= maxConsecutiveFailures) {
        _fail(
          videoId,
          'Lost contact with V-Modal while indexing: ${e.toString()}',
        );
      } else {
        statusMessage.value =
            'Indexing in progress... (retrying status check '
            '$_consecutiveFailures/$maxConsecutiveFailures)';
      }
    }
  }

  /// Waits for the backend to actually advertise a queryable index.
  ///
  /// A `success` job status only means the job finished, not that the index is
  /// published — marking the video searchable on the status alone was sending
  /// the user straight into a search that could not find anything yet.
  Future<void> _confirmPublished(
    String videoId,
    String jobIdToPoll,
    String rawStatus,
  ) async {
    var published = false;
    try {
      final readiness = await vmodalService.resolveReadiness(
        collectionName: _collectionName,
      );
      published = readiness.isIndexPublished;
      developer.log(
        'Post-success readiness: published=$published, '
        'sources=${readiness.searchSources}, '
        'inferred=${readiness.sourcesWereInferred}, '
        'version=${readiness.versionLancedb}, '
        'versions=${readiness.lancedbVersions}',
        name: 'IndexingService.confirm',
      );
    } catch (e) {
      // A readiness lookup failing is not the job failing. Fall through to the
      // grace period rather than reporting a finished index as broken.
      developer.log(
        'Post-success readiness check failed: $e',
        name: 'IndexingService.confirm',
      );
    }

    final doneAt = _jobDoneAt;
    final waited = doneAt == null
        ? Duration.zero
        : DateTime.now().difference(doneAt);

    // Accept once confirmed, or once the grace period is spent. Giving up on
    // confirmation is safe now that search retries across advertised versions:
    // a still-settling index yields a retryable message, not a stuck screen.
    if (published || waited >= publishGrace) {
      _finish(videoId, jobIdToPoll, rawStatus, confirmed: published);
      return;
    }

    statusMessage.value =
        'Indexing finished. Waiting for V-Modal to publish the search index...';
  }

  void _finish(
    String videoId,
    String jobIdToPoll,
    String rawStatus, {
    required bool confirmed,
  }) {
    developer.log(
      'Indexing completed: videoId=$videoId, jobId=$jobIdToPoll, '
      'collection=$_collectionName, stream=$_streamName, '
      'backendStatus=$rawStatus, indexConfirmed=$confirmed',
      name: 'IndexingService.success',
    );
    stopPolling();
    statusMessage.value = confirmed
        ? 'Ready to search! Indexing completed.'
        : 'Indexing completed. The search index may take another moment to '
              'become queryable.';
    videoService.updateVideoStatus(
      videoId,
      VideoStatus.indexed,
      jobId: jobIdToPoll,
    );
    // Announced from the service, not the Upload screen, so the user still
    // hears about it if they navigated away during the long wait.
    SnackbarUtils.showSuccess(
      'Video indexing completed! You can now search moments.',
    );
  }

  void _fail(String videoId, String message) {
    stopPolling();
    statusMessage.value = message;
    videoService.updateVideoStatus(videoId, VideoStatus.error, error: message);
    SnackbarUtils.showError(message);
  }

  /// Clears all job state, e.g. when the video is removed.
  void reset() {
    stopPolling();
    _videoId = null;
    _collectionName = null;
    _streamName = null;
    _startedAt = null;
    _jobDoneAt = null;
    _ticking = false;
    _consecutiveFailures = 0;
    jobId.value = '';
    indexStatus.value = '';
    statusMessage.value = '';
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }
}
