import 'dart:io';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/research_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/models/observation_model.dart';
import '../../../shared/models/species_model.dart';

class ObservationsController extends GetxController {
  final ResearchService researchService = Get.find<ResearchService>();

  final speciesList = <SpeciesModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadObservations();
    ever(researchService.observations, (_) => loadObservations());
  }

  void loadObservations() {
    isLoading.value = true;
    try {
      speciesList.assignAll(researchService.getDerivedSpecies());
    } catch (_) {
      // Fail gracefully
    } finally {
      isLoading.value = false;
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
