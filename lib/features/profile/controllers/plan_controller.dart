import 'package:get/get.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/profile/models/response/plan_model.dart';
import 'package:masti_adda_app/features/profile/repositories/profile_datasource.dart';

class PlanController extends GetxController {
  // ── State ─────────────────────────────────────────────────────────────────
  final allPlanStatus = Status.init.obs;
  final Rx<SubscriptionPlansResponse?> allPlans = Rx(null);
  final Rx<SubscriptionPlan?> selectedPlan = Rx(null);

  // ── Actions ───────────────────────────────────────────────────────────────
  final ProfileDatasource _api = ProfileDatasource();

  Future<void> fetchAllPlans() async {
    allPlanStatus.value = Status.loading;
    final result = await _api.allSubscriptionPlans();
    if (result != null) {
      allPlans.value = result;
      allPlanStatus.value = Status.success;

      // Auto-select a plan if not already selected
      if (result.plans.isNotEmpty) {
        final current = selectedPlan.value;
        final stillExists = result.plans.any((p) => p.id == current?.id);
        if (!stillExists) {
          final recommended = result.plans.firstWhereOrNull(
            (p) => p.isRecommended && p.isActive,
          );
          final firstActive = result.plans.firstWhereOrNull((p) => p.isActive);
          selectedPlan.value = recommended ?? firstActive ?? result.plans.first;
        }
      }
    } else {
      allPlanStatus.value = Status.error;
    }
  }

  void selectPlan(SubscriptionPlan plan) {
    selectedPlan.value = plan;
  }
}
