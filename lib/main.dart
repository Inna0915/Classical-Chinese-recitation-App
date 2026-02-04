import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'controllers/poem_controller.dart';
import 'controllers/player_controller.dart';
import 'pages/main_page.dart';
import 'services/settings_service.dart';
import 'services/tts_service.dart';
import 'services/update_service.dart';
import 'services/poem_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化服务
  final settingsService = await Get.putAsync(() => SettingsService().init());
  
  // 同步音色设置到 TtsService
  TtsService().setVoiceType(settingsService.voiceType.value);
  
  // 初始化新的 PoemService (标签+歌单架构)
  Get.put(PoemService());
  
  // 旧控制器保持兼容（逐步迁移）
  Get.put(PoemController());
  Get.put(PlayerController());
  Get.put(UpdateService());
  
  runApp(const GuYunReaderApp());
}

class GuYunReaderApp extends StatelessWidget {
  const GuYunReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final settingsService = SettingsService.to;
      
      // 使用新的主题系统
      final theme = AppTheme.getThemeData(
        primaryColor: settingsService.primaryColor.value,
        isDarkMode: settingsService.isDarkMode,
        fontFamily: settingsService.currentFontFamily,
      );
      
      return GetMaterialApp(
        title: '古韵诵读',
        debugShowCheckedModeBanner: false,
        theme: theme,
        themeMode: settingsService.themeMode.value,
        home: const MainPage(),
      );
    });
  }
}
