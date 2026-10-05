import 'package:masti_adda_app/features/profile/models/response/plan_model.dart';
import 'package:masti_adda_app/web/utils/web_payment_result.dart';

class WebPaymentHelper {
  static Future<WebPaymentResult> purchasePlan({
    required SubscriptionPlan plan,
    String? userName,
    String? userEmail,
    String? userContact,
    bool openInSameTab = true,
  }) async {
    return WebPaymentResult(
      success: false,
      errorMessage: 'Web payments are not available on this platform.',
    );
  }

  static String? getLocalStorageItem(String key) => null;
  static void removeLocalStorageItem(String key) {}
}
