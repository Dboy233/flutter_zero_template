import 'package:flutter/material.dart';
import 'package:{{package_name}}/core/di/get_it_instance.dart';
import 'package:{{package_name}}/core/effect/ui_effect.dart';
import 'package:{{package_name}}/core/notifiers/toast_service.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 模块的副作用处理器（责任链中的一个 handle）。
///
/// 返回 `true` 表示已处理（责任链命中即止），`false` 表示交给后续处理器。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} effect handler (one handle in the
/// responsibility chain).
///
/// Return `true` to signal "handled" (the chain stops on the first match),
/// `false` to let subsequent handlers run.
bool {{#camelCase}}{{name}}{{/camelCase}}EffectHandle(
  BuildContext context,
  UIEffect effect,
) {
  if (effect is ToastEffect && effect.messageCode != null) {
    getIt<ToastService>().showError(_mapMessageCode(effect.messageCode!));
    return true;
  }

  if (effect is DialogEffect) {
    return _handleDialog(context, effect.type, effect.extra);
  }
  // 不认领其它类型，交给框架默认 handle。
  // Do not claim other types; let the framework defaults run.
  return false;
}

/// 将 messageCode 映射为显示文本。
///
/// 脚手架占位实现直接返回 code；请在项目中替换为真实的 i18n 解析。
///
/// Maps a messageCode to display text.
///
/// The scaffold placeholder returns the code as-is; replace it with your
/// real i18n resolution in the project.
String _mapMessageCode(String code) {
  // TODO(fluzer): 替换为项目的 i18n 解析，例如 l10n.yourKey。
  return code;
}

/// 处理对话框副作用。
///
/// Handles dialog effects.
bool _handleDialog(BuildContext context, String type, Object? extra) {
  switch (type) {
    // 按业务类型添加弹窗处理。
    // Add dialog handling by business type.
    default:
      return false;
  }
}
