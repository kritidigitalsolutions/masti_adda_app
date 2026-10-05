import 'package:get/get.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/micro_drama/datasource/micro_drama_datasource.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_model.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_detail_response.dart' hide Microdrama;
import 'package:masti_adda_app/features/micro_drama/models/episode_detail_response.dart';
import 'package:masti_adda_app/shared/models/like_dislike_response.dart';

class MicroDramaController extends GetxController {
  // ── State ─────────────────────────────────────────────────────────────────
  final allMicroDramaStatus = Status.init.obs;
  final Rx<MicrodramasResponse?> allMicroDrama = Rx(null);
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  int currentPage = 1;
  static const int pageSize = 12;

  final detailDramaStatus = Status.init.obs;
  final Rx<MicrodramaDetailResponse?> dramaDetail = Rx(null);

  final episodeDetailStatus = Status.init.obs;
  final Rx<MicroDramaEpisodesResponse?> episodeDetail = Rx(null);

  final _api = MicroDramaDatasource();

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> fetchAllMicroDrama() async {
    currentPage = 1;
    hasMore.value = true;
    allMicroDramaStatus.value = Status.loading;
    final result = await _api.allMicroDrama(page: 1, limit: pageSize);
    if (result != null) {
      allMicroDrama.value = result;
      if (result.microdramas.length < pageSize) {
        hasMore.value = false;
      }
      allMicroDramaStatus.value = Status.success;
    } else {
      allMicroDramaStatus.value = Status.error;
    }
  }

  Future<void> fetchMoreMicroDrama() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = currentPage + 1;
      final result = await _api.allMicroDrama(page: nextPage, limit: pageSize);
      if (result != null && result.microdramas.isNotEmpty) {
        final current = allMicroDrama.value;
        if (current != null) {
          final existingIds = current.microdramas.map((m) => m.id).toSet();
          final newDramas = result.microdramas.where((m) => !existingIds.contains(m.id)).toList();
          if (newDramas.isNotEmpty) {
            final combined = List<Microdrama>.from(current.microdramas)..addAll(newDramas);
            allMicroDrama.value = current.copyWith(microdramas: combined);
            currentPage = nextPage;
          } else {
            hasMore.value = false;
          }
          if (result.microdramas.length < pageSize) {
            hasMore.value = false;
          }
        }
      } else {
        hasMore.value = false;
      }
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchDramaDetail(String id) async {
    detailDramaStatus.value = Status.loading;
    final result = await _api.dramaDetail(id: id);
    if (result != null) {
      dramaDetail.value = result;
      detailDramaStatus.value = Status.success;
    } else {
      detailDramaStatus.value = Status.error;
    }
  }

  Future<void> fetchEpisodeDetail(String id) async {
    episodeDetailStatus.value = Status.loading;
    final result = await _api.episodeDetail(id: id);
    if (result != null) {
      episodeDetail.value = result;
      episodeDetailStatus.value = Status.success;
    } else {
      episodeDetailStatus.value = Status.error;
    }
  }

  Future<LikeDislikeResponse?> toggleLike(String id) async {
    try {
      final res = await _api.toggleLike(id);
      if (res != null && res.success) {
        if (episodeDetail.value != null) {
          final eps = episodeDetail.value!.episodes.map((ep) {
            if (ep.id == id) {
              return ep.copyWith(likes: res.totalLikes);
            }
            return ep;
          }).toList();
          episodeDetail.value = episodeDetail.value!.copyWith(episodes: eps);
        }
      }
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<LikeDislikeResponse?> toggleDislike(String id) async {
    try {
      final res = await _api.toggleDislike(id);
      return res;
    } catch (_) {
      return null;
    }
  }
}
