import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/features/profile/models/response/DocumentModel.dart';
import 'package:masti_adda_app/features/profile/models/response/help_response.dart';
import 'package:masti_adda_app/features/profile/models/response/plan_model.dart';
import 'package:masti_adda_app/features/profile/models/response/subscription_status_model.dart';

class ProfileDatasource {
  final NetworkApiService _apiService = NetworkApiService();

  Future<SubscriptionStatusResponse?> fetchSubscriptionStatus() async {
    try {
      final jsonData = await _apiService.getApi(AppUrl.subscriptionStatus);
      if (jsonData != null) {
        return SubscriptionStatusResponse.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<HelpResponse?> allHelp() async {
    try {
      final jsonData = await _apiService.getApi(AppUrl.helpApi);
      if (jsonData != null) {
        return HelpResponse.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<DocumentModel?> getDocument() async {
    try {
      final jsonData = await _apiService.getApi(AppUrl.legalApi);
      if (jsonData != null) {
        return DocumentModel.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Document?> getSingleDocument({required String id}) async {
    try {
      final jsonData = await _apiService.getApi(AppUrl.singleLegalApi(id: id));
      if (jsonData != null &&
          jsonData['success'] == true &&
          jsonData['document'] != null) {
        return Document.fromJson(jsonData['document']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<SubscriptionPlansResponse?> allSubscriptionPlans() async {
    try {
      final jsonData = await _apiService.getApi(AppUrl.plan);
      if (jsonData != null) {
        return SubscriptionPlansResponse.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
