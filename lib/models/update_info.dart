/// 更新信息数据模型
class UpdateInfo {
  /// 远程版本号（已去除 v 前缀）
  final String version;
  
  /// 更新日志
  final String changelog;
  
  /// APK 下载链接
  final String downloadUrl;
  
  /// 发布日期
  final DateTime? publishedAt;
  
  /// 是否为强制更新
  final bool isForce;

  UpdateInfo({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    this.publishedAt,
    this.isForce = false,
  });

  factory UpdateInfo.fromGitHubRelease(Map<String, dynamic> json) {
    // 获取版本号，去除 v 前缀
    String tagName = json['tag_name']?.toString() ?? '';
    String version = tagName.startsWith('v') 
        ? tagName.substring(1) 
        : tagName;
    
    // 解析是否为强制更新（在 release body 中包含 #force 标记）
    String body = json['body']?.toString() ?? '';
    bool isForce = body.contains('#force') || body.contains('#强制更新');
    
    // 从 assets 中找到 APK 文件
    String? apkUrl;
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final asset in assets) {
        final name = asset['name']?.toString() ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url']?.toString();
          break;
        }
      }
    }
    
    return UpdateInfo(
      version: version,
      changelog: body,
      downloadUrl: apkUrl ?? '',
      publishedAt: json['published_at'] != null 
          ? DateTime.tryParse(json['published_at']) 
          : null,
      isForce: isForce,
    );
  }

  /// 检查下载链接是否有效
  bool get hasValidDownloadUrl => downloadUrl.isNotEmpty;

  @override
  String toString() {
    return 'UpdateInfo{version: $version, isForce: $isForce, hasUrl: $hasValidDownloadUrl}';
  }
}
