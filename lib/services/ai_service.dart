import 'package:dio/dio.dart';
import '../constants/ai_models.dart';
import '../constants/ai_prompts.dart';
import 'settings_service.dart';

/// AI 服务结果
class AIResult {
  final bool isSuccess;
  final String? content;
  final Map<String, String>? poemData; // 解析后的诗词数据
  final String? errorMessage;

  AIResult({
    required this.isSuccess,
    this.content,
    this.poemData,
    this.errorMessage,
  });

  bool get isEmpty => content == null || content!.isEmpty;
}

/// AI 服务类
/// 
/// 封装大语言模型 API 调用
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final Dio _dio = Dio();

  /// 查询古诗词内容
  /// 
  /// [poemName] - 诗词作品名称（如：静夜思）
  Future<AIResult> queryPoem(String poemName) async {
    if (poemName.isEmpty) {
      return AIResult(
        isSuccess: false,
        errorMessage: '请输入诗词名称',
      );
    }

    final settings = SettingsService.to;
    // 使用自定义提示词（如果有），否则使用默认
    final systemPrompt = settings.customPrompt.value.isNotEmpty
        ? settings.customPrompt.value
        : AIPrompts.poemQuerySystemPrompt;

    final result = await _callAIAPI(
      systemPrompt: systemPrompt,
      userPrompt: AIPrompts.poemQueryUserPrompt(poemName),
    );

    if (!result.isSuccess) {
      return result;
    }

    // 解析返回的内容
    final poemData = AIPrompts.parsePoemResponse(result.content ?? '');
    
    return AIResult(
      isSuccess: true,
      content: result.content,
      poemData: poemData,
    );
  }

  /// 使用自定义提示词生成
  /// 
  /// [input] - 用户输入
  /// [customPrompt] - 自定义提示词（使用 {content} 作为占位符）
  Future<AIResult> generateWithCustomPrompt(String input, String customPrompt) async {
    final systemPrompt = customPrompt.contains('{content}')
        ? customPrompt.replaceAll('{content}', input)
        : '$customPrompt\n\n输入：$input';
    
    return await _callAIAPI(systemPrompt: systemPrompt, userPrompt: input);
  }

  /// 通用 AI 调用封装
  Future<AIResult> _callAIAPI({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final settings = SettingsService.to;
    
    // 检查配置
    if (!settings.hasAIConfig.value) {
      return AIResult(
        isSuccess: false,
        errorMessage: '请先配置 AI 模型 API',
      );
    }

    final providerKey = settings.aiProvider.value;
    final apiKey = settings.aiApiKey.value;
    final model = settings.aiModel.value;
    final apiUrl = settings.aiApiUrl.value;

    if (apiKey.isEmpty) {
      return AIResult(
        isSuccess: false,
        errorMessage: 'API Key 未设置',
      );
    }

    try {
      // 根据不同提供商调用 API
      switch (providerKey) {
        case 'kimi':
        case 'deepseek':
        case 'openai':
          return await _callOpenAICompatibleAPI(
            apiUrl: apiUrl,
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
          );
        case 'qwen':
          return await _callQwenAPI(
            apiUrl: apiUrl,
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
          );
        case 'gemini':
          return await _callGeminiAPI(
            apiUrl: apiUrl,
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
          );
        case 'custom':
          return await _callOpenAICompatibleAPI(
            apiUrl: apiUrl,
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
          );
        default:
          return AIResult(
            isSuccess: false,
            errorMessage: '不支持的模型提供商: $providerKey',
          );
      }
    } catch (e) {
      return AIResult(
        isSuccess: false,
        errorMessage: '调用失败: $e',
      );
    }
  }

  /// 调用 OpenAI 兼容格式 API (Kimi, DeepSeek, OpenAI)
  Future<AIResult> _callOpenAICompatibleAPI({
    required String apiUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    try {
      final response = await _dio.post(
        apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120), // 查询可能较慢
        ),
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.3, // 降低随机性，确保准确性
          'max_tokens': 4000,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices']?[0]?['message']?['content'];
        if (content != null) {
          return AIResult(
            isSuccess: true,
            content: content.toString(),
          );
        }
      }

      return AIResult(
        isSuccess: false,
        errorMessage: 'API 返回异常: ${response.statusCode}',
      );
    } on DioException catch (e) {
      return AIResult(
        isSuccess: false,
        errorMessage: '网络错误: ${e.message}',
      );
    } catch (e) {
      return AIResult(
        isSuccess: false,
        errorMessage: '解析错误: $e',
      );
    }
  }

  /// 调用通义千问 API
  Future<AIResult> _callQwenAPI({
    required String apiUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    try {
      final response = await _dio.post(
        apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
        data: {
          'model': model,
          'input': {
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
          },
          'parameters': {
            'temperature': 0.3,
            'max_tokens': 4000,
          },
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['output']?['text'] ?? 
                       response.data['choices']?[0]?['message']?['content'];
        if (content != null) {
          return AIResult(
            isSuccess: true,
            content: content.toString(),
          );
        }
      }

      return AIResult(
        isSuccess: false,
        errorMessage: 'API 返回异常: ${response.statusCode}',
      );
    } on DioException catch (e) {
      return AIResult(
        isSuccess: false,
        errorMessage: '网络错误: ${e.message}',
      );
    } catch (e) {
      return AIResult(
        isSuccess: false,
        errorMessage: '解析错误: $e',
      );
    }
  }

  /// 调用 Gemini API
  Future<AIResult> _callGeminiAPI({
    required String apiUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    try {
      final urlWithKey = '$apiUrl?key=$apiKey';
      
      final response = await _dio.post(
        urlWithKey,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': '$systemPrompt\n\n$userPrompt'},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 4000,
          },
        },
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content']?['parts']?[0]?['text'];
          if (content != null) {
            return AIResult(
              isSuccess: true,
              content: content.toString(),
            );
          }
        }
      }

      return AIResult(
        isSuccess: false,
        errorMessage: 'API 返回异常: ${response.statusCode}',
      );
    } on DioException catch (e) {
      return AIResult(
        isSuccess: false,
        errorMessage: '网络错误: ${e.message}',
      );
    } catch (e) {
      return AIResult(
        isSuccess: false,
        errorMessage: '解析错误: $e',
      );
    }
  }
}
