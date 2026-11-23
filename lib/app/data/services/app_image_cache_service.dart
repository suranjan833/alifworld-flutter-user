import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class AppImageCacheService extends GetxService {
  static AppImageCacheService get to => Get.find<AppImageCacheService>();

  Directory? _cacheDir;
  final Set<String> _cachedFileNames = <String>{};
  final Map<String, Future<File?>> _activeDownloads = {};
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.bytes,
    ),
  );

  /// Reactive trigger to notify listeners when new images finish caching
  final cacheNotifier = 0.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await initStorage();
  }

  Future<void> initStorage() async {
    try {
      Directory baseDir;
      try {
        baseDir = await getApplicationSupportDirectory();
      } catch (_) {
        baseDir = await getTemporaryDirectory();
      }
      _cacheDir = Directory('${baseDir.path}/app_image_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // Pre-scan existing files into memory set for instant O(1) synchronous lookup
      final entities = _cacheDir!.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.cached')) {
          final fileName = entity.uri.pathSegments.last;
          if (entity.lengthSync() > 0) {
            _cachedFileNames.add(fileName);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AppImageCacheService] Init fallback error: $e');
      }
    }
  }

  /// Generates a unique, deterministic cache key from image URL
  String _generateKey(String url) {
    final cleanUrl = url.trim().split('?').first;
    return md5.convert(utf8.encode(cleanUrl)).toString();
  }

  String _getFileName(String url) {
    return '${_generateKey(url)}.cached';
  }

  /// Synchronously checks if the image exists in disk cache
  File? getExistingFile(String? url) {
    if (url == null || url.trim().isEmpty || _cacheDir == null) return null;
    final fileName = _getFileName(url);
    if (_cachedFileNames.contains(fileName)) {
      final file = File('${_cacheDir!.path}/$fileName');
      if (file.existsSync() && file.lengthSync() > 0) {
        return file;
      } else {
        _cachedFileNames.remove(fileName);
      }
    }
    return null;
  }

  /// Downloads and caches an image to disk permanently
  Future<File?> getOrDownloadFile(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();

    // 1. Check disk cache first
    final existing = getExistingFile(trimmed);
    if (existing != null) return existing;

    // 2. Ensure cache dir is ready
    if (_cacheDir == null) {
      await initStorage();
    }
    if (_cacheDir == null) return null;

    final fileName = _getFileName(trimmed);
    final targetFile = File('${_cacheDir!.path}/$fileName');
    final tempFile = File('${_cacheDir!.path}/$fileName.tmp');

    // 3. Deduplicate active in-flight network requests
    if (_activeDownloads.containsKey(trimmed)) {
      return _activeDownloads[trimmed];
    }

    final downloadFuture = _performDownload(trimmed, targetFile, tempFile, fileName);
    _activeDownloads[trimmed] = downloadFuture;

    try {
      final result = await downloadFuture;
      return result;
    } finally {
      _activeDownloads.remove(trimmed);
    }
  }

  Future<File?> _performDownload(
    String url,
    File targetFile,
    File tempFile,
    String fileName,
  ) async {
    try {
      final response = await _dio.get<List<int>>(url);
      if (response.statusCode == 200 && response.data != null && response.data!.isNotEmpty) {
        // Atomic write: write to .tmp then rename to avoid partial corrupt files
        await tempFile.writeAsBytes(response.data!, flush: true);
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tempFile.rename(targetFile.path);

        _cachedFileNames.add(fileName);
        cacheNotifier.value++;
        return targetFile;
      }
    } catch (_) {
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
    return null;
  }

  /// Clears cache if necessary (optional utility)
  Future<void> clearDiskCache() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
        _cachedFileNames.clear();
        cacheNotifier.value++;
      }
    } catch (_) {}
  }
}
