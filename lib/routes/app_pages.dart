import 'package:get/get.dart';
import 'package:masti_adda_app/features/auth/views/all_set_screen.dart';
import 'package:masti_adda_app/features/auth/views/enter_mobile_screen.dart';
import 'package:masti_adda_app/features/auth/views/login_screen.dart';
import 'package:masti_adda_app/features/auth/views/onboarding_screen.dart';
import 'package:masti_adda_app/features/auth/views/select_interests_screen.dart';
import 'package:masti_adda_app/features/auth/views/splash_screen.dart';
import 'package:masti_adda_app/features/auth/views/verified_screen.dart';
import 'package:masti_adda_app/features/auth/views/verify_otp_screen.dart';
import 'package:masti_adda_app/features/micro_drama/views/micro_drama_screen.dart';
import 'package:masti_adda_app/features/movie/views/movie_details_screen.dart';
import 'package:masti_adda_app/features/profile/views/content_preference_screen.dart';
import 'package:masti_adda_app/features/profile/views/downloads_screen.dart';
import 'package:masti_adda_app/features/profile/views/edit_profile_screen.dart';
import 'package:masti_adda_app/features/profile/views/faq_page.dart';
import 'package:masti_adda_app/features/profile/views/language_screen.dart';
import 'package:masti_adda_app/features/profile/views/notification_screen.dart';
import 'package:masti_adda_app/features/profile/views/notification_settings_screen.dart';
import 'package:masti_adda_app/features/profile/views/premiun_welcome_screen.dart';
import 'package:masti_adda_app/features/profile/views/privacy_policy_screen.dart';
import 'package:masti_adda_app/features/profile/views/rate_app_screen.dart';
import 'package:masti_adda_app/features/profile/views/refund_policy.dart';
import 'package:masti_adda_app/features/profile/views/subscription_screen.dart';
import 'package:masti_adda_app/web/screens/subscription/payment_status_screen.dart';
import 'package:masti_adda_app/features/profile/views/terms_conditions_screen.dart';
import 'package:masti_adda_app/features/audio_play/views/audio_stories_screen.dart';
import 'package:masti_adda_app/features/audio_play/views/audio_detail_screen.dart';
import 'package:masti_adda_app/features/audio_play/views/audio_player_screen.dart';
import 'package:masti_adda_app/features/home/views/watchlist_tab.dart';
import 'package:masti_adda_app/features/movie/views/movie_listing_screen.dart';
import 'package:masti_adda_app/features/web_series/views/web_series_listing_screen.dart';
import 'package:masti_adda_app/routes/app_routes.dart';

import '../features/auth/views/create_account_screen.dart';

abstract class AppPages {
  AppPages._();

  static final pages = [
    // ----------------------------------------------------
    // Auth Page
    //_____________________________________________________
    GetPage(
      name: AppRoutes.splash,
      page: () => SplashScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => OnboardingScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),

    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: AppRoutes.enterMobile,
      page: () => EnterMobileScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.verifyOtp,
      page: () => VerifyOtpScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.verified,
      page: () => VerifiedScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),

    GetPage(
      name: AppRoutes.createAccount,
      page: () => CreateAccountScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.selectInterests,
      page: () => SelectInterestsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.allSet,
      page: () => AllSetScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),

    GetPage(
      name: AppRoutes.movieDetails,
      page: () => MovieDetailsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    // GetPage(
    //   name: AppRoutes.videoPlayer,
    //   page: () => MoviePlayerScreen(episode: ,),
    //   transition: Transition.fadeIn,
    //   transitionDuration: const Duration(milliseconds: 250),
    // ),
    GetPage(
      name: AppRoutes.subscription,
      page: () => const SubscriptionScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.paymentStatus,
      page: () => const PaymentStatusScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: AppRoutes.premiumWelcome,
      page: () => const PremiumWelcomeScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => EditProfileScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => NotificationScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.language,
      page: () => LanguageScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.downloads,
      page: () => DownloadsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.contentPreference,
      page: () => ContentPreferenceScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.notificationSettings,
      page: () => NotificationSettingsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => PrivacyPolicyScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.termsConditions,
      page: () => TermsConditionsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    // ---------------------------------------------------
    // Audio Play Pages
    // ---------------------------------------------------
    GetPage(
      name: AppRoutes.audioStories,
      page: () => const AudioStoriesScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.audioDetail,
      page: () => const AudioDetailScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.audioPlayer,
      page: () => const AudioPlayerScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),

    // ---------------------------------------------------
    // Micro Drama Pages
    // ---------------------------------------------------
    GetPage(
      name: AppRoutes.microDrama,
      page: () => const MicroDramaScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    // GetPage(
    //   name: AppRoutes.microDramaDetail,
    //   page: () => const MicroDramaDetailScreen(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 350),
    // ),
    // GetPage(
    //   name: AppRoutes.microDramaPlayer,
    //   page: () => const MicroDramaPlayerScreen(),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 350),
    // ),
    // ---------------------------------------------------
    // Watchlist
    // ---------------------------------------------------
    GetPage(
      name: AppRoutes.watchlist,
      page: () => const WatchlistScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    // ---------------------------------------------------
    // Movie Listing
    // ---------------------------------------------------
    GetPage(
      name: AppRoutes.movieListing,
      page: () => const MovieListingScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),

    GetPage(
      name: AppRoutes.faq,
      page: () => const FaqPage(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.refundPolicy,
      page: () => const RefundPolicy(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.rateApp,
      page: () => const RateAppScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    // ---------------------------------------------------
    // Web Series
    // ---------------------------------------------------
    GetPage(
      name: AppRoutes.webSeries,
      page: () => const WebSeriesListingScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    // GetPage(
    //   name: AppRoutes.webSeriesDetail,
    //   page: () => const WebSeriesDetailScreen(id: ,),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 350),
    // ),
  ];
}
