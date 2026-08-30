import 'package:get/get.dart';
import '../../modules/home/bindings/home_binding.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/upload/bindings/upload_binding.dart';
import '../../modules/upload/views/upload_view.dart';
import '../../modules/search/bindings/search_binding.dart';
import '../../modules/search/views/search_view.dart';
import '../../modules/player/bindings/player_binding.dart';
import '../../modules/player/views/player_view.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.home;

  static final routes = [
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.upload,
      page: () => const UploadView(),
      binding: UploadBinding(),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchView(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: AppRoutes.player,
      page: () => const PlayerView(),
      binding: PlayerBinding(),
    ),
  ];
}
