import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class AssetVideoLoader {
  static final Map<String, String> _cachedVideoPaths = {};

  static Future<String> getLocalPath(BuildContext context, String assetPath) async {
    // Return cached path if available
    if (_cachedVideoPaths.containsKey(assetPath)) {
      return _cachedVideoPaths[assetPath]!;
    }

    try {
      // Get application documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String videoDirPath = '${appDocDir.path}/videos';
      final Directory videoDir = Directory(videoDirPath);

      // Create videos directory if it doesn't exist
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      // Extract filename from asset path
      final String filename = assetPath.split('/').last;
      final String localPath = '$videoDirPath/$filename';

      // Check if file already exists locally
      final File localFile = File(localPath);
      if (await localFile.exists()) {
        _cachedVideoPaths[assetPath] = localPath;
        return localPath;
      }

      // Copy asset to local storage
      await _copyAssetToLocal(assetPath, localPath);

      _cachedVideoPaths[assetPath] = localPath;
      return localPath;
    } catch (e) {
      print('Error loading video: $assetPath - $e');
      throw Exception('Cannot load video: $assetPath');
    }
  }

  static Future<void> _copyAssetToLocal(String assetPath, String localPath) async {
    try {
      // Load asset as byte data
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      // Write to local file
      final File localFile = File(localPath);
      await localFile.writeAsBytes(bytes);

      print('Video copied: $assetPath -> $localPath');
    } catch (e) {
      print('Error copying video: $assetPath - $e');
      throw Exception('Cannot copy video: $assetPath');
    }
  }

  static Future<void> preloadVideos(List<String> assetPaths, BuildContext context) async {
    print('Preloading ${assetPaths.length} videos...');

    for (final assetPath in assetPaths) {
      try {
        await getLocalPath(context, assetPath);
        print('Preloaded: $assetPath');
      } catch (e) {
        print('Preload failed: $assetPath - $e');
      }
    }

    print('Video preloading completed');
  }

  static Future<void> clearCache() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String videoDirPath = '${appDocDir.path}/videos';
      final Directory videoDir = Directory(videoDirPath);

      if (await videoDir.exists()) {
        await videoDir.delete(recursive: true);
      }

      _cachedVideoPaths.clear();
      print('Video cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  static Future<int> getCacheSize() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String videoDirPath = '${appDocDir.path}/videos';
      final Directory videoDir = Directory(videoDirPath);

      if (!await videoDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      final List<FileSystemEntity> files = videoDir.listSync();

      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      print('Cache size: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB');
      return totalSize;
    } catch (e) {
      print('Error checking cache size: $e');
      return 0;
    }
  }

  // Get list of cached video files
  static Future<List<String>> getCachedVideoList() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String videoDirPath = '${appDocDir.path}/videos';
      final Directory videoDir = Directory(videoDirPath);

      if (!await videoDir.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = videoDir.listSync();
      final List<String> videoFiles = [];

      for (final file in files) {
        if (file is File && file.path.endsWith('.mp4')) {
          videoFiles.add(file.path.split('/').last);
        }
      }

      print('Cached videos: ${videoFiles.length} files');
      return videoFiles;
    } catch (e) {
      print('Error getting cached video list: $e');
      return [];
    }
  }

  // Check if a specific video is cached
  static Future<bool> isVideoCached(String assetPath) async {
    try {
      final String filename = assetPath.split('/').last;
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String localPath = '${appDocDir.path}/videos/$filename';
      final File localFile = File(localPath);

      return await localFile.exists();
    } catch (e) {
      print('Error checking if video is cached: $e');
      return false;
    }
  }

  // Delete specific video from cache
  static Future<bool> deleteCachedVideo(String assetPath) async {
    try {
      final String filename = assetPath.split('/').last;
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String localPath = '${appDocDir.path}/videos/$filename';
      final File localFile = File(localPath);

      if (await localFile.exists()) {
        await localFile.delete();
        _cachedVideoPaths.remove(assetPath);
        print('Deleted cached video: $filename');
        return true;
      }

      return false;
    } catch (e) {
      print('Error deleting cached video: $e');
      return false;
    }
  }

  // Get cache information
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final int size = await getCacheSize();
      final List<String> videos = await getCachedVideoList();

      return {
        'totalSize': size,
        'totalVideos': videos.length,
        'videoFiles': videos,
        'sizeInMB': (size / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      print('Error getting cache info: $e');
      return {
        'totalSize': 0,
        'totalVideos': 0,
        'videoFiles': [],
        'sizeInMB': '0.00',
      };
    }
  }
}