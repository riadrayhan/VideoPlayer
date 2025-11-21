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
      print('ভিডিও লোড করতে সমস্যা: $assetPath - $e');
      throw Exception('ভিডিও লোড করতে পারছি না: $assetPath');
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

      print('ভিডিও কপি করা হয়েছে: $assetPath → $localPath');
    } catch (e) {
      print('ভিডিও কপি করতে সমস্যা: $assetPath - $e');
      throw Exception('ভিডিও কপি করতে পারছি না: $assetPath');
    }
  }

  static Future<void> preloadVideos(List<String> assetPaths, BuildContext context) async {
    for (final assetPath in assetPaths) {
      try {
        await getLocalPath(context, assetPath);
      } catch (e) {
        print('প্রিলোড করতে সমস্যা: $assetPath - $e');
      }
    }
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
      print('ভিডিও ক্যাশে ক্লিয়ার করা হয়েছে');
    } catch (e) {
      print('ক্যাশে ক্লিয়ার করতে সমস্যা: $e');
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

      return totalSize;
    } catch (e) {
      print('ক্যাশে সাইজ চেক করতে সমস্যা: $e');
      return 0;
    }
  }
}