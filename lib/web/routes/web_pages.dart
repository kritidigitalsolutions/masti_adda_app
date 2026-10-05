import 'package:get/get.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/screens/auth/web_login_screen.dart';
import 'package:masti_adda_app/web/screens/details/web_details_screen.dart';
import 'package:masti_adda_app/web/screens/dramas/web_dramas_screen.dart';
import 'package:masti_adda_app/web/screens/home/web_home_screen.dart';
import 'package:masti_adda_app/web/screens/movies/web_movies_screen.dart';
import 'package:masti_adda_app/web/screens/player/web_player_screen.dart';
import 'package:masti_adda_app/web/screens/profile/web_profile_screen.dart';
import 'package:masti_adda_app/web/screens/search/web_search_screen.dart';
import 'package:masti_adda_app/web/screens/series/web_series_screen.dart';
import 'package:masti_adda_app/web/screens/subscription/payment_status_screen.dart';
import 'package:masti_adda_app/web/screens/subscription/web_subscription_screen.dart';

abstract class WebPages {
  WebPages._();

  static final pages = [
    GetPage(
      name: WebRoutes.root,
      page: () => const WebHomeScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: WebRoutes.home,
      page: () => const WebHomeScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: WebRoutes.dramas,
      page: () => const WebDramasScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: WebRoutes.movies,
      page: () => const WebMoviesScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: WebRoutes.series,
      page: () => const WebSeriesScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: WebRoutes.search,
      page: () => const WebSearchScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: WebRoutes.details,
      page: () => const WebDetailsScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: WebRoutes.player,
      page: () => const WebPlayerScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: WebRoutes.profile,
      page: () => const WebProfileScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: WebRoutes.login,
      page: () => const WebLoginScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: WebRoutes.subscription,
      page: () => const WebSubscriptionScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: WebRoutes.paymentStatus,
      page: () => const PaymentStatusScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
  ];
}
