import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/features/profile/models/response/company_info_model.dart';

class CompanyInfoController extends GetxController {
  static CompanyInfoController get to =>
      Get.isRegistered<CompanyInfoController>()
          ? Get.find<CompanyInfoController>()
          : Get.put(CompanyInfoController());

  final NetworkApiService _apiService = NetworkApiService();

  final Rx<CompanyInfoModel> companyInfo = const CompanyInfoModel().obs;
  final RxBool isLoading = false.obs;
  final RxBool hasFetched = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompanyInfo();
  }

  Future<void> fetchCompanyInfo({bool isRefresh = false}) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      final dynamic jsonData = await _apiService.getApi(AppUrl.companyInfo);

      if (jsonData != null && jsonData is Map<String, dynamic>) {
        final response = CompanyInfoResponse.fromJson(jsonData);
        if (response.success && response.data != null) {
          companyInfo.value = response.data!;
          hasFetched.value = true;
        }
      }
    } catch (e) {
      debugPrint("❌ CompanyInfoController: Error fetching company info: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
