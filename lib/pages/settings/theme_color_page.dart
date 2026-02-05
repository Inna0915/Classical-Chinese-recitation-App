import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../data/theme_colors_data.dart';
import '../../data/theme_colors_db.dart';
import '../../services/settings_service.dart';
import '../../utils/color_utils.dart';

/// 主题颜色选择页 - 24节气传统色彩
/// 参考：郭浩《中国传统色：故宫里的色彩美学》
class ThemeColorPage extends StatefulWidget {
  const ThemeColorPage({super.key});

  @override
  State<ThemeColorPage> createState() => _ThemeColorPageState();
}

class _ThemeColorPageState extends State<ThemeColorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SettingsService _settingsService = SettingsService.to;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // 根据当前主题色定位到对应季节
    _initTabIndex();
  }

  void _initTabIndex() {
    final currentColor = _settingsService.primaryColor.value;
    // 查找当前颜色属于哪个季节
    for (int i = 0; i < allSeasons.length; i++) {
      for (final term in allSeasons[i].terms) {
        for (final color in term.colors) {
          if (color.color.value == currentColor.value) {
            _tabController.index = i;
            return;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentPrimaryColor = _settingsService.primaryColor.value;
      
      return Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: currentPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            '主题色 · 24节气',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Get.back(),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withAlpha(180),
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            tabs: allSeasons.map((season) => Tab(text: season.name)).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: allSeasons.map((season) {
            return _SeasonTab(
              season: season,
              currentPrimaryColor: currentPrimaryColor,
              onColorSelected: (color) {
                _settingsService.savePrimaryColor(color);
              },
            );
          }).toList(),
        ),
      );
    });
  }
}

/// 季节标签页
class _SeasonTab extends StatelessWidget {
  final SeasonData season;
  final Color currentPrimaryColor;
  final Function(Color) onColorSelected;

  const _SeasonTab({
    required this.season,
    required this.currentPrimaryColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: season.terms.length,
      itemBuilder: (context, index) {
        return _SolarTermCard(
          term: season.terms[index],
          currentPrimaryColor: currentPrimaryColor,
          onColorSelected: onColorSelected,
        );
      },
    );
  }
}

/// 节气卡片
class _SolarTermCard extends StatelessWidget {
  final SolarTerm term;
  final Color currentPrimaryColor;
  final Function(Color) onColorSelected;

  const _SolarTermCard({
    required this.term,
    required this.currentPrimaryColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 节气标题
            Row(
              children: [
                Text(
                  term.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 20,
                  color: context.dividerColor,
                ),
                const SizedBox(width: 8),
                Text(
                  term.pinyin,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSecondaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 颜色网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: term.colors.length,
              itemBuilder: (context, index) {
                final colorData = term.colors[index];
                final isSelected = colorData.color.value == currentPrimaryColor.value;
                
                return _ColorBlock(
                  colorData: colorData,
                  isSelected: isSelected,
                  onTap: () => onColorSelected(colorData.color),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 颜色块
class _ColorBlock extends StatelessWidget {
  final TraditionalColor colorData;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorBlock({
    required this.colorData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = getContrastingTextColor(colorData.color);
    final secondaryTextColor = textColor.withAlpha(204);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorData.color,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Colors.white,
                  width: 3,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorData.color.withAlpha(100),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 内容
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 颜色名
                  Text(
                    colorData.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Hex代码
                  Text(
                    colorData.hex,
                    style: TextStyle(
                      fontSize: 8,
                      color: secondaryTextColor,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // 选中标记
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: colorData.color,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
