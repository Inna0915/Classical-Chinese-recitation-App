import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'constants/app_constants.dart';
import 'controllers/poem_controller.dart';
import 'pages/poem_list_page.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化服务
  await Get.putAsync(() => SettingsService().init());
  Get.put(PoemController());
  
  runApp(const GuYunReaderApp());
}

class GuYunReaderApp extends StatelessWidget {
  const GuYunReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '古韵诵读',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const PoemListPage(),
    );
  }

  /// 构建应用主题
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(UIConstants.backgroundColor),
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(UIConstants.backgroundColor),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(UIConstants.textPrimaryColor),
          fontFamily: FontConstants.chineseSerif,
          fontSize: FontConstants.titleSize,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: Color(UIConstants.textPrimaryColor),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: FontConstants.chineseSerif,
          color: Color(UIConstants.textPrimaryColor),
        ),
        headlineMedium: TextStyle(
          fontFamily: FontConstants.chineseSerif,
          color: Color(UIConstants.textPrimaryColor),
        ),
        titleLarge: TextStyle(
          fontFamily: FontConstants.chineseSerif,
          color: Color(UIConstants.textPrimaryColor),
        ),
        titleMedium: TextStyle(
          fontFamily: FontConstants.chineseSerif,
          color: Color(UIConstants.textPrimaryColor),
        ),
        bodyLarge: TextStyle(
          fontFamily: FontConstants.chineseSerif,
          color: Color(UIConstants.textPrimaryColor),
        ),
        bodyMedium: TextStyle(
          fontFamily: FontConstants.chineseSerif,
          color: Color(UIConstants.textSecondaryColor),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(UIConstants.dividerColor),
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(UIConstants.cardColor),
      ),
      dialogTheme: DialogTheme(
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
