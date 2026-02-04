import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import '../models/poem_new.dart';
import '../models/poem.dart' as old;
import '../services/poem_service.dart';
import '../controllers/poem_controller.dart';
import 'poem_detail_page.dart';

/// 诗词详情页 - 新架构适配器
/// 通过 poemId 加载并跳转到原有详情页
class PoemDetailPageNew extends StatefulWidget {
  final int poemId;

  const PoemDetailPageNew({super.key, required this.poemId});

  @override
  State<PoemDetailPageNew> createState() => _PoemDetailPageNewState();
}

class _PoemDetailPageNewState extends State<PoemDetailPageNew> {
  final PoemService _poemService = Get.find<PoemService>();
  bool _isLoading = true;
  Poem? _poem;

  @override
  void initState() {
    super.initState();
    _loadPoem();
  }

  Future<void> _loadPoem() async {
    _poem = await _poemService.getPoem(widget.poemId);
    setState(() => _isLoading = false);
    
    if (_poem != null) {
      // 同步到旧控制器以兼容原有详情页
      final oldController = Get.find<PoemController>();
      oldController.selectPoem(_poem!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_poem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('诗词不存在')),
        body: const Center(child: Text('该诗词已被删除')),
      );
    }

    // 跳转到原有详情页
    return const PoemDetailPage();
  }
}

/// 扩展 PoemController 以支持新模型
extension PoemControllerExtension on PoemController {
  void selectPoem(Poem poem) {
    // 转换新模型到旧模型格式
    currentPoem.value = PoemAdapter.toOldPoem(poem);
  }
}

/// 模型适配器 - 新模型转旧模型
class PoemAdapter {
  static old.Poem toOldPoem(Poem poem) {
    // 解析 author 字段 "李白 [唐]"
    final authorMatch = RegExp(r'(.+)\s*\[(.+?)\]').firstMatch(poem.author);
    final authorName = authorMatch?.group(1)?.trim() ?? poem.author;
    final dynasty = authorMatch?.group(2)?.trim();

    // 创建兼容旧控制器的 poem 对象
    return old.Poem(
      id: poem.id!,
      title: poem.title,
      author: authorName,
      dynasty: dynasty,
      content: poem.cleanContent,
      cleanContent: poem.cleanContent,
      annotatedContent: poem.annotatedContent,
      localAudioPath: poem.localAudioPath,
      createdAt: poem.createdAt,
      isFavorite: poem.isFavorite,
    );
  }
}
