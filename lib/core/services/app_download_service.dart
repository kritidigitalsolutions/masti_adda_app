import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

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

  // Reactive state
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

  void _loadDownloadsFromBox() {
    try {
      final box = Hive.box(boxName);
      final List<DownloadedMediaItem> loaded = [];

      for (var key in box.keys) {
        final raw = box.get(key);
        if (raw is Map) {
          final item = DownloadedMediaItem.fromJson(Map<String, dynamic>.from(raw));
          if (File(item.localFilePath).existsSync()) {
            loaded.add(item);
          } else {
            box.delete(key);
          }
        }
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
    return downloadedItems.any((e) => e.id == id);
  }

  bool isDownloading(String id) {
    if (id.isEmpty) return false;
    return downloadingIds.contains(id);
  }

  double getProgress(String id) {
    return downloadProgress[id] ?? 0.0;
  }

  String? getLocalFilePath(String id) {
    final match = downloadedItems.firstWhereOrNull((e) => e.id == id);
    if (match != null && File(match.localFilePath).existsSync()) {
      return match.localFilePath;
    }
    return null;
  }

  DownloadedMediaItem? getDownloadedItem(String id) {
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
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (isDownloading(id)) return;

    try {
      downloadingIds.add(id);
      downloadProgress[id] = 0.0;

      final resolvedUrl = formatMediaUrl(remoteUrl);
      if (resolvedUrl.isEmpty) {
        throw Exception('Media stream URL could not be resolved');
      }

      // Prepare local directory
      final appDir = await getApplicationDocumentsDirectory();
      final subFolder = mediaType.name;
      final saveDir = Directory('${appDir.path}/downloads/$subFolder');
      if (!saveDir.existsSync()) {
        await saveDir.create(recursive: true);
      }

      final ext = (mediaType == DownloadMediaType.audio) ? 'mp3' : 'mp4';
      final localFilePath = '${saveDir.path}/$id.$ext';

      // Download file with progress
      await _dio.download(
        resolvedUrl,
        localFilePath,
        options: Options(headers: getVideoPlayerHeaders(resolvedUrl)),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress[id] = (received / total).clamp(0.0, 1.0);
          }
        },
      );

      // File size calculation
      final file = File(localFilePath);
      String formattedSize = '0 MB';
      if (file.existsSync()) {
        final bytes = await file.length();
        formattedSize = _formatBytes(bytes);
      }

      final downloadedItem = DownloadedMediaItem(
        id: id,
        title: title.isNotEmpty ? title : 'Media Item',
        parentTitle: parentTitle,
        coverImage: coverImage,
        localFilePath: localFilePath,
        remoteUrl: resolvedUrl,
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

      Get.snackbar(
        'Downloaded',
        '$title saved successfully for offline watching/listening.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('downloadMedia error: $e');
      Get.snackbar(
        'Download Failed',
        'Could not download $title. Please check your internet connection.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
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
      final index = downloadedItems.indexWhere((e) => e.id == id);
      if (index >= 0) {
        final item = downloadedItems[index];
        final file = File(item.localFilePath);
        if (file.existsSync()) {
          await file.delete();
        }

        final box = Hive.box(boxName);
        await box.delete(id);
        downloadedItems.removeAt(index);

        Get.snackbar(
          'Removed',
          '${item.title} deleted from downloads.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
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
