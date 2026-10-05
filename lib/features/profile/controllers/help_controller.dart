import 'package:get/get.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/profile/models/response/DocumentModel.dart';
import 'package:masti_adda_app/features/profile/models/response/help_response.dart';
import 'package:masti_adda_app/features/profile/repositories/profile_datasource.dart';

class HelpController extends GetxController {
  static HelpController get to => Get.isRegistered<HelpController>()
      ? Get.find<HelpController>()
      : Get.put(HelpController());

  // ── State ─────────────────────────────────────────────────────────────────
  final helpStatus = Status.init.obs;
  final Rx<HelpResponse?> helps = Rx(null);

  final documentStatus = Status.init.obs;
  final Rx<DocumentModel?> documents = Rx(null);

  final singleDocumentStatus = Status.init.obs;
  final Rx<Document?> singleDocument = Rx(null);

  final ProfileDatasource _api = ProfileDatasource();

  @override
  void onInit() {
    super.onInit();
    if (helps.value == null) {
      fetchAllHelp();
    }
  }

  /// Extracts the support phone number from fetched help data
  String get supportNumber {
    final list = helps.value?.helpData ?? [];
    // 1. Check contact-support category first
    for (final item in list) {
      if (item.category == 'contact-support' &&
          item.supportNumber.trim().isNotEmpty) {
        return item.supportNumber.trim();
      }
    }
    // 2. Fallback to any item with non-empty supportNumber
    for (final item in list) {
      if (item.supportNumber.trim().isNotEmpty) {
        return item.supportNumber.trim();
      }
    }
    return '';
  }

  /// Extracts the support email from fetched help data
  String get supportEmail {
    final list = helps.value?.helpData ?? [];
    for (final item in list) {
      if (item.category == 'contact-support' &&
          item.supportEmail.trim().isNotEmpty) {
        return item.supportEmail.trim();
      }
    }
    for (final item in list) {
      if (item.supportEmail.trim().isNotEmpty) {
        return item.supportEmail.trim();
      }
    }
    return '';
  }

  /// Returns support number after ensuring it is fetched
  Future<String> fetchSupportNumber() async {
    if (supportNumber.isNotEmpty) return supportNumber;
    await fetchAllHelp();
    return supportNumber;
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> fetchAllHelp() async {
    helpStatus.value = Status.loading;
    final result = await _api.allHelp();
    if (result != null) {
      helps.value = result;
      helpStatus.value = Status.success;
    } else {
      helpStatus.value = Status.error;
    }
  }

  Future<void> fetchDocuments() async {
    documentStatus.value = Status.loading;
    final result = await _api.getDocument();
    if (result != null) {
      documents.value = result;
      documentStatus.value = Status.success;
    } else {
      documentStatus.value = Status.error;
    }
  }

  Future<void> fetchSingleDocument({required String id}) async {
    singleDocumentStatus.value = Status.loading;
    final result = await _api.getSingleDocument(id: id);
    if (result != null) {
      singleDocument.value = result;
      singleDocumentStatus.value = Status.success;
    } else {
      singleDocumentStatus.value = Status.error;
    }
  }
}
