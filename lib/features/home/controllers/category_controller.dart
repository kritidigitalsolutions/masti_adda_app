import 'package:get/get.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/home/models/category_detail_model.dart';
import 'package:masti_adda_app/features/home/models/category_model.dart';
import 'package:masti_adda_app/features/home/repositories/home_datasource.dart';

class CategoryController extends GetxController {
  // ── State ─────────────────────────────────────────────────────────────────
  final _api = HomeDatasource();
  final categoryStatus = Status.init.obs;
  final Rx<CategoriesResponse?> allCategories = Rx(null);

  final detailCategoryStatus = Status.init.obs;
  final Rx<CategoryContentResponse?> categoryDetail = Rx(null);

  final pageNo = 0.obs;
  final int pageSize = 10;
  final hasMore = false.obs;

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> fetchAllCategories() async {
    categoryStatus.value = Status.loading;
    final result = await _api.allCategories();
    if (result != null) {
      allCategories.value = result;
      categoryStatus.value = Status.success;
    } else {
      categoryStatus.value = Status.error;
    }
  }

  Future<void> fetchCategoryDetail(String id) async {
    detailCategoryStatus.value = Status.loading;
    pageNo.value = 0;
    hasMore.value = true;

    final result = await _api.categoryDetail(id: id, page: 0, size: pageSize);

    if (result != null) {
      categoryDetail.value = result;
      detailCategoryStatus.value = Status.success;
      pageNo.value = 0;
      hasMore.value = result.content.length == pageSize;
    } else {
      detailCategoryStatus.value = Status.error;
    }
  }

  Future<void> loadMore(String id) async {
    if (detailCategoryStatus.value == Status.loading || !hasMore.value) return;

    detailCategoryStatus.value = Status.loading;
    final nextPage = pageNo.value + 1;

    final result = await _api.categoryDetail(
      id: id,
      page: nextPage,
      size: pageSize,
    );

    if (result != null) {
      final oldContent = categoryDetail.value?.content ?? [];
      final updatedContent = [...oldContent, ...result.content];
      categoryDetail.value = result.copyWith(content: updatedContent);
      pageNo.value = nextPage;
      hasMore.value = result.content.length == pageSize;
      detailCategoryStatus.value = Status.success;
    } else {
      detailCategoryStatus.value = Status.error;
    }
  }
}
