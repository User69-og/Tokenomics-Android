import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String apkUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.apkUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  // Replace this with your actual GitHub raw URL once published
  static const String _updateJsonUrl =
      'https://raw.githubusercontent.com/TokenomicsApp/Tokenomics-Android/main/update.json';
  
  static final Dio _dio = Dio();

  static Future<UpdateInfo> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _dio.get(_updateJsonUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> json;
        if (data is String) {
          json = jsonDecode(data);
        } else {
          json = data;
        }

        final latestVersion = json['version'] as String;
        final apkUrl = json['apkUrl'] as String;
        final releaseNotes = json['releaseNotes'] as String? ?? '';

        bool hasUpdate = _isNewerVersion(currentVersion, latestVersion);

        return UpdateInfo(
          hasUpdate: hasUpdate,
          latestVersion: latestVersion,
          apkUrl: apkUrl,
          releaseNotes: releaseNotes,
        );
      }
    } catch (e) {
      print('Error checking for update: $e');
    }
    
    return UpdateInfo(hasUpdate: false, latestVersion: '', apkUrl: '', releaseNotes: '');
  }

  static bool _isNewerVersion(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < currentParts.length; i++) {
      if (i >= latestParts.length) return false;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return latestParts.length > currentParts.length;
  }

  static Future<void> downloadAndInstallUpdate(
      String url, Function(double) onProgress) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/update.apk';

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            onProgress(progress);
          }
        },
      );

      // Open the APK file to trigger the Android Package Installer
      final result = await OpenFilex.open(savePath);
      print('Open result: ${result.type} - ${result.message}');
    } catch (e) {
      print('Error downloading update: $e');
      onProgress(-1); // Error state
    }
  }
}
