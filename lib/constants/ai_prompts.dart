import 'dart:convert';

/// AI 提示词常量
/// 
/// 用于查询古诗词内容的提示词模板
class AIPrompts {
  /// 古诗词查询提示词 - JSON 格式输出
  /// 
  /// 让 LLM 返回包含 clean_content 和 annotated_content 的结构化数据
  static const String poemQuerySystemPrompt = r'''
# Role
你是一个专业的古诗词助手，专门为 API 提供结构化数据。

# Task
用户会提供古诗词的作品名称（如：静夜思），你需要查询并返回严格的 **JSON 格式**数据。

# Output Format (Strict JSON)
请严格按照以下 JSON 结构返回，不要包含 Markdown 代码块标记（```json），只返回纯文本 JSON：

{
  "title": "诗词标题",
  "author": "作者 及其朝代",
  "clean_content": "第一句原文\n第二句原文\n...",
  "annotated_content": "第一句原文\n(shēng pì zì zhù yīn)\n【释义】这句诗的现代汉语解释\n\n第二句原文\n..."
}

# Content Rules
1. **clean_content (纯净版):** - 仅包含古诗原文。
   - 每一句占一行。
   - 不含任何拼音、注释或多余符号。
   - **这是用于 TTS 语音合成的，必须准确、纯净。**

2. **annotated_content (释义版):**
   - 这是一个富文本版本，用于帮助用户学习。
   - 结构建议：原文一句一行，紧接着下方是该句的【释义】或生僻字【注音】。
   - 排版要清晰，适合手机竖屏阅读。

# Example (Target Output)
{
  "title": "咏鹅",
  "author": "骆宾王 [唐]",
  "clean_content": "鹅，鹅，鹅，曲项向天歌。\n白毛浮绿水，红掌拨清波。",
  "annotated_content": "鹅，鹅，鹅，曲项向天歌。\n【释义】鹅呀鹅，弯曲着脖子向天欢叫。\n\n白毛浮绿水，红掌拨清波。\n【释义】洁白的羽毛漂浮在碧绿的水面上，红红的脚掌拨动着清清的水波。"
}

# Important Notes
- 必须返回纯 JSON 文本，不要添加 Markdown 代码块标记（```json）。
- 如果查询不到该作品，请返回 {"error": "未找到该诗词"}。
- 确保 JSON 格式合法，所有字符串正确转义。
''';

  /// 用户提示词模板
  static String poemQueryUserPrompt(String poemName) {
    return '请查询诗词 "$poemName" 的原文和释义，返回 JSON 格式数据。';
  }

  /// 解析 AI 返回的 JSON 内容
  /// 
  /// 返回 Map 包含：title, author, content, cleanContent, annotatedContent
  static Map<String, String> parsePoemResponse(String response) {
    final result = <String, String>{
      'title': '',
      'author': '',
      'content': '',
      'cleanContent': '',
      'annotatedContent': '',
    };

    try {
      // 尝试解析 JSON
      String jsonStr = response.trim();
      
      // 去除可能的 Markdown 代码块标记
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
        if (jsonStr.endsWith('```')) {
          jsonStr = jsonStr.substring(0, jsonStr.length - 3);
        }
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
        if (jsonStr.endsWith('```')) {
          jsonStr = jsonStr.substring(0, jsonStr.length - 3);
        }
      }
      
      jsonStr = jsonStr.trim();
      
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // 提取字段
      result['title'] = data['title']?.toString() ?? '';
      result['author'] = data['author']?.toString() ?? '';
      result['cleanContent'] = data['clean_content']?.toString() ?? '';
      result['annotatedContent'] = data['annotated_content']?.toString() ?? '';
      
      // content 字段兼容旧逻辑，使用 clean_content
      result['content'] = result['cleanContent']!;
      
    } catch (e) {
      // JSON 解析失败，回退到旧格式解析
      print('JSON 解析失败，尝试旧格式: $e');
      return _parseLegacyFormat(response);
    }

    return result;
  }
  
  /// 旧格式解析（兼容）
  static Map<String, String> _parseLegacyFormat(String response) {
    final result = <String, String>{
      'title': '',
      'author': '',
      'content': '',
      'cleanContent': '',
      'annotatedContent': '',
    };

    final lines = response.split('\n');
    final contentBuffer = StringBuffer();
    final cleanContentBuffer = StringBuffer();
    final annotatedBuffer = StringBuffer();
    bool inBodySection = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // 检测标题
      if (line.startsWith('标题') && line.contains('：')) {
        result['title'] = line.split('：')[1].trim();
        continue;
      }
      
      // 检测作者
      if (line.startsWith('作者') && line.contains('：')) {
        result['author'] = line.split('：')[1].trim();
        continue;
      }
      
      // 检测正文与释义章节开始
      if (line.contains('正文') && line.contains('释义')) {
        inBodySection = true;
        continue;
      }
      
      // 在正文章节内解析
      if (inBodySection) {
        // 如果是释义行
        if (line.startsWith('释义：') || line.startsWith('释义:')) {
          final explanation = line.substring(line.indexOf('：') + 1).trim();
          
          if (annotatedBuffer.isNotEmpty) {
            annotatedBuffer.write('\n');
          }
          annotatedBuffer.write('【释义】$explanation');
        } else if (line.startsWith('释义')) {
          // 兼容没有冒号的情况
          final explanation = line.substring(2).trim();
          
          if (annotatedBuffer.isNotEmpty) {
            annotatedBuffer.write('\n');
          }
          annotatedBuffer.write('【释义】$explanation');
        } else {
          // 这是原文行（带拼音）
          if (contentBuffer.isNotEmpty) {
            contentBuffer.write('\n');
          }
          contentBuffer.write(line);
          
          // 清理拼音，提取 cleanContent
          final cleanLine = _removePinyin(line);
          if (cleanContentBuffer.isNotEmpty) {
            cleanContentBuffer.write('\n');
          }
          cleanContentBuffer.write(cleanLine);
          
          // 添加到释义版
          if (annotatedBuffer.isNotEmpty) {
            annotatedBuffer.write('\n\n');
          }
          annotatedBuffer.write(cleanLine);
        }
      }
    }

    result['content'] = contentBuffer.toString();
    result['cleanContent'] = cleanContentBuffer.toString();
    result['annotatedContent'] = annotatedBuffer.toString();

    return result;
  }
  
  /// 移除拼音标注，返回纯净文本
  /// 格式：字(拼音) -> 字
  static String _removePinyin(String text) {
    // 匹配中文字符后跟 (拼音) 的模式
    final pinyinPattern = RegExp(r'([\u4e00-\u9fa5])\([^)]+\)');
    return text.replaceAllMapped(pinyinPattern, (match) => match.group(1)!);
  }
}
