import 'package:get/get.dart';
import '../controllers/observations_controller.dart';

class ObservationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ObservationsController>(() => ObservationsController());
  }
}
