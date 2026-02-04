import 'package:flutter/material.dart';

/// 播放模式枚举
enum PlayMode {
  sequence,   // 列表循环
  shuffle,    // 随机播放
  singleLoop  // 单曲循环
}

extension PlayModeExtension on PlayMode {
  String get displayName {
    switch (this) {
      case PlayMode.sequence:
        return '顺序播放';
      case PlayMode.shuffle:
        return '随机播放';
      case PlayMode.singleLoop:
        return '单曲循环';
    }
  }

  IconData get icon {
    switch (this) {
      case PlayMode.sequence:
        return Icons.repeat;
      case PlayMode.shuffle:
        return Icons.shuffle;
      case PlayMode.singleLoop:
        return Icons.repeat_one;
    }
  }

  /// 切换到下一种模式
  PlayMode get next {
    switch (this) {
      case PlayMode.sequence:
        return PlayMode.shuffle;
      case PlayMode.shuffle:
        return PlayMode.singleLoop;
      case PlayMode.singleLoop:
        return PlayMode.sequence;
    }
  }
}
