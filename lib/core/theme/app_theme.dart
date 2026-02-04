import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

/// 中国传统色配色方案
/// 
/// 参考：
/// - 朱砂 (Cinnabar): 传统正红，热情庄重
/// - 竹青 (Bamboo Green): 清雅淡泊
/// - 黛蓝 (Indigo): 沉稳深邃
/// - 栀子 (Gardenia): 温暖明亮
/// - 暮山紫 (Twilight Purple): 淡雅诗意
/// - 玄青 (Dark Black): 极简内敛
class TraditionalChineseColors {
  /// 朱砂 (Cinnabar) - 默认主题色
  static const Color cinnabar = Color(0xFFC93836);
  
  /// 竹青 (Bamboo Green)
  static const Color bambooGreen = Color(0xFF789262);
  
  /// 黛蓝 (Indigo)
  static const Color indigo = Color(0xFF425066);
  
  /// 栀子 (Gardenia)
  static const Color gardenia = Color(0xFFE6C35C);
  
  /// 暮山紫 (Twilight Purple)
  static const Color twilightPurple = Color(0xFFA4ABD6);
  
  /// 玄青 (Dark Black)
  static const Color darkBlack = Color(0xFF3D3B4F);
  
  /// 获取所有主题色列表
  static const List<Color> allColors = [
    cinnabar,
    bambooGreen,
    indigo,
    gardenia,
    twilightPurple,
    darkBlack,
  ];
  
  /// 获取颜色名称
  static String getColorName(Color color) {
    if (color == cinnabar) return '朱砂';
    if (color == bambooGreen) return '竹青';
    if (color == indigo) return '黛蓝';
    if (color == gardenia) return '栀子';
    if (color == twilightPurple) return '暮山紫';
    if (color == darkBlack) return '玄青';
    return '自定义';
  }
}

/// 应用主题扩展
/// 
/// 提供便捷的主题属性访问
extension AppThemeExtension on BuildContext {
  /// 当前主题
  ThemeData get theme => Theme.of(this);
  
  /// 主色调
  Color get primaryColor => theme.colorScheme.primary;
  
  /// 背景色
  Color get backgroundColor => theme.scaffoldBackgroundColor;
  
  /// 卡片背景色
  Color get cardColor => theme.cardColor;
  
  /// 分割线颜色
  Color get dividerColor => theme.dividerColor;
  
  /// 主要文字颜色
  Color get textPrimaryColor => theme.textTheme.bodyLarge?.color ?? Colors.black;
  
  /// 次要文字颜色
  Color get textSecondaryColor => theme.textTheme.bodyMedium?.color ?? Colors.grey;
  
  /// 错误色
  Color get errorColor => theme.colorScheme.error;
  
  /// 是否为深色模式（注意：GetX 也提供了 isDarkMode，使用时注意命名空间）
  bool get isAppDarkMode => theme.brightness == Brightness.dark;
}

/// 应用主题管理类
class AppTheme {
  /// 获取主题数据
  /// 
  /// [primaryColor] 主色调
  /// [isDarkMode] 是否为深色模式
  /// [fontFamily] 字体（null 表示使用系统默认）
  static ThemeData getThemeData({
    required Color primaryColor,
    required bool isDarkMode,
    String? fontFamily,
  }) {
    return isDarkMode 
        ? _getDarkTheme(primaryColor, fontFamily)
        : _getLightTheme(primaryColor, fontFamily);
  }
  
