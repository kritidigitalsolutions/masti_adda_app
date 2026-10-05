import 'package:get/get.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/home/models/content_model.dart';
import 'package:masti_adda_app/features/home/repositories/home_datasource.dart';

class ContentController extends GetxController {
  // ── State ─────────────────────────────────────────────────────────────────
  final allContentStatus = Status.init.obs;
  final Rx<HomeContentResponse?> allContents = Rx(null);

  final searchContentStatus = Status.init.obs;
  final Rx<HomeContentResponse?> searchContents = Rx(null);

  final _api = HomeDatasource();

  // ── Actions ───────────────────────────────────────────────────────────────
  // Future<void> fetchAllContent() async {
  //   allContentStatus.value = Status.loading;
  //   final result = await _api.allContent();
  //   if (result != null) {
  //     allContents.value = result;
  //     allContentStatus.value = Status.success;
  //   } else {
  //     allContentStatus.value = Status.error;
  //   }
  // }

  Future<void> searchContent(String query) async {
    if (query.trim().isEmpty) {
      searchContentStatus.value = Status.init;
      searchContents.value = null;
      return;
    }
    searchContentStatus.value = Status.loading;
    final result = await _api.searchContent(query.trim());
    if (result != null) {
      searchContents.value = result;
      searchContentStatus.value = Status.success;
    } else {
      searchContentStatus.value = Status.error;
    }
  }
}
