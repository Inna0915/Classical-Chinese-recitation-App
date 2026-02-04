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
import '../core/theme/app_theme.dart';
import '../models/github_release.dart';
import '../widgets/dialogs/app_dialog.dart';

/// 更新服务 - 管理应用自动更新
/// 
/// Android 13+ 适配说明：
/// - 使用应用私有缓存目录 (getTemporaryDirectory) 下载 APK，无需存储权限
/// - 申请通知权限 (Android 13+) 用于显示下载进度
/// - 使用 FileProvider 安装 APK
class UpdateService extends GetxService {
  static UpdateService get to => Get.find();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
    followRedirects: true,
    maxRedirects: 5,
    validateStatus: (status) => status != null && status < 500,
    headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) Chrome/91.0.4472.120',
    },
  ));

  // GitHub 仓库信息
  static const String _owner = 'Inna0915';
  static const String _repo = 'Classical-Chinese-recitation-App';
  static const String _apiUrl = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  // 下载加速前缀（可配置）
  static const String _mirrorPrefix = 'https://mirror.ghproxy.com/';
  bool _useMirror = false;

  // 状态
  final RxBool isChecking = false.obs;
  final RxBool isDownloading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxString downloadStatus = ''.obs;
  final RxString currentVersion = ''.obs;
  final RxBool hasNotificationPermission = false.obs;

  // 下载文件路径
  String? _downloadedFilePath;

  @override
  void onInit() {
    super.onInit();
    _initVersion();
    _checkNotificationPermission();
  }

  /// 初始化获取当前版本
  Future<void> _initVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = packageInfo.version;
  }

  /// 检查通知权限状态
  Future<void> _checkNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      hasNotificationPermission.value = status.isGranted;
    }
  }

  /// 请求通知权限（Android 13+ 需要）
  Future<bool> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    
    final status = await Permission.notification.request();
    hasNotificationPermission.value = status.isGranted;
    
    if (!status.isGranted) {
      debugPrint('[UpdateService] Notification permission denied');
      // 权限被拒绝，但下载仍然可以继续，只是没有通知提示
      return false;
    }
    return true;
  }

  /// 检查更新
  /// 
  /// [isManual] 是否为手动点击检查，手动检查时会显示"已是最新"提示
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
        // 手动检查且已是最新 - 使用美观的对话框
        AppDialog.success(
          title: '已是最新版本',
          message: '当前版本 $currentV 已是最新版本',
          confirmText: '确定',
        );
      }
    } on DioException catch (e) {
      debugPrint('[UpdateService] Network error: $e');
      if (isManual) {
        AppDialog.info(
          title: '检查失败',
          message: '网络连接异常，请稍后重试',
        );
      }
    } catch (e) {
      debugPrint('[UpdateService] Error: $e');
      if (isManual) {
        AppDialog.info(
          title: '检查失败',
          message: '检查更新时发生错误',
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
      Builder(
        builder: (context) {
          return AlertDialog(
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Center(
              child: Text(
                '发现新版本 v${release.version}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 320,
                maxHeight: Get.height * 0.5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    release.name.isNotEmpty ? release.name : '新版本更新',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        release.body.isNotEmpty ? release.body : '暂无更新说明',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondaryColor,
                          height: 1.5,
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
                          backgroundColor: context.dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          downloadStatus.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Obx(() => TextButton(
                onPressed: isDownloading.value ? null : () => Get.back(),
                child: Text(
                  '稍后',
                  style: TextStyle(
                    color: isDownloading.value 
                        ? context.textSecondaryColor.withValues(alpha: 0.5)
                        : context.textSecondaryColor,
                  ),
                ),
              )),
              Obx(() => ElevatedButton(
                onPressed: isDownloading.value
                    ? null
                    : () => _startDownload(apkUrl),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isDownloading.value ? '下载中...' : '立即更新'),
              )),
            ],
          );
        },
      ),
      barrierDismissible: !isDownloading.value,
    );
  }

  /// 开始下载 APK
  /// 
  /// Android 13+ 适配：
  /// - 使用应用私有缓存目录，无需申请存储权限
  /// - 申请通知权限用于显示下载进度（可选）
  Future<void> _startDownload(String apkUrl) async {
    try {
      isDownloading.value = true;
      downloadProgress.value = 0;
      downloadStatus.value = '准备下载...';

      // 1. 请求通知权限（Android 13+ 需要）
      await _requestNotificationPermission();

      // 2. 获取应用私有缓存目录 - Android 13+ 无需存储权限
      final directory = await getTemporaryDirectory();
      final savePath = '${directory.path}/guyun_update.apk';
      _downloadedFilePath = savePath;

      debugPrint('[UpdateService] Download to: $savePath');

      // 3. 尝试下载（先使用镜像，失败则回退到原始 URL）
      bool downloadSuccess = false;
      
      // 尝试 1: 使用镜像
      if (_useMirror && apkUrl.contains('github.com')) {
        final mirrorUrl = '$_mirrorPrefix$apkUrl';
        debugPrint('[UpdateService] Trying mirror: $mirrorUrl');
        downloadSuccess = await _tryDownload(mirrorUrl, savePath);
      }
      
      // 尝试 2: 使用原始 URL
      if (!downloadSuccess) {
        debugPrint('[UpdateService] Trying original URL: $apkUrl');
        downloadStatus.value = '尝试直接下载...';
        downloadSuccess = await _tryDownload(apkUrl, savePath);
      }
      
      if (!downloadSuccess) {
        throw DioException(
          requestOptions: RequestOptions(path: apkUrl),
          error: '所有下载方式均失败',
        );
      }

      downloadStatus.value = '下载完成，准备安装...';
      
      // 关闭对话框
      Get.back();

      // 4. 安装 APK
      await _installApk(savePath);

    } on DioException catch (e) {
      debugPrint('[UpdateService] Download error: ${e.type}, ${e.message}');
      downloadStatus.value = '下载失败';
      AppDialog.info(
        title: '下载失败',
        message: _getErrorMessage(e),
      );
    } catch (e) {
      debugPrint('[UpdateService] Error: $e');
      downloadStatus.value = '下载失败';
      AppDialog.info(
        title: '下载失败',
        message: '发生错误: $e',
      );
    } finally {
      isDownloading.value = false;
    }
  }
  
  /// 尝试下载文件
  Future<bool> _tryDownload(String url, String savePath) async {
    try {
      await _dio.download(
        url,
        savePath,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total * 100).toDouble();
            downloadProgress.value = progress;
            downloadStatus.value = '下载中 ${progress.toStringAsFixed(1)}%';
          } else if (received > 0) {
            // 未知总大小时显示已下载大小
            final mb = (received / 1024 / 1024).toStringAsFixed(2);
            downloadStatus.value = '已下载 ${mb}MB';
          }
        },
      );
      return true;
    } on DioException catch (e) {
      debugPrint('[UpdateService] Download failed from $url: ${e.type} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[UpdateService] Download failed from $url: $e');
      return false;
    }
  }
  
  /// 获取错误提示信息
  String _getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '连接超时，请检查网络后重试';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络设置';
      case DioExceptionType.badResponse:
        return '服务器响应错误 (${e.response?.statusCode})';
      case DioExceptionType.cancel:
        return '下载已取消';
      default:
        return '网络异常，请稍后重试';
    }
  }

  /// 安装 APK
  /// 
  /// 使用 FileProvider 读取 APK 文件（Android 7.0+ 必需）
  Future<void> _installApk(String filePath) async {
    try {
      debugPrint('[UpdateService] Installing APK: $filePath');
      final result = await OpenFilex.open(filePath);
      debugPrint('[UpdateService] Open file result: ${result.message}');
    } catch (e) {
      debugPrint('[UpdateService] Install error: $e');
      Get.snackbar(
        '安装失败',
        '无法打开安装文件，请手动安装',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// 设置是否使用镜像加速
  void setUseMirror(bool use) {
    _useMirror = use;
  }

  /// 清理下载的 APK 文件
  Future<void> clearDownloadedFile() async {
    if (_downloadedFilePath != null) {
      try {
        final file = File(_downloadedFilePath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('[UpdateService] Cleared downloaded file');
        }
      } catch (e) {
        debugPrint('[UpdateService] Failed to clear file: $e');
      }
    }
  }
}

/*
================================================================================
AndroidManifest.xml 配置说明
================================================================================

1. 必需权限（已配置）：
   
   <!-- 网络权限 -->
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   
   <!-- 安装应用权限（Android 8.0+） -->
   <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
   
   <!-- 通知权限（Android 13+） -->
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

2. FileProvider 配置（已配置）：
   
   <application>
       <!-- FileProvider - 用于安装 APK（Android 7.0+ 必需） -->
       <provider
           android:name="androidx.core.content.FileProvider"
           android:authorities="${applicationId}.fileprovider"
           android:exported="false"
           android:grantUriPermissions="true">
           <meta-data
               android:name="android.support.FILE_PROVIDER_PATHS"
               android:resource="@xml/file_paths" />
       </provider>
   </application>

3. file_paths.xml 配置（android/app/src/main/res/xml/file_paths.xml）：
   
   <?xml version="1.0" encoding="utf-8"?>
   <paths>
       <!-- 应用私有缓存目录 -->
       <cache-path name="cache" path="." />
       
       <!-- 应用私有文件目录 -->
       <files-path name="files" path="." />
       
       <!-- 外部缓存目录（兼容旧版本） -->
       <external-cache-path name="external_cache" path="." />
   </paths>

================================================================================
Android 13+ 适配要点
================================================================================

1. 不需要申请的权限（已移除）：
   ❌ android.permission.READ_EXTERNAL_STORAGE
   ❌ android.permission.WRITE_EXTERNAL_STORAGE

2. 推荐使用的目录：
   ✅ getTemporaryDirectory() - /data/data/<package>/cache
   ✅ getApplicationSupportDirectory() - /data/data/<package>/files
   
   这些目录不需要任何权限即可读写。

3. 需要申请的权限：
   ✅ android.permission.POST_NOTIFICATIONS (Android 13+)
     - 用于显示下载进度通知
     - 可选，不申请也能下载，只是没有通知提示

4. 安装 APK：
   ✅ 必须使用 FileProvider
   ✅ 必须申请 REQUEST_INSTALL_PACKAGES 权限
================================================================================
*/
