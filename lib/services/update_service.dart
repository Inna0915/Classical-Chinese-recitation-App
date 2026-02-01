import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/update_info.dart';

/// 更新服务类 - 处理 GitHub Release 自动更新
class UpdateService {
  // ==================== 配置参数 ====================
  
  /// GitHub 仓库所有者
  static const String repoOwner = 'YOUR_GITHUB_USERNAME';
  
  /// GitHub 仓库名
  static const String repoName = 'YOUR_REPO_NAME';
  
  /// GitHub API 基础地址
  static const String _githubApiUrl = 'https://api.github.com/repos';
  
  /// Gitee 镜像 API（国内网络 fallback）
  static const String _giteeApiUrl = 'https://gitee.com/api/v5/repos';
  
  /// 请求超时时间
  static const Duration _timeout = Duration(seconds: 10);
  
  /// SharedPreferences key - 忽略的版本
  static const String _ignoredVersionKey = 'ignored_update_version';
  
  /// SharedPreferences key - 最后检查时间
  static const String _lastCheckTimeKey = 'last_update_check_time';

  // ==================== Dio 实例 ====================
  
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: _timeout,
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/vnd.github.v3+json',
    },
  ));

  // ==================== 版本检查 ====================
  
  /// 获取当前应用版本号
  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// 检查更新
  /// 
  /// 返回 [UpdateInfo] 表示有更新，返回 null 表示无更新或检查失败
  /// [checkIgnored] 是否检查被忽略的版本
  /// [useGitee] 是否使用 Gitee 镜像（国内网络）
  static Future<UpdateInfo?> checkUpdate({
    bool checkIgnored = true,
    bool useGitee = false,
  }) async {
    try {
      // 获取远程版本信息
      final updateInfo = await _fetchLatestRelease(useGitee: useGitee);
      if (updateInfo == null) return null;
      
      // 检查是否有有效的下载链接
      if (!updateInfo.hasValidDownloadUrl) {
        debugPrint('UpdateService: 没有找到 APK 下载链接');
        return null;
      }
      
      // 获取当前版本
      final currentVersion = await getCurrentVersion();
      
      // 版本比较
      if (!_shouldUpdate(currentVersion, updateInfo.version)) {
        debugPrint('UpdateService: 当前已是最新版本');
        return null;
      }
      
      // 检查是否被忽略（非强制更新时）
      if (checkIgnored && !updateInfo.isForce) {
        final isIgnored = await _isVersionIgnored(updateInfo.version);
        if (isIgnored) {
          debugPrint('UpdateService: 用户已忽略版本 ${updateInfo.version}');
          return null;
        }
      }
      
      // 记录检查时间
      await _recordCheckTime();
      
      return updateInfo;
    } on DioException catch (e) {
      debugPrint('UpdateService: 网络错误 - ${e.message}');
      
      // 如果是 GitHub 请求失败且未尝试 Gitee，尝试 Gitee
      if (!useGitee && e.type == DioExceptionType.connectionTimeout) {
        debugPrint('UpdateService: 尝试 Gitee 镜像...');
        return checkUpdate(checkIgnored: checkIgnored, useGitee: true);
      }
      
      return null;
    } catch (e) {
      debugPrint('UpdateService: 检查更新失败 - $e');
      return null;
    }
  }

  /// 从 GitHub/Gitee 获取最新 Release 信息
  static Future<UpdateInfo?> _fetchLatestRelease({bool useGitee = false}) async {
    String url;
    if (useGitee) {
      // Gitee API: /repos/{owner}/{repo}/releases/latest
      url = '$_giteeApiUrl/$repoOwner/$repoName/releases/latest';
    } else {
      // GitHub API: /repos/{owner}/{repo}/releases/latest
      url = '$_githubApiUrl/$repoOwner/$repoName/releases/latest';
    }
    
    final response = await _dio.get(url);
    if (response.statusCode == 200 && response.data != null) {
      return UpdateInfo.fromGitHubRelease(response.data as Map<String, dynamic>);
    }
    return null;
  }

  /// 语义化版本比较
  /// 
  /// 返回 true 表示需要更新（remoteVersion > localVersion）
  static bool _shouldUpdate(String localVersion, String remoteVersion) {
    try {
      final local = _parseVersion(localVersion);
      final remote = _parseVersion(remoteVersion);
      
      // 逐位比较
      for (int i = 0; i < 3; i++) {
        if (remote[i] > local[i]) return true;
        if (remote[i] < local[i]) return false;
      }
      
      // 版本号完全相同，不需要更新
      return false;
    } catch (e) {
      debugPrint('UpdateService: 版本号解析失败 - $e');
      return false;
    }
  }

  /// 解析三段式版本号为整数数组
  /// 
  /// "1.2.3" → [1, 2, 3]
  /// "1.2" → [1, 2, 0]
  static List<int> _parseVersion(String version) {
    // 去除可能的前缀（如 v1.0.0）
    String cleanVersion = version.trim();
    if (cleanVersion.startsWith('v') || cleanVersion.startsWith('V')) {
      cleanVersion = cleanVersion.substring(1);
    }
    
    // 解析版本号
    final parts = cleanVersion.split('.');
    final result = <int>[];
    
    for (int i = 0; i < 3; i++) {
      if (i < parts.length) {
        result.add(int.tryParse(parts[i]) ?? 0);
      } else {
        result.add(0);
      }
    }
    
    return result;
  }

  // ==================== 下载与安装 ====================

  /// 下载并安装 APK
  /// 
  /// [updateInfo] 更新信息
  /// [onProgress] 下载进度回调 (0.0 ~ 1.0)
  static Future<UpdateResult> downloadAndInstall(
    UpdateInfo updateInfo, {
    Function(double progress)? onProgress,
  }) async {
    // Web 平台不支持下载安装
    if (kIsWeb) {
      return UpdateResult.installFailed;
    }
    
    try {
      // 1. 检查下载链接
      if (!updateInfo.hasValidDownloadUrl) {
        return UpdateResult.noApk;
      }
      
      // 2. 申请安装权限
      final hasPermission = await _requestInstallPermission();
      if (!hasPermission) {
        return UpdateResult.permissionDenied;
      }
      
      // 3. 获取下载路径
      final tempDir = await getTemporaryDirectory();
      final apkFileName = 'update_${updateInfo.version}.apk';
      final apkPath = '${tempDir.path}/$apkFileName';
      
      // 4. 删除旧文件（如果存在）
      final oldFile = File(apkPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
      
      // 5. 下载 APK
      await _dio.download(
        updateInfo.downloadUrl,
        apkPath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );
      
      // 6. 验证文件
      final file = File(apkPath);
      if (!await file.exists() || await file.length() == 0) {
        return UpdateResult.downloadFailed;
      }
      
      // 7. 打开安装界面
      final result = await OpenFilex.open(apkPath);
      if (result.type != ResultType.done) {
        debugPrint('UpdateService: 打开安装界面失败 - ${result.message}');
        return UpdateResult.installFailed;
      }
      
      return UpdateResult.success;
    } on DioException catch (e) {
      debugPrint('UpdateService: 下载失败 - ${e.message}');
      return UpdateResult.downloadFailed;
    } catch (e) {
      debugPrint('UpdateService: 安装失败 - $e');
      return UpdateResult.installFailed;
    }
  }

  /// 申请安装权限
  static Future<bool> _requestInstallPermission() async {
    // Web 平台不支持
    if (kIsWeb) return false;
    
    // Android 8.0+ 需要 REQUEST_INSTALL_PACKAGES 权限
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        final result = await Permission.requestInstallPackages.request();
        if (!result.isGranted) {
          return false;
        }
      }
    }
    return true;
  }

  // ==================== 忽略版本管理 ====================

  /// 忽略指定版本
  static Future<void> ignoreVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ignoredVersionKey, version);
  }

  /// 检查版本是否被忽略
  static Future<bool> _isVersionIgnored(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final ignored = prefs.getString(_ignoredVersionKey);
    return ignored == version;
  }

  /// 清除忽略的版本记录
  static Future<void> clearIgnoredVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ignoredVersionKey);
  }

  // ==================== 检查时间管理 ====================

  /// 记录最后检查时间
  static Future<void> _recordCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 获取最后检查时间
  static Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastCheckTimeKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// 是否应该自动检查（距离上次检查超过 24 小时）
  static Future<bool> shouldAutoCheck() async {
    final lastCheck = await getLastCheckTime();
    if (lastCheck == null) return true;
    
    final now = DateTime.now();
    final diff = now.difference(lastCheck);
    return diff.inHours >= 24;
  }

  // ==================== UI 辅助方法 ====================

  /// 显示更新对话框（简化版）
  static Future<void> showUpdateDialog(UpdateInfo updateInfo) async {
    final result = await Get.dialog<bool>(
      barrierDismissible: !updateInfo.isForce,
      AlertDialog(
        backgroundColor: const Color(0xFFFAF8F3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: const Color(0xFFC45C48),
            ),
            const SizedBox(width: 8),
            const Text(
              '发现新版本',
              style: TextStyle(
                fontFamily: 'NotoSerifSC',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'v${updateInfo.version}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC45C48),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '更新内容：',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  updateInfo.changelog.isEmpty 
                      ? '优化了一些已知问题' 
                      : updateInfo.changelog,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ),
            if (updateInfo.isForce) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '此版本必须更新',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!updateInfo.isForce) ...[
            TextButton(
              onPressed: () {
                ignoreVersion(updateInfo.version);
                Get.back(result: false);
              },
              child: const Text(
                '忽略此版本',
                style: TextStyle(color: Color(0xFF666666)),
              ),
            ),
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('稍后'),
            ),
          ],
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC45C48),
              foregroundColor: Colors.white,
            ),
            child: Text(kIsWeb ? '查看更新' : '立即更新'),
          ),
        ],
      ),
    );

    // 用户选择更新
    if (result == true) {
      if (kIsWeb) {
        // Web 平台：显示提示
        Get.dialog(
          AlertDialog(
            backgroundColor: const Color(0xFFFAF8F3),
            title: const Text('请下载 Android 版本'),
            content: const Text('Web 版本不支持自动更新，请下载 Android APK 使用完整功能。'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      } else {
        await _showDownloadDialog(updateInfo);
      }
    }
  }

  /// 显示下载进度对话框
  static Future<void> _showDownloadDialog(UpdateInfo updateInfo) async {
    final RxDouble progress = 0.0.obs;
    final RxString status = '正在下载...'.obs;
    
    // 显示下载进度对话框
    Get.dialog(
      barrierDismissible: false,
      Obx(() => AlertDialog(
        backgroundColor: const Color(0xFFFAF8F3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '下载更新',
          style: TextStyle(
            fontFamily: 'NotoSerifSC',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: progress.value,
              color: const Color(0xFFC45C48),
            ),
            const SizedBox(height: 16),
            Text(
              status.value,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress.value * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      )),
    );

    // 开始下载
    final result = await downloadAndInstall(
      updateInfo,
      onProgress: (p) => progress.value = p,
    );

    // 关闭下载对话框
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    // 处理结果
    switch (result) {
      case UpdateResult.success:
        // 安装界面已调起，无需提示
        break;
      case UpdateResult.noApk:
        _showErrorDialog('未找到安装包', 'GitHub Release 中没有上传 APK 文件');
        break;
      case UpdateResult.permissionDenied:
        _showPermissionDeniedDialog();
        break;
      case UpdateResult.downloadFailed:
        _showErrorDialog('下载失败', '网络连接失败，请检查网络后重试');
        break;
      case UpdateResult.installFailed:
        _showErrorDialog('安装失败', '无法打开安装包，请手动安装');
        break;
    }
  }

  /// 显示错误对话框
  static void _showErrorDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFFAF8F3),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示权限拒绝对话框
  static void _showPermissionDeniedDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFFFAF8F3),
        title: const Text('需要安装权限'),
        content: const Text('请允许应用安装未知来源应用，以便完成更新'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC45C48),
              foregroundColor: Colors.white,
            ),
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 检查更新并显示对话框（一键方法）
  static Future<void> checkAndShowUpdate({bool showNoUpdate = false}) async {
    // 显示加载中
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    final updateInfo = await checkUpdate();

    // 关闭加载
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    if (updateInfo != null) {
      await showUpdateDialog(updateInfo);
    } else if (showNoUpdate) {
      Get.snackbar(
        '检查更新',
        '当前已是最新版本',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

/// 更新结果枚举
enum UpdateResult {
  /// 更新成功（安装界面已调起）
  success,
  
  /// 没有找到 APK 文件
  noApk,
  
  /// 权限被拒绝
  permissionDenied,
  
  /// 下载失败
  downloadFailed,
  
  /// 安装失败
  installFailed,
}
