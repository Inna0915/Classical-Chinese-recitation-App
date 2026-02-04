/// GitHub Release 模型
/// 解析 GitHub API 返回的 Release 信息
class GithubRelease {
  final String tagName;
  final String name;
  final String body;
  final DateTime publishedAt;
  final List<ReleaseAsset> assets;
  final bool prerelease;
  final bool draft;

  GithubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.assets,
    required this.prerelease,
    required this.draft,
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    return GithubRelease(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      publishedAt: DateTime.parse(json['published_at'] as String? ?? DateTime.now().toIso8601String()),
      assets: (json['assets'] as List<dynamic>?)
              ?.map((e) => ReleaseAsset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      prerelease: json['prerelease'] as bool? ?? false,
      draft: json['draft'] as bool? ?? false,
    );
  }

  /// 获取 APK 下载链接
  String? get apkDownloadUrl {
    for (final asset in assets) {
      if (asset.browserDownloadUrl.endsWith('.apk')) {
        return asset.browserDownloadUrl;
      }
    }
    return null;
  }

  /// 获取版本号（去掉 v 前缀）
  String get version {
    String v = tagName;
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1);
    }
    return v;
  }
}

/// Release 资源文件
class ReleaseAsset {
  final String name;
  final String browserDownloadUrl;
  final int size;
  final int downloadCount;

  ReleaseAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.size,
    required this.downloadCount,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String? ?? '',
      browserDownloadUrl: json['browser_download_url'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      downloadCount: json['download_count'] as int? ?? 0,
    );
  }
}
