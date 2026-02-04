import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pub_semver/pub_semver.dart';
import '../constants/app_constants.dart';
import '../models/github_release.dart';

/// 更新服务 - 管理应用自动更新
class UpdateService extends GetxService {
  static UpdateService get to => Get.find();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
  ));

  // GitHub 仓库信息
  static const String _owner = 'Inna0915';
  static const String _repo = 'Classical-Chinese-recitation-App';
  static const String _apiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  // 下载加速前缀（可配置）
  static const String _mirrorPrefix = 'https://mirror.ghproxy.com/';
  bool _useMirror = true;

  // 状态
  final RxBool isChecking = false.obs;
  final RxBool isDownloading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxString downloadStatus = ''.obs;
  final RxString currentVersion = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initVersion();
  }

  /// 初始化获取当前版本
  Future<void> _initVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = packageInfo.version;
  }

  /// 检查更新
  Future<void> checkUpdate({bool isManual = false}) async {
    if (isChecking.value) return;

    // 仅支持 Android
    if (!Platform.isAndroid) {
      if (isManual) {
        Get.snackbar(
          '提示',
          'iOS 版本请前往 App Store 更新',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    isChecking.value = true;

    try {
      // 获取当前版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentV = packageInfo.version;

      debugPrint('[UpdateService] Current version: $currentV');

      // 请求 GitHub API
      final response = await _dio.get(_apiUrl);
      final release = GithubRelease.fromJson(response.data as Map<String, dynamic>);

      debugPrint('[UpdateService] Latest version: ${release.version}');

      // 检查是否有更新
      if (_hasUpdate(currentV, release.version)) {
        _showUpdateDialog(release);
      } else if (isManual) {
        // 手动检查且已是最新
        Get.snackbar(
          '已是最新版本',
          '当前版本 $currentV 已是最新',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on DioException catch (e) {
      debugPrint('[UpdateService] Network error: $e');
      if (isManual) {
        Get.snackbar(
          '检查失败',
          '网络连接异常，请稍后重试',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] Error: $e');
      if (isManual) {
        Get.snackbar(
          '检查失败',
          '检查更新时发生错误',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isChecking.value = false;
    }
  }

  /// 比较版本号
  bool _hasUpdate(String current, String latest) {
    try {
      final currentV = Version.parse(current);
      final latestV = Version.parse(latest);
      return latestV > currentV;
    } catch (e) {
      return latest != current;
    }
  }

  /// 显示更新对话框
  void _showUpdateDialog(GithubRelease release) {
    final apkUrl = release.apkDownloadUrl;
    if (apkUrl == null) {
      debugPrint('[UpdateService] No APK found in release');
      return;
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        title: Text(
          '发现新版本 v${release.version}',
          style: const TextStyle(
            fontFamily: FontConstants.chineseSerif,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                release.name.isNotEmpty ? release.name : '新版本更新',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(UIConstants.accentColor),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    release.body.isNotEmpty ? release.body : '暂无更新说明',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(UIConstants.textSecondaryColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 下载进度显示
              Obx(() {
                if (!isDownloading.value) return const SizedBox.shrink();
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: downloadProgress.value / 100,
                      backgroundColor: const Color(UIConstants.dividerColor),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(UIConstants.accentColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      downloadStatus.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(UIConstants.textSecondaryColor),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isDownloading.value ? null : () => Get.back(),
            child: const Text(
              '稍后',
              style: TextStyle(
                color: Color(UIConstants.textSecondaryColor),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: isDownloading.value
                ? null
                : () => _startDownload(apkUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(UIConstants.accentColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('立即更新'),
          ),
        ],
      ),
      barrierDismissible: !isDownloading.value,
    );
  }

  /// 开始下载 APK
  Future<void> _startDownload(String apkUrl) async {
    // 请求存储权限
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      Get.snackbar(
        '权限 denied',
        '需要存储权限才能下载更新',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isDownloading.value = true;
      downloadProgress.value = 0;
      downloadStatus.value = '准备下载...';

      // 应用镜像加速
      String downloadUrl = apkUrl;
      if (_useMirror && apkUrl.contains('github.com')) {
        downloadUrl = '$_mirrorPrefix$apkUrl';
        debugPrint('[UpdateService] Using mirror: $downloadUrl');
      }

      // 获取下载目录
      final directory = await getExternalStorageDirectory();
      final savePath = '${directory?.path}/guyun-release.apk';

      debugPrint('[UpdateService] Download to: $savePath');

      // 开始下载
      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total * 100).toDouble();
            downloadProgress.value = progress;
            downloadStatus.value = '下载中 ${progress.toStringAsFixed(1)}%';
          }
        },
      );

      downloadStatus.value = '下载完成，准备安装...';
      
      // 关闭对话框
      Get.back();

      // 安装 APK
      await _installApk(savePath);

    } on DioException catch (e) {
      debugPrint('[UpdateService] Download error: $e');
      downloadStatus.value = '下载失败';
      Get.snackbar(
        '下载失败',
        '网络异常，请稍后重试',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('[UpdateService] Error: $e');
      downloadStatus.value = '下载失败';
      Get.snackbar(
        '下载失败',
        '发生错误: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDownloading.value = false;
    }
  }

  /// 安装 APK
  Future<void> _installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      debugPrint('[UpdateService] Open file result: ${result.message}');
    } catch (e) {
      debugPrint('[UpdateService] Install error: $e');
      Get.snackbar(
        '安装失败',
        '无法打开安装文件，请手动安装: $filePath',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// 设置是否使用镜像加速
  void setUseMirror(bool use) {
    _useMirror = use;
  }
}
