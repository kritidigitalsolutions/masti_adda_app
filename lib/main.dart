import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/core/services/app_download_service.dart';
import 'package:masti_adda_app/features/audio_play/controllers/audio_player_controller.dart';
import 'package:masti_adda_app/features/audio_play/services/audio_download_service.dart';
import 'package:masti_adda_app/features/audio_play/services/audio_handler.dart';
import 'package:masti_adda_app/features/audio_play/widgets/audio_mini_player.dart';
import 'package:masti_adda_app/features/home/controllers/home_controller.dart';
import 'package:masti_adda_app/features/home/views/discover_tab.dart';
import 'package:masti_adda_app/features/home/views/home_tab.dart';
import 'package:masti_adda_app/features/home/views/reels_tab.dart';
import 'package:masti_adda_app/features/home/views/watchlist_tab.dart';
import 'package:masti_adda_app/features/micro_drama/views/micro_drama_screen.dart';
import 'package:masti_adda_app/features/profile/controllers/notification_settings_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/features/profile/views/profile_screen.dart';
import 'package:masti_adda_app/routes/app_pages.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/shared/widgets/bottom_nav_bar.dart';
import 'package:masti_adda_app/web/screens/home/web_home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:masti_adda_app/core/services/firebase_service.dart';
import 'package:masti_adda_app/web/routes/web_pages.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Initialize Hive storage
  await Hive.initFlutter();
  await Hive.openBox('appBox');

  if (!kIsWeb) {
    final notificationService = Get.put(NotificationService(), permanent: true);
    await notificationService.init();

    // Initialize universal offline media download manager
    final appDownloadService = Get.put(AppDownloadService(), permanent: true);
    await appDownloadService.init();

    final audioDownloadService = Get.put(
      AudioDownloadService(),
      permanent: true,
    );
    await audioDownloadService.init();

    // Initialize audio_service — registers the background service & notification
    final audioHandler = await AudioService.init(
      builder: () => GolodoliAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.golidoli.audio.channel',
        androidNotificationChannelName: 'Masti Adda Audio',
        androidStopForegroundOnPause:
            true, // stop foreground when paused (battery friendly)
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    );

    // Wire handler to AudioPlayerController singleton
    AudioPlayerController.setHandler(audioHandler);
    Get.put(AudioPlayerController(), permanent: true);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  runApp(const MyApp());
}

class AppWebScrollBehavior extends MaterialScrollBehavior {
  const AppWebScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Masti Adda',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppWebScrollBehavior(),
      initialBinding: BindingsBuilder(() {
        Get.put(SubscriptionStatusController(), permanent: true);
        Get.put(NotificationSettingsController(), permanent: true);
      }),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        primaryTextTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).primaryTextTheme,
        ),
        scaffoldBackgroundColor: AppColors.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: AppColors.backgroundColor,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      initialRoute: kIsWeb ? WebRoutes.home : AppRoutes.splash,
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => kIsWeb ? const WebHomeScreen() : MyHomePage(),
      ),
      getPages: kIsWeb
          ? [...WebPages.pages, ...AppPages.pages]
          : [
              GetPage(
                name: AppRoutes.home,
                page: () => const MyHomePage(),
                transitionDuration: const Duration(milliseconds: 350),
              ),
              ...AppPages.pages,
            ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  final int? initialIndex;

  const MyHomePage({super.key, this.initialIndex});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HomeController());
    Get.put(SubscriptionStatusController(), permanent: true);
    Get.put(NotificationSettingsController(), permanent: true);
    AudioPlayerController.to;

    // Handle initial index after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex != null && controller.selectedIndex.value == 0) {
        final pagesLength = _getPages().length;
        final validIndex = widget.initialIndex!.clamp(0, pagesLength - 1);
        controller.changeTab(validIndex);
      }
    });
  }

  @override
  void dispose() {
    // Clean up GetX controller if needed
    // Get.delete<HomeController>();
    super.dispose();
  }

  List<Widget> _getPages() {
    return const [
      HomeTab(),
      WatchlistScreen(),
      ReelsTab(),
      DiscoverTab(),
      MicroDramaScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();

    return Obx(
      () => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AudioMiniPlayer(),
            BottomNavBar(
              currentIndex: controller.selectedIndex.value,
              onTap: controller.changeTab,
            ),
          ],
        ),
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: pages,
        ),
      ),
    );
  }
}
