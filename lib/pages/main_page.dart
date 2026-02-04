import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/poem_controller.dart';
import '../controllers/player_controller.dart';
import '../core/theme/app_theme.dart';
import '../services/update_service.dart';
import '../widgets/mini_player_widget.dart';
import 'bookshelf_page.dart';
import 'collections_page.dart';
import 'favorites_page_new.dart';
import 'settings_page.dart';

/// 主页面 - 带底部导航 (v2.0 新架构)
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    // 初始化 PlayerController
    Get.put(PlayerController());
    // Android 平台启动后延迟检查更新
    if (!kIsWeb && Platform.isAndroid) {
      _checkUpdateOnStartup();
    }
  }

  /// 启动时检查更新
  void _checkUpdateOnStartup() {
    // 等待页面渲染完成
    Future.delayed(const Duration(seconds: 3), () {
      // 静默检查更新
      UpdateService.to.checkUpdate(isManual: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = PoemController.to;

    return Obx(() => Scaffold(
          body: IndexedStack(
            index: controller.currentTabIndex.value,
            children: const [
              BookshelfPage(),      // 新书架页（标签+搜索）
              FavoritesPageNew(),   // 新收藏页
              CollectionsPage(),    // 小集页（原分组页）
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 迷你播放控制条（有播放任务时显示）
              const MiniPlayerWidget(),
              
              // 底部导航栏
              Container(
                decoration: BoxDecoration(
                  color: context.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
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
                        _buildNavItem(
                          index: 2,
                          icon: Icons.folder_special_outlined,
                          activeIcon: Icons.folder_special,
                          label: '小集',
                        ),
                        // 设置按钮
                        _buildSettingsButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? context.primaryColor.withAlpha(26)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? context.primaryColor
                    : context.textSecondaryColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? context.primaryColor
                      : context.textSecondaryColor,
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
  Widget _buildSettingsButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const SettingsPage()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_outlined,
              color: context.textSecondaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              '设置',
              style: TextStyle(
                color: context.textSecondaryColor,
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
