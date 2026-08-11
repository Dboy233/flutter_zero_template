import 'package:flutter/material.dart';
import 'package:flutter_zero_app/core/localization/context_l10n.dart';

import '../../di/get_it_instance.dart';
import '../../notifiers/toast_service.dart';
import '../ui_effect.dart';

/// 框架默认 Toast 处理器：将 [ToastEffect] 委托给注入的 [ToastService]。
///
/// 处理优先级：
/// 1. [ToastEffect.message] — 直接展示
/// 2. [ToastEffect.code] — 兜底："请求出错：{code}"
/// 3. [ToastEffect.l10nCode] — 按 l10n key 展示（由 `fluzer gen-l10n` 生成）
bool defaultToastHandle(BuildContext context, UIEffect effect) {
  if (effect is! ToastEffect) return false;

  final svc = getIt<ToastService>();
  final l = context.l;

  if (effect.message != null) {
    svc.showInfo(effect.message!);
  } else if (effect.l10nCode != null) {
    // 推荐执行 `fluzer gen-l10n` 自动生成辅助函数。
    // It is recommended to execute 'fluzer gen-l10n' to automatically generate
    // auxiliary functions.
    assert(() {
      debugPrint(
        'Unhandled ToastEffect.l10nCode: ${effect.l10nCode}. '
            'Add a business EffectHandle before defaultToastHandle to resolve it.',
      );
      return true;
    }(), 'l10nCode must be resolved by a business EffectHandle');

  } else if (effect.code != null) {
    svc.showError(l.unknownError(effect.code.toString()));
  } else {
    svc.showError(l.unknownError('Unknown'));
  }
  return true;
}