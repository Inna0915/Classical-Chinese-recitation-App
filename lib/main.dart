import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'constants/app_constants.dart';
import 'controllers/poem_controller.dart';
import 'controllers/player_controller.dart';
import 'pages/main_page.dart';
import 'services/settings_service.dart';
import 'services/tts_service.dart';
import 'services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化服务
  final settingsService = await Get.putAsync(() => SettingsService().init());
  
  // 同步音色设置到 TtsService
  TtsService().setVoiceType(settingsService.voiceType.value);
  
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
      final fontFamily = settingsService.currentFontFamily;
      
      return GetMaterialApp(
        title: '诗文朗诵',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(fontFamily),
        home: const MainPage(),
      );
    });
  }

  /// 构建应用主题
  /// 
  /// [fontFamily] 为 null 时使用系统默认字体
  ThemeData _buildTheme(String? fontFamily) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(UIConstants.backgroundColor),
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        primary: Color(UIConstants.primaryColor),
        secondary: Color(UIConstants.accentColor),
        surface: Color(UIConstants.cardColor),
        background: Color(UIConstants.backgroundColor),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(UIConstants.textPrimaryColor),
        onBackground: Color(UIConstants.textPrimaryColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(UIConstants.backgroundColor),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: const Color(UIConstants.textPrimaryColor),
          fontFamily: fontFamily,
          fontSize: FontConstants.titleSize,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(
          color: Color(UIConstants.textPrimaryColor),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          color: const Color(UIConstants.textPrimaryColor),
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          color: const Color(UIConstants.textPrimaryColor),
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          color: const Color(UIConstants.textPrimaryColor),
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          color: const Color(UIConstants.textPrimaryColor),
        ),
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          color: const Color(UIConstants.textPrimaryColor),
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          color: const Color(UIConstants.textSecondaryColor),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(UIConstants.dividerColor),
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(UIConstants.cardColor),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(UIConstants.cardColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(UIConstants.accentColor),
        foregroundColor: Colors.white,
      ),
    );
  }
}
