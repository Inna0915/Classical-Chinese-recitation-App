# Android 配置指南

## 1. AndroidManifest.xml 配置

在 `android/app/src/main/AndroidManifest.xml` 中添加以下权限：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- ==================== 网络权限 ==================== -->
    <!-- 访问互联网权限（必需）用于请求 TTS API -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- 访问网络状态权限（建议）用于检测网络连接状态 -->
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- ==================== 存储权限 ==================== -->
    <!-- Android 13+ (API 33+) 使用新的媒体权限 -->
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
    
    <!-- Android 12 及以下版本使用传统存储权限 -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="29" />
    
    <!-- ==================== 音频权限 ==================== -->
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    
    <!-- ==================== 唤醒权限（可选）=================== -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <application
        android:label="古韵诵读"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false"
        android:requestLegacyExternalStorage="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
              
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

## 2. 最低 SDK 版本配置

在 `android/app/build.gradle` 中确保最低 SDK 版本：

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // 最低支持 Android 5.0
        targetSdkVersion 34
        // ...
    }
}
```

## 3. 权限说明

| 权限 | 用途 | 必需 |
|------|------|------|
| `INTERNET` | 访问 TTS API | ✅ |
| `ACCESS_NETWORK_STATE` | 检测网络状态 | ❌（建议） |
| `READ_MEDIA_AUDIO` | Android 13+ 读取音频 | ❌ |
| `READ_EXTERNAL_STORAGE` | 读取缓存音频 | ❌ |
| `WRITE_EXTERNAL_STORAGE` | 保存音频缓存 | ❌ |
| `MODIFY_AUDIO_SETTINGS` | 调整音频设置 | ❌ |
| `WAKE_LOCK` | 保持 CPU 唤醒 | ❌ |

## 4. ProGuard 配置（如需混淆）

在 `android/app/proguard-rules.pro` 中添加：

```proguard
# Dio
-keep class com.google.gson.** { *; }

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# sqflite
-keep class com.tekartik.sqflite.** { *; }
```
