import 'package:get/get.dart';
import 'package:localstore/localstore.dart';
import '../../shared/models/search_result_model.dart';
import 'vmodal_service.dart';
import 'video_service.dart';
import '../utils/thumbnail_utils.dart';

class DiscoveryService extends GetxService {
  final VModalService vmodalService = Get.find<VModalService>();
  final VideoService videoService = Get.find<VideoService>();
  final _db = Localstore.instance;
  static const String _collectionPath = 'observations';

  final sightingsFeed = <SearchResultModel>[].obs;
  final savedObservations = <SearchResultModel>[].obs;
  final isFetchingFeed = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final items = await _db.collection(_collectionPath).get();
    if (items != null) {
      final loaded = items.entries
          .map((e) => SearchResultModel.fromJson(e.value))
          .toList();
      savedObservations.assignAll(await _enrichResultsWithLocalThumbnails(loaded));
    }
  }

  /// Fetches a broad "Sightings" feed from the entire collection.
  Future<void> fetchSightingsFeed() async {
    if (!vmodalService.isConfigured) return;

    try {
      isFetchingFeed.value = true;
      // Search for any "wildlife" or "animal" to get an aggregate feed
      final response = await vmodalService.searchCollection(query: 'animal wildlife activity');

      final hits = <Map<String, dynamic>>[];
      for (final rawHit in response.data) {
        if (rawHit is Map<String, dynamic>) {
          hits.add(rawHit);
        } else if (rawHit is Map) {
          hits.add(rawHit.map((k, v) => MapEntry('$k', v)));
        }
      }

      final results = SearchResultModel.resolveTimestamps(
        hits,
        query: 'Sightings',
        videoPath: '', 
      );

      // Resolve thumbnails for discovery feed from backend
      final remoteResults = await vmodalService.resolveThumbnails(results);

      // Override with local thumbnails where possible (using video_snapshot_generator)
      sightingsFeed.value = await _enrichResultsWithLocalThumbnails(remoteResults);
    } catch (e) {
      // Silently fail or log for feed
    } finally {
      isFetchingFeed.value = false;
    }
  }

  Future<void> toggleBookmark(SearchResultModel result) async {
    final index = savedObservations.indexWhere((o) => o.id == result.id);
    if (index != -1) {
      savedObservations.removeAt(index);
      await _db.collection(_collectionPath).doc(result.id).delete();
    } else {
      savedObservations.add(result);
      await _db.collection(_collectionPath).doc(result.id).set(result.toJson());
    }
  }

  bool isBookmarked(SearchResultModel result) {
    return savedObservations.any((o) => o.id == result.id);
  }

  Future<List<SearchResultModel>> _enrichResultsWithLocalThumbnails(
      List<SearchResultModel> results) async {
    final enriched = <SearchResultModel>[];

    for (var result in results) {
      String? path = result.videoPath.isNotEmpty ? result.videoPath : null;

      // Try to find local path from history if not present
      if (path == null) {
        final localVideo = videoService.videoHistory.firstWhereOrNull(
          (v) => v.fileName == result.videoFileName,
        );
        if (localVideo != null) {
          path = localVideo.filePath;
          result = result.copyWith(videoPath: path);
        }
      }

      // If we have a local path, try generating a local thumbnail
      if (path != null && path.isNotEmpty) {
        final localThumb = await ThumbnailUtils.generateVideoThumbnail(
          videoPath: path,
          timeMs: result.timestampMs,
        );
        if (localThumb != null) {
          result = result.copyWith(thumbnailUrl: localThumb);
        }
      }
      enriched.add(result);
    }
    return enriched;
  }
}
