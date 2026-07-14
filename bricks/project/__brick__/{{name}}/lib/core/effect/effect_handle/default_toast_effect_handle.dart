import 'package:flutter/material.dart';

import '../../di/get_it_instance.dart';
import '../../notifiers/toast_service.dart';
import '../ui_effect.dart';

/// 框架默认 Toast 处理器：将 [ToastEffect] 委托给注入的 [ToastService]。
///
/// 由 [EffectListener] 自动追加到责任链链尾作为兜底。业务自定义 handle
/// 若在前置位置认领了 [ToastEffect] 并返回 `true`，本处理器不会执行——
/// 二者互不影响，替换底层 toast 实现只需在 DI 中切换 [ToastService]。
///
/// Default framework toast handler: delegates [ToastEffect] to the injected
/// [ToastService]. Appended automatically by [EffectListener] at the chain
/// tail as a fallback. A business-defined handle placed earlier that claims
/// [ToastEffect] and returns `true` prevents this handler from running.
bool defaultToastHandle(BuildContext context, UIEffect effect) {
  if (effect is! ToastEffect) return false;

  final svc = getIt<ToastService>();
  if (effect.message != null) {
    svc.showInfo(effect.message!);
  } else if (effect.messageCode != null) {
    // 框架级兜底：无法直接解析 i18n 码，原样作为错误文案展示。
    // 业务应使用自定义 handle 完成 messageCode → 本地化文本的映射。
    // Framework fallback: cannot resolve the i18n code locally, so it is
    // shown verbatim as the error text. Business code should use a custom
    // handle to map messageCode → localized text.
    svc.showError(effect.messageCode!);
  }
  return true;
}
