import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/video_service.dart';
import '../../../core/services/vmodal_service.dart';
import '../../../core/services/research_service.dart';
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

  final referenceImage = Rxn<File>();
  final isGlobalSearch = false.obs;

  VideoModel? get currentVideo => videoService.currentVideo;

  @override
  void onInit() {
    super.onInit();
    if (AppConstants.semanticChips.isNotEmpty) {
      final firstQuery = AppConstants.semanticChips.first['query'];
      if (firstQuery != null) {
        queryTextController.text = firstQuery;
      }
    }
  }

  void selectSampleQuery(String sample) {
    queryTextController.text = sample;
    performSearch();
  }

  Future<void> pickReferenceImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result.isNotEmpty) {
        final file = result.first;
        if (file.path != null) {
          referenceImage.value = File(file.path!);
          // Clear text query when picking an image to indicate image search
          queryTextController.clear();
        }
      }
    } catch (e) {
      SnackbarUtils.showError('Failed to pick image: $e');
    }
  }

  void clearReferenceImage() {
    referenceImage.value = null;
  }

  Future<void> performSearch() async {
    final query = queryTextController.text.trim();
    final image = referenceImage.value;

    if (query.isEmpty && image == null) {
      SnackbarUtils.showInfo('Please enter a search query or pick a reference image.');
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
      activeQuery.value = query.isNotEmpty ? query : 'Image Reference';
      searchResults.clear();

      String? imageBase64;
      if (image != null) {
        final bytes = await image.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final response = isGlobalSearch.value
          ? await vmodalService.searchCollection(
              query: query,
              imageQuery: imageBase64,
              collectionName: video.collectionName,
            )
          : await vmodalService.searchVideo(
              query: query,
              imageQuery: imageBase64,
              collectionName: video.collectionName,
              streamName: video.streamName,
            );

      executionTimeMs.value = response.executionTimeMs;
      totalMatches.value = response.cntTotal;

      if (query.isNotEmpty) {
        Get.find<ResearchService>().logSearch(query);
      }

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
        query: activeQuery.value,
        videoPath: video.filePath,
      );

      // Resolve thumbnails for results
      final updatedResults = await vmodalService.resolveThumbnails(
        searchResults,
        collectionName: video.collectionName,
      );

      final finalResults = updatedResults.map((res) {
        final match = videoService.videoHistory.firstWhereOrNull((v) => v.fileName == res.videoFileName);
        if (match != null) {
          return res.copyWith(videoPath: match.filePath);
        }
        return res;
      }).toList();

      searchResults.value = finalResults;
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
    final path = result.videoPath.isNotEmpty ? result.videoPath : (currentVideo?.filePath ?? '');
    final name = result.videoFileName.isNotEmpty ? result.videoFileName : (currentVideo?.fileName ?? 'Wildlife Footage');

    if (path.isEmpty || !File(path).existsSync()) {
      SnackbarUtils.showError('Video file path is not available or file does not exist locally.');
      return;
    }

    Get.toNamed(
      AppRoutes.player,
      arguments: {
        'videoPath': path,
        'videoName': name,
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
