import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/video_service.dart';
import '../../../core/services/vmodal_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/models/video_model.dart';

class HomeController extends GetxController {
  final VModalService vmodalService = Get.find<VModalService>();
  final VideoService videoService = Get.find<VideoService>();

  final apiKeyController = TextEditingController();
  final isConnecting = false.obs;

  VideoModel? get currentVideo => videoService.currentVideo;
  bool get hasIndexedVideo => currentVideo?.status == VideoStatus.indexed;

  @override
  void onInit() {
    super.onInit();
    if (vmodalService.isConfigured) {
      apiKeyController.text = vmodalService.apiKey;
    }
  }

  Future<void> saveApiKey(String apiKey) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      SnackbarUtils.showError('Please enter a valid V-Modal API Key.');
      return;
    }

    try {
      isConnecting.value = true;
      await vmodalService.configure(key);
      SnackbarUtils.showSuccess('V-Modal SDK configured successfully!');
    } catch (e) {
      SnackbarUtils.showError('Configuration failed: ${e.toString()}');
    } finally {
      isConnecting.value = false;
    }
  }

  void goToUpload() {
    Get.toNamed(AppRoutes.upload);
  }

  void goToSearch() {
    if (!vmodalService.isConfigured) {
      SnackbarUtils.showInfo('Please configure your V-Modal API key first.');
      return;
    }
    if (!hasIndexedVideo) {
      SnackbarUtils.showInfo('Please upload and index a video footage before searching.');
      Get.toNamed(AppRoutes.upload);
      return;
    }
    Get.toNamed(AppRoutes.search);
  }

  @override
  void onClose() {
    apiKeyController.dispose();
    super.onClose();
  }
}
