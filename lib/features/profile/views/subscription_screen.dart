import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/profile/controllers/payment_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/profile_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/features/profile/models/response/plan_model.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import '../controllers/plan_controller.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionStatusController get _subController =>
      Get.isRegistered<SubscriptionStatusController>()
          ? Get.find<SubscriptionStatusController>()
          : Get.put(SubscriptionStatusController(), permanent: true);

  late final PlanController _controller;
  late final PaymentController _paymentController;
  late final ProfileController _profileController;
  final Set<String> _expandedPlanIds = {};

  @override
  void initState() {
    super.initState();
    _controller = Get.put(PlanController());
    _paymentController = Get.put(PaymentController());
    _profileController = Get.put(ProfileController());
    _controller.fetchAllPlans().then((_) {
      if (_controller.selectedPlan.value != null && mounted) {
        setState(() {
          _expandedPlanIds.add(_controller.selectedPlan.value!.id);
        });
      }
    });
  }

  void startPayment() {
    if (_subController.isPremiumUser.value) {
      Get.snackbar(
        'Subscription Active',
        'You already have an active subscription plan.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accentColor.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    final selectedPlan = _controller.selectedPlan.value ??
        _controller.allPlans.value?.plans.firstOrNull;

    if (selectedPlan == null) {
      Get.snackbar(
        'Notice',
        'No subscription plan available to purchase.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    final user = _profileController.user.value;

    _paymentController.startPayment(
      plan: selectedPlan,
      userContact: user?.phone,
      userEmail: user?.email,
      userName: user?.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _controller.fetchAllPlans();
                },
                color: AppColors.primaryColor,
                backgroundColor: AppColors.surfaceColor,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _buildBanner()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Select a Plan',
                          style: text16(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _buildPlansList(),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Choose your plan',
              style: text18(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => _paymentController.checkAndUpdateStatus(),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
            tooltip: 'Check Payment Status',
          ),
        ],
      ),
    );
  }

  // ─── Banner ────────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceColor,
            AppColors.cardColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppColors.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock Premium Experience',
                  style: text14(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enjoy ad-free streaming, HD quality & all content',
                  style: text11(color: AppColors.secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Plans List ───────────────────────────────────────────────────
  Widget _buildPlansList() {
    return Obx(() {
      final status = _controller.allPlanStatus.value;

      if (status == Status.loading || status == Status.init) {
        return const SubscriptionPlansShimmer();
      }

      if (status == Status.error) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.errorColor,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load subscription plans',
                  style: text14(color: AppColors.secondaryTextColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _controller.fetchAllPlans(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.black,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      }

      final plans = _controller.allPlans.value?.plans ?? [];
      if (plans.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sentiment_dissatisfied_rounded,
                  color: AppColors.hintTextColor,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'No subscription plans available right now.',
                  style: text14(color: AppColors.secondaryTextColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _controller.fetchAllPlans(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.black,
                  ),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        );
      }

      final selectedPlan = _controller.selectedPlan.value;

      return Column(
        children: plans.map((plan) {
          final isSelected = selectedPlan?.id == plan.id;
          return _buildPlanCard(plan: plan, isSelected: isSelected);
        }).toList(),
      );
    });
  }

  // ─── Plan Card ────────────────────────────────────────────────────
  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required bool isSelected,
  }) {
    final hasFeatures = plan.features.isNotEmpty;
    final isExpanded = _expandedPlanIds.contains(plan.id);
    final durationLabel = plan.duration > 0
        ? '${plan.duration} ${plan.duration == 1 ? 'Day' : 'Days'}'
        : plan.planType.toUpperCase();

    return GestureDetector(
      onTap: () {
        _controller.selectPlan(plan);
        setState(() {
          if (!_expandedPlanIds.contains(plan.id)) {
            _expandedPlanIds.add(plan.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceColor
              : AppColors.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.borderColor.withValues(alpha: 0.4),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Badges & Radio Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Plan Type / Duration Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor.withValues(alpha: 0.2)
                            : AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor.withValues(alpha: 0.5)
                              : AppColors.borderColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        durationLabel,
                        style: text10(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.secondaryTextColor,
                        ),
                      ),
                    ),
                    if (plan.isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'RECOMMENDED',
                          style: text8(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Selection Radio Circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.primaryColor
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.hintTextColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: AppColors.black,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Plan Title & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: text16(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.white : AppColors.secondaryTextColor,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${plan.price}',
                      style: text24(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/${plan.duration}d',
                      style: text11(color: AppColors.hintTextColor),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(
              color: AppColors.dividerColor.withValues(alpha: 0.5),
              height: 1,
            ),
            const SizedBox(height: 8),

            // Expandable Features Toggle Header
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  if (_expandedPlanIds.contains(plan.id)) {
                    _expandedPlanIds.remove(plan.id);
                  } else {
                    _expandedPlanIds.add(plan.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasFeatures
                          ? 'Features (${plan.features.length})'
                          : 'Plan Features',
                      style: text12(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.secondaryTextColor,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          isExpanded ? 'Hide' : 'View',
                          style: text11(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.hintTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Expandable Features List
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasFeatures)
                      ...plan.features.map(
                        (f) => _buildFeatureRow(
                          f,
                          color: AppColors.white,
                          checkColor: isSelected
                              ? AppColors.primaryColor
                              : AppColors.accentColor,
                        ),
                      )
                    else ...[
                      _buildFeatureRow(
                        'Unlimited Movies, Series & Micro Dramas',
                        color: AppColors.white,
                        checkColor: isSelected
                            ? AppColors.primaryColor
                            : AppColors.accentColor,
                      ),
                      _buildFeatureRow(
                        'Full HD Streaming & Ad-Free Experience',
                        color: AppColors.white,
                        checkColor: isSelected
                            ? AppColors.primaryColor
                            : AppColors.accentColor,
                      ),
                    ],
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Feature Row ──────────────────────────────────────────────────
  Widget _buildFeatureRow(
    String label, {
    Color color = AppColors.white,
    Color checkColor = AppColors.secondaryTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: checkColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: text12(color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Bar with Continue Button ──────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppColors.borderColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Obx(() {
        final isProcessing = _paymentController.isProcessing.value;
        final isSubscribed = _subController.isPremiumUser.value;
        final selectedPlan = _controller.selectedPlan.value;

        String buttonText;
        if (isSubscribed) {
          buttonText = 'Active Plan';
        } else if (selectedPlan != null) {
          buttonText = 'Pay ₹${selectedPlan.price} • Continue';
        } else {
          buttonText = 'Continue';
        }

        return GestureDetector(
          onTap: isProcessing ? null : startPayment,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isSubscribed
                  ? AppColors.surfaceColor
                  : AppColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
              border: isSubscribed
                  ? Border.all(color: AppColors.borderColor)
                  : null,
            ),
            child: Center(
              child: isProcessing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.black,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: text14(
                        color: isSubscribed ? AppColors.white : AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }
}

