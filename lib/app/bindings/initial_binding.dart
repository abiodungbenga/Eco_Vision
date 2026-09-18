import 'package:get/get.dart';
import '../../core/services/indexing_service.dart';
import '../../core/services/video_service.dart';
import '../../core/services/vmodal_service.dart';
import '../../core/services/discovery_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final vmodal = Get.put<VModalService>(VModalService(), permanent: true);
    final videos = Get.put<VideoService>(VideoService(), permanent: true);

    // Permanent so indexing keeps polling while the user navigates away from
    // the Upload screen.
    Get.put<IndexingService>(
      IndexingService(vmodalService: vmodal, videoService: videos),
      permanent: true,
    );
    Get.put<DiscoveryService>(DiscoveryService(), permanent: true);
  }
}
