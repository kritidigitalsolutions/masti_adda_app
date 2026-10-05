import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/features/profile/models/response/watchlist_model.dart';

class WatchlistRepository {
  final NetworkApiService _apiService = NetworkApiService();

  /// 📥 Fetch User's Watchlist
  Future<WatchlistResponse?> fetchWatchlist() async {
    try {
      final response = await _apiService.getApi(AppUrl.watchlist);
      if (response != null) {
        return WatchlistResponse.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint("Error in fetchWatchlist: $e");
      return null;
    }
  }

  /// ➕ Add Item to Watchlist
  Future<dynamic> addToWatchlist(String itemId) async {
    try {
      final response = await _apiService.postApi(AppUrl.watchlist, {
        "itemId": itemId,
      });
      return response;
    } catch (e) {
      debugPrint("Error in addToWatchlist: $e");
      return {"success": false, "message": e.toString()};
    }
  }

  /// ❌ Remove Item from Watchlist by Watchlist Record ID
  Future<dynamic> removeFromWatchlist(String watchlistId) async {
    try {
      final response = await _apiService.deleteApi(
        AppUrl.deleteWatchlist(watchlistId),
        {},
      );
      return response;
    } catch (e) {
      debugPrint("Error in removeFromWatchlist: $e");
      return {"success": false, "message": e.toString()};
    }
  }
}
