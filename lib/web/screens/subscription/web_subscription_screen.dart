import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/auth/controllers/auth_controller.dart';
import 'package:masti_adda_app/features/auth/repositories/auth_datasource.dart';
import 'package:masti_adda_app/features/profile/controllers/plan_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/features/profile/models/response/plan_model.dart';
import 'package:masti_adda_app/features/profile/repositories/payment_repo.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:masti_adda_app/web/layouts/web_main_layout.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/utils/web_auth_guard.dart';
import 'package:masti_adda_app/web/utils/web_payment_helper.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';

class WebSubscriptionScreen extends StatefulWidget {
  const WebSubscriptionScreen({super.key});

  @override
  State<WebSubscriptionScreen> createState() => _WebSubscriptionScreenState();
}

class _WebSubscriptionScreenState extends State<WebSubscriptionScreen> {
  late final PlanController _planController;
  final Set<String> _expandedPlanIds = {};
  bool _isProcessingPayment = false;

  SubscriptionStatusController get _subController =>
      Get.isRegistered<SubscriptionStatusController>()
          ? Get.find<SubscriptionStatusController>()
          : Get.put(SubscriptionStatusController(), permanent: true);

  @override
  void initState() {
    super.initState();
    _planController = Get.isRegistered<PlanController>()
        ? Get.find<PlanController>()
        : Get.put(PlanController());

    _planController.fetchAllPlans().then((_) {
      if (_planController.selectedPlan.value != null && mounted) {
        setState(() {
          _expandedPlanIds.add(_planController.selectedPlan.value!.id);
        });
      }
    });

    // Ensure status controller is registered
    if (!Get.isRegistered<SubscriptionStatusController>()) {
      Get.put(SubscriptionStatusController());
    }

    // Handle incoming web parameters (Auto-Login & Payment Flow)
    _handleWebParams();

    // Automatically check for pending payment / return query parameters from gateway
    _checkAndVerifyPendingPayment();
  }

