import 'package:flutter/material.dart';

import '../../di/get_it_instance.dart';
import '../../notifiers/loading_service.dart';
import '../ui_effect.dart';

/// 框架默认 Loading 处理器：将 [LoadingEffect] 委托给注入的 [LoadingService]。
///
/// 由 [EffectListener] 自动追加到责任链链尾。业务层只需
/// `emitEffect(const LoadingEffect(show: true/false))` 即可控制全局 loading，
/// 无需关心具体实现框架；替换实现只需在 DI 中切换 [LoadingService]。
///
/// Default framework loading handler: delegates [LoadingEffect] to the
/// injected [LoadingService]. Appended automatically by [EffectListener] at
/// the chain tail. The business layer only emits
/// `emitEffect(const LoadingEffect(show: true/false))` to control global
/// loading without knowing the concrete framework.
bool defaultLoadingHandle(BuildContext context, UIEffect effect) {
  if (effect is! LoadingEffect) return false;

  final svc = getIt<LoadingService>();
  if (effect.show) {
    final Object? extra = effect.extra;
    final status = extra is String ? extra : null;
    svc.show(status: status);
  } else {
    svc.dismiss();
  }
  return true;
}
