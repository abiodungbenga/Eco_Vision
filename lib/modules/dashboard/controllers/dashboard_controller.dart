import 'dart:io';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/video_service.dart';
import '../../../core/services/research_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/models/observation_model.dart';
import '../../../shared/models/species_model.dart';

class DashboardController extends GetxController {
  final VideoService videoService = Get.find<VideoService>();
  final ResearchService researchService = Get.find<ResearchService>();

  final videosAnalyzed = 0.obs;
  final observationCount = 0.obs;
  final speciesCount = 0.obs;
  final monthlySearchCount = 0.obs;

  final mostObservedSpecies = <SpeciesModel>[].obs;
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
      
      final species = researchService.getDerivedSpecies();
      speciesCount.value = species.length;
      mostObservedSpecies.assignAll(species);
      
      monthlySearchCount.value = researchService.getMonthlySearchCount();
      recentObservations.assignAll(researchService.observations.take(5));
    } catch (_) {
      // Fail gracefully
    }
  }

  void watchObservation(ObservationModel obs) {
    if (obs.videoPath.isEmpty || !File(obs.videoPath).existsSync()) {
      SnackbarUtils.showError('Video file path is not available or file does not exist locally.');
      return;
    }

    Get.toNamed(
      AppRoutes.player,
      arguments: {
        'videoPath': obs.videoPath,
        'videoName': obs.videoName,
        'timestamp': Duration(milliseconds: obs.timestampMs),
        'timestampText': obs.formattedTimestamp,
        'title': '${obs.species} - ${obs.searchQuery}',
        'hasTimestamp': true,
        'isTimestampApproximate': false,
      },
    );
  }
}
