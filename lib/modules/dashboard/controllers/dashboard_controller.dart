import 'package:get/get.dart';

import '../../../core/services/video_service.dart';
import '../../../core/services/research_service.dart';
import '../../../shared/models/observation_model.dart';

class DashboardController extends GetxController {
  final VideoService videoService = Get.find<VideoService>();
  final ResearchService researchService = Get.find<ResearchService>();

  final videosAnalyzed = 0.obs;
  final observationCount = 0.obs;
  final monthlySearchCount = 0.obs;

  final recentObservations = <ObservationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    updateStats();
    ever(researchService.observations, (_) => updateStats());
    ever(researchService.searchHistory, (_) => updateStats());
    ever(videoService.videoHistory, (_) => updateStats());
  }

  void updateStats() {
    try {
      videosAnalyzed.value = videoService.videoHistory.length;
      observationCount.value = researchService.observations.length;

      monthlySearchCount.value = researchService.getMonthlySearchCount();
      recentObservations.assignAll(researchService.observations.take(5));
    } catch (_) {
      // Fail gracefully
    }
  }
}
