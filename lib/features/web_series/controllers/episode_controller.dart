import 'package:get/get.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/web_series/datasource/series_datasource.dart';
import 'package:masti_adda_app/features/web_series/model/episode_response.dart';
import 'package:masti_adda_app/features/web_series/model/episode_model.dart';

class EpisodeController extends GetxController {
  // ── State ─────────────────────────────────────────────────────────────────
  final allEpisodeStatus = Status.init.obs;
  final Rx<EpisodesResponse?> allEpisode = Rx(null);

  final detailEpisodeStatus = Status.init.obs;
  final Rx<EpisodeModel?> episodeDetail = Rx(null);

  // ── Actions ───────────────────────────────────────────────────────────────

  final _api = SeriesDatasource();

  Future<void> fetchAllEpisodes(String id) async {
    allEpisodeStatus.value = Status.loading;
    final result = await _api.allEpisode(id: id);
    if (result != null) {
      allEpisode.value = result;
      allEpisodeStatus.value = Status.success;
    } else {
      allEpisodeStatus.value = Status.error;
    }
  }

  Future<void> fetchEpisodeDetail(String id) async {
    detailEpisodeStatus.value = Status.loading;
    final result = await _api.singleEpisode(id: id);
    if (result != null) {
      episodeDetail.value = result;
      detailEpisodeStatus.value = Status.success;
    } else {
      detailEpisodeStatus.value = Status.error;
    }
  }
}
