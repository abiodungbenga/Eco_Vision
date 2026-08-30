import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/video_service.dart';
import '../../../core/services/vmodal_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/models/search_result_model.dart';
import '../../../shared/models/video_model.dart';

class SearchViewController extends GetxController {
  final VModalService vmodalService = Get.find<VModalService>();
  final VideoService videoService = Get.find<VideoService>();

  final queryTextController = TextEditingController();
  final searchResults = <SearchResultModel>[].obs;
  final isSearching = false.obs;
  final hasSearched = false.obs;
  final activeQuery = ''.obs;
  final executionTimeMs = 0.0.obs;
  final totalMatches = 0.obs;
  final errorMessage = ''.obs;

  VideoModel? get currentVideo => videoService.currentVideo;

  @override
  void onInit() {
    super.onInit();
    queryTextController.text = AppConstants.sampleQueries.first;
  }

  void selectSampleQuery(String sample) {
    queryTextController.text = sample;
    performSearch();
  }

  Future<void> performSearch() async {
    final query = queryTextController.text.trim();
    if (query.isEmpty) {
      SnackbarUtils.showInfo('Please enter a search query.');
      return;
    }

    if (!vmodalService.isConfigured) {
      SnackbarUtils.showError('V-Modal SDK is not configured. Please add an API key.');
      return;
    }

    final video = currentVideo;
    if (video == null) {
      SnackbarUtils.showInfo('Please select and index a video first.');
      return;
    }

    try {
      isSearching.value = true;
      hasSearched.value = true;
      errorMessage.value = '';
      activeQuery.value = query;
      searchResults.clear();

      final response = await vmodalService.searchVideo(
        query: query,
        collectionName: video.collectionName,
        streamName: video.streamName,
      );

      executionTimeMs.value = response.executionTimeMs;
      totalMatches.value = response.cntTotal;

      // Collected first, then resolved together: in-video offsets are derived
      // from the earliest timestamp across the whole response.
      final hits = <Map<String, dynamic>>[];
      for (final rawHit in response.data) {
        if (rawHit is Map<String, dynamic>) {
          hits.add(rawHit);
        } else if (rawHit is Map) {
          hits.add(rawHit.map((k, v) => MapEntry('$k', v)));
        }
      }

      searchResults.value = SearchResultModel.resolveTimestamps(
        hits,
        query: query,
        videoPath: video.filePath,
      );
    } on SearchException catch (e) {
      // VModalService already translated API failures (including the
      // missing-LanceDB 404) into a message worth showing.
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Search failed: ${e.toString()}';
    } finally {
      isSearching.value = false;
    }
  }

  void watchMoment(SearchResultModel result) {
    final video = currentVideo;
    if (video == null || video.filePath.isEmpty) {
      SnackbarUtils.showError('Video file path is not available.');
      return;
    }

    Get.toNamed(
      AppRoutes.player,
      arguments: {
        'videoPath': video.filePath,
        'videoName': video.fileName,
        'timestamp': result.timestampDuration,
        'timestampText': result.formattedTimestamp,
        'title': result.title,
        'hasTimestamp': result.hasTimestamp,
        'isTimestampApproximate': result.isTimestampApproximate,
      },
    );
  }

  @override
  void onClose() {
    queryTextController.dispose();
    super.onClose();
  }
}
