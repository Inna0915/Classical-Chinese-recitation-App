import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/poem_new.dart';
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
      // 同步到控制器
      final controller = Get.find<PoemController>();
      controller.selectPoem(_poem!);
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
