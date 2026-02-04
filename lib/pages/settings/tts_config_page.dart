import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/tts_voices.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tts_result.dart';
import '../../services/settings_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/dialogs/app_dialog.dart';
import '../../widgets/settings/index.dart';

/// TTS 配置页面 - 火山引擎语音合成详细配置
class TtsConfigPage extends StatefulWidget {
  const TtsConfigPage({super.key});

  @override
  State<TtsConfigPage> createState() => _TtsConfigPageState();
}

class _TtsConfigPageState extends State<TtsConfigPage> {
  final SettingsService settingsService = SettingsService.to;
  final TtsService ttsService = TtsService();
  
  final TextEditingController _appIdController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _clusterController = TextEditingController();
  
  bool _obscureToken = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // 加载 TTS 配置（如果 TtsService 有提供获取配置的方法）
    // 这里使用默认配置或从 SettingsService 加载
    _appIdController.text = '1557076786'; // 默认 AppID
    _tokenController.text = 'y_I-ra6xiDjJW1V8CBVOBjsPZMB9FEtm'; // 默认 Token
    _clusterController.text = 'volcano_tts'; // 默认 Cluster
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _tokenController.dispose();
    _clusterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'TTS 服务配置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              '保存',
              style: TextStyle(
                color: context.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            // 鉴权信息
            _buildAuthSection(),
            
            // 音色选择
            _buildVoiceSection(),
            
            // 参数调节
            _buildParamsSection(),
            
            // 测试连接
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testTts,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isTesting ? '测试中...' : '测试语音合成'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showDebugLogs,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('日志'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.cardColor,
                      foregroundColor: context.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: context.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 重置按钮
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: _showResetConfirm,
                child: const Text(
                  '恢复默认配置',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 鉴权信息
  Widget _buildAuthSection() {
    return SettingsSection(
      title: '火山引擎鉴权信息',
      children: [
        // AppID
        SettingsTile(
          title: 'App ID',
          subtitleWidget: TextField(
            controller: _appIdController,
            style: TextStyle(
              fontSize: 14,
              color: context.textPrimaryColor,
            ),
            decoration: InputDecoration(
              hintText: '请输入火山引擎 App ID',
              hintStyle: TextStyle(
                color: context.textSecondaryColor.withValues(alpha: 0.5),
                fontSize: 13,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
          trailing: SettingsTileTrailing.none,
        ),
        
        Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
        
        // Access Token
        SettingsTile(
          title: 'Access Token',
          subtitleWidget: TextField(
            controller: _tokenController,
            obscureText: _obscureToken,
            style: TextStyle(
              fontSize: 14,
              color: context.textPrimaryColor,
            ),
            decoration: InputDecoration(
              hintText: '请输入 Access Token',
              hintStyle: TextStyle(
                color: context.textSecondaryColor.withValues(alpha: 0.5),
                fontSize: 13,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureToken ? Icons.visibility_off : Icons.visibility,
                  color: context.textSecondaryColor.withValues(alpha: 0.6),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureToken = !_obscureToken;
                  });
                },
              ),
            ),
          ),
          trailing: SettingsTileTrailing.none,
        ),
        
        Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
        
        // Cluster
        SettingsTile(
          title: 'Cluster',
          subtitleWidget: TextField(
            controller: _clusterController,
            style: TextStyle(
              fontSize: 14,
              color: context.textPrimaryColor,
            ),
            decoration: InputDecoration(
              hintText: 'volcano_tts',
              hintStyle: TextStyle(
                color: context.textSecondaryColor.withValues(alpha: 0.5),
                fontSize: 13,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
          trailing: SettingsTileTrailing.none,
        ),
      ],
    );
  }

  /// 音色选择
  Widget _buildVoiceSection() {
    return Obx(() => SettingsSection(
      title: '音色选择',
      children: [
        SettingsTile(
          icon: Icons.record_voice_over,
          iconBackgroundColor: const Color(0xFFE3F2FD),
          iconColor: const Color(0xFF2196F3),
          title: '当前音色',
          subtitle: TtsVoices.getDisplayName(settingsService.voiceType.value),
          trailing: SettingsTileTrailing.arrow,
          onTap: () => _showVoiceSelector(),
        ),
      ],
    ));
  }

  /// 参数调节
  Widget _buildParamsSection() {
    return Obx(() => SettingsSection(
      title: '参数调节',
      children: [
        // 语速
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '语速',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${(settingsService.speechRate.value / 50 + 1).toStringAsFixed(1)}x',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: settingsService.speechRate.value.toDouble(),
                min: -50,
                max: 100,
                divisions: 30,
                label: settingsService.speechRate.value.toString(),
                activeColor: context.primaryColor,
                onChanged: (value) {
                  settingsService.saveSpeechRate(value.round());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('慢', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                  Text('标准', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                  Text('快', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                ],
              ),
            ],
          ),
        ),
        
        Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
        
        // 音量
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '音量增强',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    settingsService.loudnessRate.value > 0 
                        ? '+${settingsService.loudnessRate.value}' 
                        : '${settingsService.loudnessRate.value}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: settingsService.loudnessRate.value.toDouble(),
                min: -50,
                max: 100,
                divisions: 30,
                label: settingsService.loudnessRate.value.toString(),
                activeColor: context.primaryColor,
                onChanged: (value) {
                  settingsService.saveLoudnessRate(value.round());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('轻', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                  Text('标准', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                  Text('响', style: TextStyle(fontSize: 12, color: context.textSecondaryColor)),
                ],
              ),
            ],
          ),
        ),
      ],
    ));
  }

  /// 显示音色选择器
  void _showVoiceSelector() {
    // 分类音色
    const voice2List = TtsVoice2.voices;
    const voice1List = TtsVoice1.voices;
    
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动指示条
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 标题
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '选择音色',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimaryColor,
                  ),
                ),
              ),
              
              Divider(height: 1, color: context.dividerColor),
              
              // 音色列表
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Doubao 2.0 音色
                    _buildVoiceCategory('Doubao 2.0 (推荐)', voice2List),
                    
                    Divider(height: 1, color: context.dividerColor),
                    
                    // Doubao 1.0 音色
                    _buildVoiceCategory('Doubao 1.0', voice1List),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// 构建音色分类
  Widget _buildVoiceCategory(String title, List<TtsVoice> voices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
            ),
          ),
        ),
        ...voices.map((voice) => _buildVoiceTile(voice)),
      ],
    );
  }

  /// 构建音色项
  Widget _buildVoiceTile(TtsVoice voice) {
    final isSelected = settingsService.voiceType.value == voice.voiceType;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected 
              ? context.primaryColor.withValues(alpha: 0.1)
              : context.textSecondaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            voice.gender == 'male' ? Icons.male : Icons.female,
            color: isSelected 
                ? context.primaryColor
                : context.textSecondaryColor,
          ),
        ),
      ),
      title: Text(
        voice.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: context.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        voice.description,
        style: TextStyle(
          fontSize: 12,
          color: context.textSecondaryColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isSelected 
          ? Icon(Icons.check_circle, color: context.primaryColor)
          : null,
      onTap: () {
        settingsService.saveVoiceType(voice.voiceType);
        Get.back();
      },
    );
  }

  /// 测试 TTS - 仅测试连接，不触发保存，显示结果弹窗
  Future<void> _testTts() async {
    setState(() {
      _isTesting = true;
    });

    try {
      // 仅同步配置到服务，不保存到设置
      ttsService.setVoiceType(settingsService.voiceType.value);
      
      // 仅测试连接，不合成完整文本
      final result = await ttsService.testConnection();
      
      // 显示结果弹窗
      _showTestResultDialog(result);
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }
  
  /// 显示测试结果弹窗
  void _showTestResultDialog(ConnectionResult result) {
    Get.dialog(
      AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Column(
            children: [
              Icon(
                result.isSuccess ? Icons.check_circle : Icons.error,
                color: result.isSuccess ? Colors.green : Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                result.isSuccess ? '测试成功' : '测试失败',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
        content: Text(
          result.isSuccess 
              ? '语音合成服务连接正常'
              : (result.errorMessage ?? '连接失败'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: context.textSecondaryColor,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              '关闭',
              style: TextStyle(color: context.textSecondaryColor),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              _showDebugLogs();
            },
            icon: const Icon(Icons.bug_report, size: 18),
            label: const Text('查看日志'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 显示调试日志
  void _showDebugLogs() {
    final logs = ttsService.debugLogs;
    
    Get.bottomSheet(
      Container(
        height: Get.height * 0.85, // 接近全屏高度
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 拖动条
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '调试日志',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            ttsService.clearDebugLogs();
                            setState(() {});
                          },
                          child: const Text('清空'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              // 日志列表 - 使用 Expanded 避免 overflow
              Expanded(
                child: Obx(() {
                  if (logs.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无日志',
                        style: TextStyle(color: context.textSecondaryColor),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogItem(log);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 构建日志项
  Widget _buildLogItem(TtsDebugLog log) {
    Color typeColor;
    IconData typeIcon;
    
    switch (log.type) {
      case 'error':
        typeColor = Colors.red;
        typeIcon = Icons.error_outline;
        break;
      case 'request':
        typeColor = Colors.blue;
        typeIcon = Icons.send;
        break;
      case 'response':
        typeColor = Colors.green;
        typeIcon = Icons.download_done;
        break;
      default:
        typeColor = context.textSecondaryColor;
        typeIcon = Icons.info_outline;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcon, size: 16, color: typeColor),
              const SizedBox(width: 8),
              Text(
                log.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: typeColor,
                ),
              ),
              const Spacer(),
              Text(
                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondaryColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if (log.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              log.content,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondaryColor,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    // 同步到 TtsService
    ttsService.setVoiceType(settingsService.voiceType.value);
    
    AppDialog.success(
      title: '保存成功',
      message: 'TTS 配置已更新',
    );
  }

  /// 显示重置确认
  void _showResetConfirm() {
    Get.dialog(
      AlertDialog(
        title: const Text('恢复默认配置'),
        content: const Text('确定要恢复默认的 TTS 配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              settingsService.resetTtsConfig();
              _loadSettings();
              Get.back();
              AppDialog.success(
                title: '已重置',
                message: 'TTS 配置已恢复为默认值',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}
