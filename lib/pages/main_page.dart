import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../controllers/poem_controller.dart';
import '../services/update_service.dart';
import 'poem_list_page.dart';
import 'favorites_page.dart';
import 'settings_page.dart';

/// 主页面 - 带底部导航
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    // Android 平台启动后延迟检查更新
    if (!kIsWeb && Platform.isAndroid) {
      _checkUpdateOnStartup();
    }
  }

  /// 启动时检查更新
  Future<void> _checkUpdateOnStartup() async {
    // 等待页面渲染完成
    await Future.delayed(const Duration(seconds: 2));
    
    // 检查是否应该自动检查（距离上次超过 24 小时）
    final shouldCheck = await UpdateService.shouldAutoCheck();
    if (!shouldCheck) return;
    
    // 静默检查更新
    final updateInfo = await UpdateService.checkUpdate();
    if (updateInfo != null && mounted) {
      // 发现更新，显示对话框
      UpdateService.showUpdateDialog(updateInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = PoemController.to;

    return Obx(() => Scaffold(
          body: IndexedStack(
            index: controller.currentTabIndex.value,
            children: const [
              PoemListPage(),
              FavoritesPage(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: const Color(UIConstants.cardColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.menu_book_outlined,
                      activeIcon: Icons.menu_book,
                      label: '书架',
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.favorite_outline,
                      activeIcon: Icons.favorite,
                      label: '收藏',
                    ),
                    // 设置按钮
                    _buildSettingsButton(),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final controller = PoemController.to;

    return Obx(() {
      final isActive = controller.currentTabIndex.value == index;
      return GestureDetector(
        onTap: () => controller.currentTabIndex.value = index,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(UIConstants.accentColor).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? const Color(UIConstants.accentColor)
                    : const Color(UIConstants.textSecondaryColor),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? const Color(UIConstants.accentColor)
                      : const Color(UIConstants.textSecondaryColor),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 设置按钮
  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () => Get.to(() => const SettingsPage()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_outlined,
              color: Color(UIConstants.textSecondaryColor),
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              '设置',
              style: TextStyle(
                color: Color(UIConstants.textSecondaryColor),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
