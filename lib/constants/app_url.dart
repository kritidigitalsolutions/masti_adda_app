class AppUrl {
  static const String baseUrl = 'http://192.168.1.11:5000';
  // static const String baseUrl = 'https://api.mastiadda.com';
  static const String webBaseUrl = 'https://mastiadda.com';
  // static const String webBaseUrl = 'https://sage-praline-c605a4.netlify.app';

  // static const String baseUrl = 'https://goli-doli-ott-backend.vercel.app';
  static const String sendOtp = '$baseUrl/api/auth/send-otp';
  static const String verifyOtp = "$baseUrl/api/auth/verify-otp";
  static const String googleLogin = "$baseUrl/api/auth/google-login";
  static const String websiteLogin = "$baseUrl/api/auth/website-login";
  static const String logout = "$baseUrl/api/auth/logout";
  static const String completeProfile = "$baseUrl/api/user/complete-profile";
  static const String fetchProfile = "$baseUrl/api/user/profile";
  static const String updateProfile = "$baseUrl/api/user/update-profile";
  static const String allMovies = "$baseUrl/api/movies";
  static String detailMovie(String id) => "$baseUrl/api/movies/$id";
  static const String allSeries = "$baseUrl/api/series";
  static String seriesDetail(String id) => "$baseUrl/api/series/$id";
  static String episodes(String id) => "$baseUrl/api/series/episodes/$id";
  static String helpApi = "$baseUrl/api/help";
  static String singleEpisode({required String id}) =>
      "$baseUrl/api/episodes/$id";
  static String legalApi = "$baseUrl/api/legal";
  static String singleLegalApi({required String id}) =>
      "$baseUrl/api/legal/$id";
  static String allMicroDramaApis = "$baseUrl/api/microdramas";
  static String singleMicroDrama({required String id}) =>
      "$baseUrl/api/microdramas/$id";
  static String allCategories = "$baseUrl/api/categories";
  static String categoryDetail({required String id, int? page, int? size}) =>
      "$baseUrl/api/categories/$id?page=$page&size=$size";
  static String microDramaEpisodeDetail({required String id}) =>
      "$baseUrl/api/microdramas-episodes/$id";
  static const String plan = "$baseUrl/api/plan";
  // static String allContentApi = "$baseUrl/api/content";
  static String searchContent({required String query}) =>
      "$baseUrl/api/content/?search=$query";

  static String createOrder = "$baseUrl/api/payment/create-order";
  static String verifyPayment = "$baseUrl/api/payment/verify";
  static const String subscriptionStatus = "$baseUrl/api/subscription/status";

  static const String webSubscription = "$webBaseUrl/subscription";

  // Home Banners & Intro Screens
  static const String homeBanners = "$baseUrl/api/home-banners";
  static const String introScreens = "$baseUrl/api/intro-screens";

  // Watchlist APIs
  static const String watchlist = "$baseUrl/api/watchlist";
  static String deleteWatchlist(String id) => "$baseUrl/api/watchlist/$id";

  // Notification APIs
  static const String fcmToken = "$baseUrl/api/notifications/fcm-token";
  static const String notifications = "$baseUrl/api/notifications";
  static const String unreadNotificationsCount =
      "$baseUrl/api/notifications/unread-count";
  static String markNotificationRead(String id) =>
      "$baseUrl/api/notifications/$id/read";
  static const String markAllNotificationsRead =
      "$baseUrl/api/notifications/read-all";
  static String deleteNotification(String id) =>
      "$baseUrl/api/notifications/$id";
  static const String notificationSettings =
      "$baseUrl/api/notification-settings";

  // Continue Watching APIs
  static const String saveWatchProgress =
      "$baseUrl/api/continue-watching/progress";
  static const String continueWatchingList = "$baseUrl/api/continue-watching";
  static String watchProgressForContent(String contentId) =>
      "$baseUrl/api/continue-watching/progress/$contentId";
  static String markWatchCompleted(String progressId) =>
      "$baseUrl/api/continue-watching/complete/$progressId";
  static String deleteWatchProgress(String progressId) =>
      "$baseUrl/api/continue-watching/$progressId";

  // Audio Stories APIs
  static const String audioCategories = "$baseUrl/api/audio-categories";
  static String audioStories({
    String? categoryId,
    String? language,
    int? page,
    int? limit,
  }) {
    final params = <String>[];
    if (categoryId != null && categoryId.isNotEmpty) {
      params.add("category=$categoryId");
    }
    if (language != null && language.isNotEmpty) {
      params.add("language=$language");
    }
    if (page != null) params.add("page=$page");
    if (limit != null) params.add("limit=$limit");
    final queryString = params.isNotEmpty ? "?${params.join("&")}" : "";
    return "$baseUrl/api/audio-stories$queryString";
  }

  static const String audioStoriesHome = "$baseUrl/api/audio-stories/home";
  static String searchAudioStories(String query) =>
      "$baseUrl/api/audio-stories/search?q=${Uri.encodeComponent(query)}";
  static String singleAudioStory(String storyId) =>
      "$baseUrl/api/audio-stories/$storyId";
  static String playAudioEpisode(String episodeId) =>
      "$baseUrl/api/audio-episodes/$episodeId/play";
  static const String saveAudioProgress = "$baseUrl/api/audio-progress";
  static const String continueListening =
      "$baseUrl/api/audio-progress/continue";
  static String markAudioEpisodeCompleted(String episodeId) =>
      "$baseUrl/api/audio-progress/$episodeId/complete";
  static String audioEpisodeProgress(String episodeId) =>
      "$baseUrl/api/audio-progress/$episodeId";

  // Interaction APIs (Toggle Like / Dislike)
  static String toggleLike(String contentId) =>
      "$baseUrl/api/interaction/toggle/like/$contentId";
  static String toggleDislike(String contentId) =>
      "$baseUrl/api/interaction/toggle/dislike/$contentId";

  // AI Reels APIs
  static String aiReelsFeed({int limit = 10, String? sessionId, bool? replay}) {
    final params = <String>[];
    params.add("limit=$limit");
    if (sessionId != null && sessionId.isNotEmpty) {
      params.add("sessionId=$sessionId");
    }
    if (replay != null && replay) {
      params.add("replay=true");
    }
    return "$baseUrl/api/ai-reels?${params.join("&")}";
  }

  static String aiReelView(String reelId) =>
      "$baseUrl/api/ai-reels/$reelId/view";
  static String aiReelComplete(String reelId) =>
      "$baseUrl/api/ai-reels/$reelId/complete";
  static String toggleLikeAiReel(String id) =>
      "$baseUrl/api/interaction/toggle/like/aiReel/$id";
  static String aiReelShare(String reelId) =>
      "$baseUrl/api/ai-reels/$reelId/share";

  // AI Reels & App Comments APIs
  static String commentsByContent(
    String contentId, {
    int? page,
    int? limit,
    String? episodeId,
  }) {
    final params = <String>[];
    if (page != null) params.add("page=$page");
    if (limit != null) params.add("limit=$limit");
    if (episodeId != null && episodeId.isNotEmpty) {
      params.add("episodeId=${Uri.encodeComponent(episodeId)}");
    }
    final queryString = params.isNotEmpty ? "?${params.join("&")}" : "";
    return "$baseUrl/api/v1/app/comments/$contentId$queryString";
  }

  static const String postComment = "$baseUrl/api/v1/app/comments";
  static String deleteComment(String commentId) =>
      "$baseUrl/api/v1/app/comments/$commentId";

  // Rating & Review API
  static const String rateApp = "$baseUrl/api/rating/rate";

  // Company Info API
  static const String companyInfo = "$baseUrl/api/companyInfo";
}
