import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/audio_play/repositories/audio_repository.dart';
import 'package:masti_adda_app/features/micro_drama/datasource/micro_drama_datasource.dart';
import 'package:masti_adda_app/features/movie/repositories/movie_datasource.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/features/web_series/datasource/series_datasource.dart';
import 'package:masti_adda_app/utils/helpers.dart';

enum DownloadMediaType {
  audio,
  movie,
  webSeries,
  microDrama,
}

class DownloadedMediaItem {
  final String id;
  final String title;
  final String parentTitle;
  final String coverImage;
  final String localFilePath;
  final String remoteUrl;
  final String fileSize;
  final int durationSeconds;
  final int episodeNumber;
  final DownloadMediaType mediaType;
  final DateTime downloadedAt;
  final Map<String, dynamic> extra;

  const DownloadedMediaItem({
    required this.id,
    required this.title,
    required this.parentTitle,
    required this.coverImage,
    required this.localFilePath,
    required this.remoteUrl,
    required this.fileSize,
    required this.durationSeconds,
    required this.episodeNumber,
    required this.mediaType,
    required this.downloadedAt,
    this.extra = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'parentTitle': parentTitle,
    'coverImage': coverImage,
    'localFilePath': localFilePath,
    'remoteUrl': remoteUrl,
    'fileSize': fileSize,
    'durationSeconds': durationSeconds,
    'episodeNumber': episodeNumber,
    'mediaType': mediaType.name,
    'downloadedAt': downloadedAt.toIso8601String(),
    'extra': extra,
  };

  factory DownloadedMediaItem.fromJson(Map<String, dynamic> json) {
    DownloadMediaType parsedType = DownloadMediaType.audio;
    final typeStr = json['mediaType']?.toString() ?? 'audio';
    for (var t in DownloadMediaType.values) {
      if (t.name == typeStr) {
        parsedType = t;
        break;
      }
    }

    return DownloadedMediaItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      parentTitle: json['parentTitle']?.toString() ?? '',
      coverImage: json['coverImage']?.toString() ?? '',
      localFilePath: json['localFilePath']?.toString() ?? '',
      remoteUrl: json['remoteUrl']?.toString() ?? '',
      fileSize: json['fileSize']?.toString() ?? '',
      durationSeconds: json['durationSeconds'] is int
          ? json['durationSeconds']
          : (int.tryParse(json['durationSeconds']?.toString() ?? '0') ?? 0),
      episodeNumber: json['episodeNumber'] is int
          ? json['episodeNumber']
          : (int.tryParse(json['episodeNumber']?.toString() ?? '1') ?? 1),
      mediaType: parsedType,
      downloadedAt: json['downloadedAt'] != null
          ? (DateTime.tryParse(json['downloadedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      extra: json['extra'] is Map ? Map<String, dynamic>.from(json['extra']) : {},
    );
  }
}

class AppDownloadService extends GetxService {
  static AppDownloadService get to {
    if (!Get.isRegistered<AppDownloadService>()) {
      return Get.put(AppDownloadService(), permanent: true);
    }
    return Get.find<AppDownloadService>();
  }

  static const String boxName = 'app_media_downloads_box';
  final Dio _dio = Dio();

  // Reactive state using GetX
  final RxList<DownloadedMediaItem> downloadedItems = <DownloadedMediaItem>[].obs;
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;
  final RxSet<String> downloadingIds = <String>{}.obs;

  Future<AppDownloadService> init() async {
    try {
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      _loadDownloadsFromBox();
    } catch (e) {
      debugPrint('AppDownloadService init error: $e');
    }
    return this;
  }

  /// Loads and validates stored downloaded media metadata from Hive storage.
  /// Automatically purges corrupted, truncated, missing, or non-media files.
  void _loadDownloadsFromBox() {
    try {
      if (!Hive.isBoxOpen(boxName)) return;
      final box = Hive.box(boxName);
      final List<DownloadedMediaItem> loaded = [];
      final List<dynamic> keysToDelete = [];

      for (var key in box.keys) {
        final raw = box.get(key);
        if (raw is Map) {
          final item = DownloadedMediaItem.fromJson(Map<String, dynamic>.from(raw));
          final cleanPath = item.localFilePath.startsWith('file://')
              ? item.localFilePath.replaceFirst('file://', '')
              : item.localFilePath;
          final file = File(cleanPath);

          bool isValid = false;
          if (file.existsSync()) {
            final len = file.lengthSync();
            if (len > 0) {
              try {
                final raf = file.openSync(mode: FileMode.read);
                final bytes = raf.readSync(len > 300 ? 300 : len);
                raf.closeSync();

                final headerStr = String.fromCharCodes(bytes).trim().toLowerCase();
                if (!headerStr.contains('<!doctype') &&
                    !headerStr.contains('<html') &&
                    !headerStr.contains('accessdenied') &&
                    !headerStr.contains('403 forbidden') &&
                    !(headerStr.startsWith('{') && headerStr.contains('"error"'))) {
                  isValid = true;
                }
              } catch (_) {
                isValid = true;
              }
            }
          }

          if (isValid) {
            loaded.add(item);
          } else {
            if (file.existsSync()) {
              try {
                file.deleteSync();
              } catch (_) {}
            }
            keysToDelete.add(key);
          }
        } else {
          keysToDelete.add(key);
        }
      }

      for (var key in keysToDelete) {
        box.delete(key);
      }

      downloadedItems.assignAll(loaded);
    } catch (e) {
      debugPrint('_loadDownloadsFromBox error: $e');
    }
  }

  void reloadDownloads() {
    _loadDownloadsFromBox();
  }

  // ─────────────────────────────────────────────
  // State Checkers
  // ─────────────────────────────────────────────

  bool isDownloaded(String id) {
    if (id.isEmpty) return false;
    return getLocalFilePath(id) != null;
  }

  bool isDownloading(String id) {
    if (id.isEmpty) return false;
    return downloadingIds.contains(id);
  }

  double getProgress(String id) {
    return downloadProgress[id] ?? 0.0;
  }

  String? getLocalFilePath(String id) {
    if (id.isEmpty) return null;
    final match = downloadedItems.firstWhereOrNull((e) => e.id == id);
    if (match != null) {
      final cleanPath = match.localFilePath.startsWith('file://')
          ? match.localFilePath.replaceFirst('file://', '')
          : match.localFilePath;
      final file = File(cleanPath);
      if (file.existsSync() && file.lengthSync() > 0) {
        return cleanPath;
      }
    }
    return null;
  }

  DownloadedMediaItem? getDownloadedItem(String id) {
    if (id.isEmpty) return null;
    return downloadedItems.firstWhereOrNull((e) => e.id == id);
  }

  // Filtered lists
  List<DownloadedMediaItem> get audioDownloads =>
      downloadedItems.where((d) => d.mediaType == DownloadMediaType.audio).toList();

  List<DownloadedMediaItem> get movieDownloads =>
      downloadedItems.where((d) => d.mediaType == DownloadMediaType.movie).toList();

  List<DownloadedMediaItem> get webSeriesDownloads =>
      downloadedItems.where((d) => d.mediaType == DownloadMediaType.webSeries).toList();

  List<DownloadedMediaItem> get microDramaDownloads =>
      downloadedItems.where((d) => d.mediaType == DownloadMediaType.microDrama).toList();

  // ─────────────────────────────────────────────
  // Direct Download URL Resolution
  // ─────────────────────────────────────────────

  String _getDirectDownloadUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    // Handle Bunny Stream embed iframe URLs: https://iframe.mediadelivery.net/embed/LIB_ID/VIDEO_ID
    final iframeMatch = RegExp(r'iframe\.mediadelivery\.net/embed/(\d+)/([a-zA-Z0-9-]+)').firstMatch(trimmed);
    if (iframeMatch != null) {
      final videoId = iframeMatch.group(2);
      return 'https://video.mastiadda.in/$videoId/play_720p.mp4';
    }

    // Handle Bunny Stream m3u8 playlist URLs: https://vz-xxx.b-cdn.net/VIDEO_ID/playlist.m3u8
    if (trimmed.contains('.b-cdn.net/') && trimmed.endsWith('playlist.m3u8')) {
      return trimmed.replaceAll('playlist.m3u8', 'play_720p.mp4');
    }

    return trimmed;
  }

  Future<String> _resolveStreamUrl(String id, String remoteUrl, DownloadMediaType mediaType) async {
    String url = formatMediaUrl(remoteUrl);

    // If url is an API endpoint or empty, fetch details from backend API first
    bool isApiRoute = url.isEmpty ||
        url.contains('/api/episodes/') ||
        url.contains('/api/movies/') ||
        url.contains('/api/microdramas') ||
        url.contains('/api/series/') ||
        url.contains('/api/audio-episodes/');

    if (!isApiRoute) {
      return _getDirectDownloadUrl(url);
    }

    try {
      switch (mediaType) {
        case DownloadMediaType.audio:
          final fetched = await AudioRepository().playAudioEpisode(id);
          if (fetched != null && fetched.isNotEmpty) {
            return _getDirectDownloadUrl(formatMediaUrl(fetched));
          }
          break;
        case DownloadMediaType.movie:
          final fetched = await MovieDatasource().movieDetail(id: id);
          if (fetched != null && fetched.videoUrl.isNotEmpty) {
            return _getDirectDownloadUrl(formatMediaUrl(fetched.videoUrl));
          }
          break;
        case DownloadMediaType.webSeries:
          final fetched = await SeriesDatasource().singleEpisode(id: id);
          if (fetched != null && fetched.episode.videoUrl.isNotEmpty) {
            return _getDirectDownloadUrl(formatMediaUrl(fetched.episode.videoUrl));
          }
          break;
        case DownloadMediaType.microDrama:
          final fetched = await MicroDramaDatasource().episodeDetail(id: id);
          if (fetched != null && fetched.episodes.isNotEmpty) {
            final match = fetched.episodes.firstWhereOrNull((e) => e.id == id) ?? fetched.episodes.first;
            if (match.videoUrl.isNotEmpty) {
              return _getDirectDownloadUrl(formatMediaUrl(match.videoUrl));
            }
          }
          break;
      }
    } catch (e) {
      debugPrint('Failed to resolve media URL for $id: $e');
    }

    return _getDirectDownloadUrl(url);
  }

  Future<void> _executeDownload(String url, String localFilePath, String id) async {
    final token = await StorageService.getToken();
    final headers = Map<String, String>.from(getVideoPlayerHeaders(url));
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    await _dio.download(
      url,
      localFilePath,
      options: Options(
        headers: headers,
        followRedirects: true,
        validateStatus: (status) => status != null && status >= 200 && status < 300,
        receiveTimeout: const Duration(minutes: 60),
        sendTimeout: const Duration(seconds: 30),
      ),
      onReceiveProgress: (received, total) {
        if (total > 0) {
          downloadProgress[id] = (received / total).clamp(0.0, 1.0);
        }
      },
    );
  }

  // ─────────────────────────────────────────────
  // Download Media Action
  // ─────────────────────────────────────────────

  Future<void> downloadMedia({
    required String id,
    required String title,
    required String parentTitle,
    required String coverImage,
    required String remoteUrl,
    required DownloadMediaType mediaType,
    int durationSeconds = 0,
    int episodeNumber = 1,
    Map<String, dynamic> extra = const {},
    bool isPremium = false,
  }) async {
    if (id.isEmpty) return;

    if (isPremium) {
      final subController = Get.isRegistered<SubscriptionStatusController>()
          ? Get.find<SubscriptionStatusController>()
          : Get.put(SubscriptionStatusController());
      if (!subController.isPremiumUser.value) {
        Get.snackbar(
          'Premium Required',
          'A premium subscription plan is required to download this content.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1E1E1E),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 3),
        );
        return;
      }
    }

    if (isDownloaded(id)) {
      Get.snackbar(
        'Already Downloaded',
        '$title is already saved on your device.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1E1E),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (isDownloading(id)) return;

    final appDir = await getApplicationDocumentsDirectory();
    final subFolder = mediaType.name;
    final saveDir = Directory('${appDir.path}/downloads/$subFolder');
    final ext = (mediaType == DownloadMediaType.audio) ? 'mp3' : 'mp4';
    final localFilePath = '${saveDir.path}/$id.$ext';

    try {
      downloadingIds.add(id);
      downloadProgress[id] = 0.0;

      String targetUrl = await _resolveStreamUrl(id, remoteUrl, mediaType);

      if (targetUrl.isEmpty) {
        throw Exception('Media streaming URL is empty or unavailable.');
      }

      if (!saveDir.existsSync()) {
        await saveDir.create(recursive: true);
      }

      // Execute file download
      await _executeDownload(targetUrl, localFilePath, id);

      // Validate downloaded file
      final file = File(localFilePath);
      if (!file.existsSync() || (await file.length()) <= 0) {
        throw Exception('Downloaded file is empty or missing.');
      }

      // Check header content
      final fileSize = await file.length();
      final readBytesCount = fileSize > 1000 ? 1000 : fileSize;
      final raf = await file.open(mode: FileMode.read);
      final headerBytes = await raf.read(readBytesCount);
      await raf.close();

      final headerStr = String.fromCharCodes(headerBytes).trim();

      // IF THE DOWNLOADED FILE IS A JSON RESPONSE (e.g. {"success": true, "videoUrl": "https://..."})
      if ((headerStr.startsWith('{') && headerStr.endsWith('}')) ||
          headerStr.contains('"videoUrl"') ||
          headerStr.contains('"url"') ||
          headerStr.contains('"streamUrl"')) {
        try {
          final jsonMap = jsonDecode(headerStr);
          String? extractedUrl;
          if (jsonMap is Map) {
            extractedUrl = jsonMap['videoUrl']?.toString() ??
                jsonMap['url']?.toString() ??
                jsonMap['streamUrl']?.toString() ??
                jsonMap['episode']?['videoUrl']?.toString() ??
                jsonMap['movie']?['videoUrl']?.toString() ??
                jsonMap['data']?['videoUrl']?.toString();
          }

          if (extractedUrl != null && extractedUrl.isNotEmpty) {
            final finalMediaUrl = _getDirectDownloadUrl(formatMediaUrl(extractedUrl));
            if (file.existsSync()) await file.delete();

            // Re-download from extracted actual video stream URL
            await _executeDownload(finalMediaUrl, localFilePath, id);
            targetUrl = finalMediaUrl;
          }
        } catch (e) {
          debugPrint('JSON extraction error: $e');
        }
      }

      // Validate final downloaded file
      final finalSize = await file.length();
      if (finalSize <= 0) {
        if (file.existsSync()) await file.delete();
        throw Exception('Downloaded media file is empty (0 bytes).');
      }

      final finalRaf = await file.open(mode: FileMode.read);
      final finalBytes = await finalRaf.read(finalSize > 500 ? 500 : finalSize);
      await finalRaf.close();
      final finalHeader = String.fromCharCodes(finalBytes).toLowerCase();

      if (finalHeader.contains('<!doctype') ||
          finalHeader.contains('<html') ||
          finalHeader.contains('<head') ||
          finalHeader.contains('<body') ||
          finalHeader.contains('accessdenied') ||
          finalHeader.contains('403 forbidden') ||
          finalHeader.contains('404 not found') ||
          (finalHeader.trim().startsWith('{') && finalHeader.contains('"error"'))) {
        if (file.existsSync()) await file.delete();
        throw Exception('Server returned an error response page instead of media video content.');
      }

      final formattedSize = _formatBytes(finalSize);

      final downloadedItem = DownloadedMediaItem(
        id: id,
        title: title.isNotEmpty ? title : 'Media Item',
        parentTitle: parentTitle,
        coverImage: coverImage,
        localFilePath: localFilePath,
        remoteUrl: targetUrl,
        fileSize: formattedSize,
        durationSeconds: durationSeconds,
        episodeNumber: episodeNumber,
        mediaType: mediaType,
        downloadedAt: DateTime.now(),
        extra: extra,
      );

      final box = Hive.box(boxName);
      await box.put(id, downloadedItem.toJson());

      downloadedItems.removeWhere((e) => e.id == id);
      downloadedItems.add(downloadedItem);
      downloadedItems.refresh();

      Get.snackbar(
        'Downloaded',
        '$title saved successfully for offline playback.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1E1E),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('downloadMedia error: $e');

      // Cleanup local partial file on error
      final partialFile = File(localFilePath);
      if (partialFile.existsSync()) {
        try {
          partialFile.deleteSync();
        } catch (_) {}
      }

      // Cleanup Hive & state
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          if (box.containsKey(id)) {
            await box.delete(id);
          }
        }
      } catch (_) {}

      downloadedItems.removeWhere((e) => e.id == id);
      downloadedItems.refresh();

      final cleanErr = e.toString().replaceAll('Exception:', '').trim();
      Get.snackbar(
        'Download Failed',
        cleanErr.isNotEmpty
            ? 'Could not download $title: $cleanErr'
            : 'Could not download $title. Please check your internet connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1E1E),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
      );
    } finally {
      downloadingIds.remove(id);
      downloadProgress.remove(id);
    }
  }

  // ─────────────────────────────────────────────
  // Remove Download Action
  // ─────────────────────────────────────────────

  Future<void> removeDownload(String id) async {
    try {
      final item = downloadedItems.firstWhereOrNull((e) => e.id == id);
      final path = item?.localFilePath ?? getLocalFilePath(id);

      if (path != null && path.isNotEmpty) {
        final cleanPath = path.startsWith('file://') ? path.replaceFirst('file://', '') : path;
        final file = File(cleanPath);
        if (file.existsSync()) {
          await file.delete();
        }
      }

      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        await box.delete(id);
      }

      downloadedItems.removeWhere((e) => e.id == id);
      downloadedItems.refresh();

      Get.snackbar(
        'Removed',
        '${item?.title ?? 'Item'} deleted from downloads.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1E1E),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('removeDownload error: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