  Future<void> _handleWebParams() async {
    final queryParams = _getAllQueryParams();
    final String? token = queryParams['token'];
    final String? planId = queryParams['planId'];
    final String? promoCode = queryParams['promoCode'];
    final String? source = queryParams['source'];

    final String? merchantTxnId = queryParams['merchantTxnId'] ?? queryParams['transactionId'];
    final String? paymentId = queryParams['paymentId'];
    final String? checksum = queryParams['checksum'];

    if (promoCode != null) debugPrint("🏷️ PromoCode: $promoCode");
    if (paymentId != null) debugPrint("💳 PaymentId: $paymentId");
    if (checksum != null) debugPrint("🔐 Checksum: $checksum");

    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    if (token != null && token.isNotEmpty) {
      debugPrint("🌐 Web Auto-Login: Token found in URL");

      bool loginSuccess = await authController.websiteLogin(token);

      if (loginSuccess && planId != null && planId.isNotEmpty) {
        if (_planController.allPlans.value?.plans.isEmpty ?? true) {
          await _planController.fetchAllPlans();
        }

        // Auto-initiate payment if redirected from mobile app
        if (source == 'app' && merchantTxnId == null) {
          debugPrint("🚀 Auto-initiating payment from WebSubscriptionScreen");
          Future.delayed(const Duration(milliseconds: 500), () {
            _startPayment();
          });
        }
      } else if (!loginSuccess) {
        Get.snackbar(
          "Error",
          "Login failed or token expired",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      // If token is not in URL (e.g. returning from gateway), restore saved user session
      final savedToken = await StorageService.getToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        var user = await StorageService.getUser();
        user ??= await AuthDatasource().fetchProfile();
        if (user != null) {
          authController.userData.value = user;
          authController.isLoggedIn.value = true;
        }
      }
    }
  }

  Map<String, String> _getAllQueryParams() {
    final params = <String, String>{};
    params.addAll(Uri.base.queryParameters);

    final fragment = Uri.base.fragment;
    if (fragment.contains('?')) {
      final queryString = fragment.substring(fragment.indexOf('?') + 1);
      final fragmentUri = Uri.parse('http://dummy.com/?$queryString');
      params.addAll(fragmentUri.queryParameters);
    }

    Get.parameters.forEach((key, value) {
      if (value != null) {
        params[key] = value;
      }
    });
    return params;
  }

  Future<void> _checkAndVerifyPendingPayment() async {
    try {
      final queryParams = _getAllQueryParams();
      final pending = await StorageService.getPendingPayment();

      String? txnId = queryParams['txnId'] ??
          queryParams['clientTxnId'] ??
          queryParams['merchantTxnId'] ??
          queryParams['transactionId'] ??
          queryParams['paymentId'] ??
          queryParams['sppayId'] ??
          queryParams['sabpaisaTxnId'] ??
          queryParams['orderId'] ??
          pending?['txnId'] ??
          (kIsWeb ? WebPaymentHelper.getLocalStorageItem('pending_txn_id') : null);

      String planId = queryParams['planId'] ??
          pending?['planId'] ??
          (kIsWeb ? WebPaymentHelper.getLocalStorageItem('pending_plan_id') : null) ??
          '';

      String? paymentId = queryParams['paymentId'] ??
          queryParams['sppayId'] ??
          pending?['paymentId'] ??
          (kIsWeb ? WebPaymentHelper.getLocalStorageItem('pending_payment_id') : null);

      if ((txnId == null || txnId.isEmpty) && pending == null && (kIsWeb ? WebPaymentHelper.getLocalStorageItem('pending_txn_id') == null : true)) {
        return;
      }

      if (planId.isEmpty) {
        planId = _planController.selectedPlan.value?.id ??
            _planController.allPlans.value?.plans.firstOrNull?.id ??
            '';
      }

      if (mounted) {
        setState(() => _isProcessingPayment = true);
      }

      final repo = PaymentRepo();
      debugPrint("WebSubscriptionScreen auto-verifying: txnId=$txnId, planId=$planId, params=$queryParams");

      final verifyRes = await repo.verifyPayment(
        transactionId: txnId ?? '',
        planId: planId,
        paymentId: paymentId,
        extraData: queryParams,
      );

      // Clear pending payment from localStorage
      await StorageService.clearPendingPayment();
      if (kIsWeb) {
        try {
          WebPaymentHelper.removeLocalStorageItem('pending_txn_id');
          WebPaymentHelper.removeLocalStorageItem('pending_plan_id');
          WebPaymentHelper.removeLocalStorageItem('pending_payment_id');
        } catch (_) {}
      }

      // Check user subscription status
      final subStatusController = _subController;
      await subStatusController.checkStatus();
      final isPremium = subStatusController.isPremiumUser.value;

      if (mounted) {
        setState(() => _isProcessingPayment = false);

        if ((verifyRes != null && verifyRes.success) || isPremium) {
          final plan = _planController.allPlans.value?.plans
                  .firstWhereOrNull((p) => p.id == planId) ??
              _planController.selectedPlan.value ??
              _planController.allPlans.value?.plans.firstOrNull;

          if (plan != null) {
            _showPaymentSuccessDialog(plan);
          } else {
            Get.snackbar(
              'VIP Unlocked!',
              'Your VIP subscription is active!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.primaryPink.withValues(alpha: 0.9),
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          }
        } else if (verifyRes != null && !verifyRes.success) {
          Get.snackbar(
            'Payment Verification',
            verifyRes.message.isNotEmpty
                ? verifyRes.message
                : 'Payment status pending or incomplete.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      debugPrint("WebSubscriptionScreen verify error: $e");
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  Future<void> _startPayment() async {
    await WebAuthGuard.requireAuth(
      context: context,
      message: 'Please sign in to purchase a subscription plan and unlock VIP content.',
      onSuccess: () {
        _processPurchase();
      },
    );
  }

  Future<void> _processPurchase() async {
    final subStatusController = _subController;
    if (subStatusController.isPremiumUser.value) {
      Get.snackbar(
        'Subscription Active',
        'You already have an active subscription plan.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accentColor.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    final selectedPlan = _planController.selectedPlan.value ??
        _planController.allPlans.value?.plans.firstOrNull;

    if (selectedPlan == null) {
      Get.snackbar(
        'Notice',
        'No subscription plan selected.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      final user = await StorageService.getUser();
      final result = await WebPaymentHelper.purchasePlan(
        plan: selectedPlan,
        userName: user?.name,
        userEmail: user?.email,
        userContact: user?.phone,
        openInSameTab: true,
      );

      if (result.success) {
        if (mounted) {
          Get.snackbar(
            'Redirecting to SabPaisa',
            'Redirecting to payment gateway...',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.primaryPink.withValues(alpha: 0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        if (mounted && result.errorMessage != null && result.errorMessage!.isNotEmpty) {
          Get.snackbar(
            'Payment Failed',
            result.errorMessage ?? 'Payment could not be completed.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.errorColor.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint("Web payment error: $e");
      if (mounted) {
        Get.snackbar(
          'Error',
          'Payment error: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorColor.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  void _showPaymentSuccessDialog(SubscriptionPlan plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primaryColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to VIP!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your subscription to "${plan.name}" is now active. Enjoy unlimited ad-free movies, web series, and exclusive micro dramas.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Get.toNamed(WebRoutes.profile);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Go to Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = WebResponsive.contentHorizontalPadding(context);

    return WebMainLayout(
      activeRoute: WebRoutes.subscription,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 32,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildBanner(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Select a Plan',
                    style: text18(
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
                _buildPlansList(),
                const SizedBox(height: 24),
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Get.back();
            } else {
              Get.toNamed(WebRoutes.home);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.borderColor.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Choose your plan',
            style: text20(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () async {
            await _subController.checkStatus();
            final isPremium = _subController.isPremiumUser.value;
            if (isPremium) {
              final plan = _planController.selectedPlan.value ??
                  _planController.allPlans.value?.plans.firstOrNull;
              if (plan != null && mounted) {
                _showPaymentSuccessDialog(plan);
              }
            } else {
              Get.snackbar(
                'Status Refreshed',
                'No active subscription found.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.surfaceColor,
                colorText: Colors.white,
              );
            }
          },
          icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
          tooltip: 'Check Status',
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: AppColors.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock Premium Experience',
                  style: text16(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enjoy ad-free streaming, HD quality & all content on Mobile and Web.',
                  style: text13(color: AppColors.secondaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList() {
    return Obx(() {
      final status = _planController.allPlanStatus.value;

      if (status == Status.loading) {
        return const SubscriptionPlansShimmer();
      }

      if (status == Status.error) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.errorColor,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load subscription plans',
                  style: text14(color: AppColors.secondaryTextColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _planController.fetchAllPlans(),
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

      final plans = _planController.allPlans.value?.plans ?? [];
      if (plans.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sentiment_dissatisfied_rounded,
                  color: AppColors.hintTextColor,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  'No subscription plans available right now.',
                  style: text14(color: AppColors.secondaryTextColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _planController.fetchAllPlans(),
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

      final selectedPlan = _planController.selectedPlan.value;

      return Column(
        children: plans.map((plan) {
          final isSelected = selectedPlan?.id == plan.id;
          return _buildPlanCard(plan: plan, isSelected: isSelected);
        }).toList(),
      );
    });
  }

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
        _planController.selectPlan(plan);
        setState(() {
          if (!_expandedPlanIds.contains(plan.id)) {
            _expandedPlanIds.add(plan.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
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
                    color: AppColors.primaryColor.withValues(alpha: 0.18),
                    blurRadius: 14,
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
                        horizontal: 12,
                        vertical: 5,
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
                        style: text11(
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
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'RECOMMENDED',
                          style: text9(
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
                  width: 24,
                  height: 24,
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
                            size: 16,
                            color: AppColors.black,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Plan Title & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: text18(
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
                      style: text26(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/${plan.duration}d',
                      style: text12(color: AppColors.hintTextColor),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(
              color: AppColors.dividerColor.withValues(alpha: 0.5),
              height: 1,
            ),
            const SizedBox(height: 10),

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
                      style: text13(
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
                          style: text12(
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
                            size: 20,
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
                padding: const EdgeInsets.only(top: 10),
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
                      _buildFeatureRow(
                        'Watch on Mobile, Tablet, Laptop and Desktop',
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
          Icon(Icons.check_circle_rounded, color: checkColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: text13(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Obx(() {
      final isSubscribed = _subController.isPremiumUser.value;
      final selectedPlan = _planController.selectedPlan.value;

      String buttonText;
      if (isSubscribed) {
        buttonText = 'Active Plan';
      } else if (selectedPlan != null) {
        buttonText = 'Pay ₹${selectedPlan.price} • Continue';
      } else {
        buttonText = 'Continue';
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            if (selectedPlan != null && !isSubscribed) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Amount',
                    style: text11(color: AppColors.secondaryTextColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${selectedPlan.price}',
                    style: text20(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
            ],
            Expanded(
              child: GestureDetector(
                onTap: _isProcessingPayment || isSubscribed ? null : _startPayment,
                child: Container(
                  height: 50,
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
                    child: _isProcessingPayment
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
                            style: text15(
                              color: isSubscribed
                                  ? AppColors.white
                                  : AppColors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
