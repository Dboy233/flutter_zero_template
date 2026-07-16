import 'dart:async';

import 'package:flutter/material.dart';

import '../ui_effect.dart';

/// 框架默认对话框处理器（兜底）：为任何未被业务 handle 认领的 [DialogEffect]
/// 渲染一个最小可用的通用对话框，避免副作用被静默丢弃。
///
/// 业务应使用自己的 handle（参考 [homeEffectHandle]）按 [DialogEffect.type]
/// 渲染真正符合产品需求的对话框；一旦业务 handle 认领并返回 `true`，
/// 本兜底处理器不会执行。
///
/// 默认对话框不显示任何文字按钮，只提供一个关闭图标按钮，确保框架层
/// 不写死任何 UI 文案。
///
/// Default framework dialog handler (fallback): renders a minimal generic
/// dialog for any [DialogEffect] not claimed by a business handle, so effects
/// are never silently dropped. Business code should render a real, product-
/// specific dialog via its own handler keyed on [DialogEffect.type].
///
/// The default dialog shows no text buttons; only a close icon button is
/// provided, keeping the framework layer free of hard-coded UI text.
bool defaultDialogHandle(BuildContext context, UIEffect effect) {
  if (effect is! DialogEffect) return false;

  unawaited(
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(effect.type),
        content: effect.extra == null ? null : Text(effect.extra.toString()),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(dialogContext).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    ),
  );
  return true;
}
