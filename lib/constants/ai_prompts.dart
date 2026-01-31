/// AI 提示词常量
/// 
/// 用于查询古诗词内容的提示词模板
class AIPrompts {
  /// 古诗词查询提示词
  /// 
  /// 根据作品名称查询原文、释义、生僻字注音
  /// 格式：一行原文，一行注释，生僻字标注拼音在原文中
  static const String poemQuerySystemPrompt = r'''
你是一个专业的古诗词助手。

用户会提供古诗词的作品名称（如：静夜思、水调歌头等），你需要查询该作品并返回以下内容：

1. 标题和作者信息
2. 正文内容：每句原文占一行
3. 逐句释义：每句原文下面紧跟一行该句的解释
4. 生僻字注音：在原文中直接标注，格式为 字(拼音带声调)

输出格式要求：

标题：（诗词标题）
作者：（作者名，朝代）

正文与释义：
（第一句原文，生僻字标注拼音如：床前明月光，疑是地上霜。）
释义：（该句的现代汉语解释）

（第二句原文）
释义：（该句的现代汉语解释）

...以此类推

示例格式：
标题：静夜思
作者：李白，唐代

正文与释义：
床前明月光，疑是地上霜。
释义：明亮的月光洒在床前的窗户纸上，好像地上泛起了一层霜。

举头望明月，低头思故乡。
释义：我禁不住抬起头来，看那天窗外空中的一轮明月，不由得低头沉思，想起远方的家乡。

注意：
- 每句原文后必须紧跟一行释义
- 生僻字、多音字在原文中直接标注拼音，如：瑟(sè)、辗(zhǎn)、闱(wéi)
- 只返回上述格式内容，不要添加其他说明文字
- 如果查询不到该作品，请返回"未找到该诗词"
''';

  /// 用户提示词模板
  static String poemQueryUserPrompt(String poemName) {
    return '请查询诗词 "$poemName" 的原文、逐句释义和生僻字注音。';
  }

  /// 解析 AI 返回的内容
  /// 
  /// 返回 Map 包含：title, author, content, explanation
  static Map<String, String> parsePoemResponse(String response) {
    final result = <String, String>{
      'title': '',
      'author': '',
      'content': '',
      'explanation': '',
    };

    final lines = response.split('\n');
    final contentBuffer = StringBuffer();
    final explanationBuffer = StringBuffer();
    bool inBodySection = false;
    int lineCount = 0;

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
          if (explanationBuffer.isNotEmpty) {
            explanationBuffer.write('\n');
          }
          explanationBuffer.write(explanation);
        } else if (line.startsWith('释义')) {
          // 兼容没有冒号的情况
          final explanation = line.substring(2).trim();
          if (explanationBuffer.isNotEmpty) {
            explanationBuffer.write('\n');
          }
          explanationBuffer.write(explanation);
        } else {
          // 这是原文行
          if (contentBuffer.isNotEmpty) {
            contentBuffer.write('\n');
          }
          contentBuffer.write(line);
        }
      }
    }

    result['content'] = contentBuffer.toString();
    result['explanation'] = explanationBuffer.toString();

    return result;
  }
}