  /// 浅色主题
  static ThemeData _getLightTheme(Color primaryColor, String? fontFamily) {
    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      secondary: primaryColor.withValues(alpha: 0.8),
      surface: Colors.white,
      background: const Color(0xFFF7F7F7),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1A1A1A),
      onBackground: const Color(0xFF1A1A1A),
      error: const Color(0xFFE53935),
      onError: Colors.white,
    );
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      cardColor: Colors.white,
      fontFamily: fontFamily,
      
      // AppBar 主题
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
          fontFamily: fontFamily,
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF1A1A1A),
        ),
      ),
      
      // 卡片主题
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // 列表瓦片主题
      listTileTheme: ListTileThemeData(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: Colors.grey.withValues(alpha: 0.2),
        thickness: 0.5,
        space: 1,
      ),
      
      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // 输入框装饰主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      
      // 文本主题
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: fontFamily, color: const Color(0xFF1A1A1A)),
        displayMedium: TextStyle(fontFamily: fontFamily, color: const Color(0xFF1A1A1A)),
        displaySmall: TextStyle(fontFamily: fontFamily, color: const Color(0xFF1A1A1A)),
        headlineLarge: TextStyle(fontFamily: fontFamily, color: const Color(0xFF1A1A1A)),
        headlineMedium: TextStyle(fontFamily: fontFamily, color: const Color(0xFF1A1A1A)),
        headlineSmall: TextStyle(fontFamily: fontFamily, color: const Color(0xFF1A1A1A)),
        titleLarge: TextStyle(fontFamily: fontFamily, color: const Color(0xFF1A1A1A)),
        titleMedium: TextStyle(fontFamily: fontFamily, color: const Color(0xFF1A1A1A)),
        titleSmall: TextStyle(fontFamily: fontFamily, color: const Color(0xFF666666)),
        bodyLarge: TextStyle(fontFamily: fontFamily, color: const Color(0xFF1A1A1A)),
        bodyMedium: TextStyle(fontFamily: fontFamily, color: const Color(0xFF666666)),
        bodySmall: TextStyle(fontFamily: fontFamily, color: const Color(0xFF999999)),
        labelLarge: TextStyle(fontFamily: fontFamily, color: const Color(0xFF1A1A1A)),
        labelMedium: TextStyle(fontFamily: fontFamily, color: const Color(0xFF666666)),
        labelSmall: TextStyle(fontFamily: fontFamily, color: const Color(0xFF999999)),
      ),
      
      // 对话框主题
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // 底部弹窗主题
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      
      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withValues(alpha: 0.3);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      
      // 滑块主题
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.1),
      ),
      
      // 浮动按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  /// 深色主题
  static ThemeData _getDarkTheme(Color primaryColor, String? fontFamily) {
    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor.withValues(alpha: 0.8),
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      error: const Color(0xFFEF5350),
      onError: Colors.white,
    );
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      fontFamily: fontFamily,
      
      // AppBar 主题
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: fontFamily,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      
      // 卡片主题
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // 列表瓦片主题
      listTileTheme: ListTileThemeData(
        tileColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // 分割线主题
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 0.5,
        space: 1,
      ),
      
      // 底部导航栏主题
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // 输入框装饰主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      
      // 文本主题
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: fontFamily, color: Colors.white),
        displayMedium: TextStyle(fontFamily: fontFamily, color: Colors.white),
        displaySmall: TextStyle(fontFamily: fontFamily, color: Colors.white),
        headlineLarge: TextStyle(fontFamily: fontFamily, color: Colors.white),
        headlineMedium: TextStyle(fontFamily: fontFamily, color: Colors.white),
        headlineSmall: TextStyle(fontFamily: fontFamily, color: Colors.white),
        titleLarge: TextStyle(fontFamily: fontFamily, color: Colors.white),
        titleMedium: TextStyle(fontFamily: fontFamily, color: Colors.white),
        titleSmall: TextStyle(fontFamily: fontFamily, color: Colors.grey),
        bodyLarge: TextStyle(fontFamily: fontFamily, color: Colors.white),
        bodyMedium: TextStyle(fontFamily: fontFamily, color: Colors.grey),
        bodySmall: TextStyle(fontFamily: fontFamily, color: Colors.grey),
        labelLarge: TextStyle(fontFamily: fontFamily, color: Colors.white),
        labelMedium: TextStyle(fontFamily: fontFamily, color: Colors.grey),
        labelSmall: TextStyle(fontFamily: fontFamily, color: Colors.grey),
      ),
      
      // 对话框主题
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // 底部弹窗主题
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      
      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withValues(alpha: 0.3);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      
      // 滑块主题
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.1),
      ),
      
      // 浮动按钮主题
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// 检查系统是否为深色模式
bool get isSystemDarkMode {
  final brightness = SchedulerBinding.instance.window.platformBrightness;
  return brightness == Brightness.dark;
}
