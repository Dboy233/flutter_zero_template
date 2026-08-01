import 'package:flutter/material.dart';
import 'package:flutter_zero_app/core/localization/context_l10n.dart';

import '../../di/get_it_instance.dart';
import '../../error/app_error_codes.dart';
import '../../notifiers/toast_service.dart';
import '../ui_effect.dart';

/// 框架默认 Toast 处理器：将 [ToastEffect] 委托给注入的 [ToastService]。
///
/// 由 [EffectListener] 自动追加到责任链链尾作为兜底。业务自定义 handle
/// 若在前置位置认领了 [ToastEffect] 并返回 `true`，本处理器不会执行——
/// 二者互不影响，替换底层 toast 实现只需在 DI 中切换 [ToastService]。
///
/// 处理优先级：
/// 1. [ToastEffect.message] — 直接展示服务端/固定文本；
/// 2. [ToastEffect.code] — 按常见 HTTP / 内部错误码映射为兜底文案；
/// 3. [ToastEffect.l10nCode] — 默认不处理，可以通过 `fluzer gen-l10n` 生成辅助函数。
///
/// Default framework toast handler: delegates [ToastEffect] to the injected
/// [ToastService]. Appended automatically by [EffectListener] at the chain
/// tail as a fallback. A business-defined handle placed earlier that claims
/// [ToastEffect] and returns `true` prevents this handler from running.
///
/// Resolution priority:
/// 1. [ToastEffect.message] — displayed directly;
/// 2. [ToastEffect.code] — mapped to a fallback text by common HTTP / internal
///    error code;
/// 3. [ToastEffect.l10nCode] — By default, it is not handled;
///    you can generate auxiliary functions using 'fluzer gen-l10n'.
///
bool defaultToastHandle(BuildContext context, UIEffect effect) {
  if (effect is! ToastEffect) return false;

  final svc = getIt<ToastService>();
  if (effect.message != null) {
    svc.showInfo(effect.message!);
  } else if (effect.code != null) {
    svc.showError(_handleErrorCode(context, effect.code!));
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
  }
  return true;
}

/// 把错误码翻译为面向用户的文本。
///
/// 涵盖应用内部错误码与常见 HTTP 4xx/5xx 状态码；未列出的码走兜底文案。
///
/// Translates an error code into user-facing text.
///
/// Covers internal error codes and common HTTP 4xx/5xx status codes;
/// unlisted codes fall back to a generic message.
String _handleErrorCode(BuildContext context, int code) {
  final l = context.l;
  return switch (code) {
  // 应用内部错误码（负数命名空间，避免与 HTTP 码冲突）。
  // Internal error codes (negative namespace to avoid HTTP collisions).
    AppErrorCodes.unknown => l.unknownError,
    AppErrorCodes.parseFromJson => l.parseFromJsonError,
    AppErrorCodes.parseNullData => l.parseNullDataError,
    AppErrorCodes.parseWrongType => l.parseWrongTypeError,
    AppErrorCodes.noConnection => l.noConnection,

  // 4xx 客户端错误。
  // 4xx client errors.
    AppErrorCodes.badRequest => l.error400,
    AppErrorCodes.unauthorized => l.error401,
    AppErrorCodes.forbidden => l.error403,
    AppErrorCodes.notFound => l.error404,
    AppErrorCodes.methodNotAllowed => l.error405,
    AppErrorCodes.requestTimeout => l.requestTimeout,
    AppErrorCodes.conflict => l.error409,
    AppErrorCodes.gone => l.error410,
    AppErrorCodes.payloadTooLarge => l.error413,
    AppErrorCodes.unsupportedMediaType => l.error415,
    AppErrorCodes.unprocessableEntity => l.error422,
    AppErrorCodes.tooManyRequests => l.error429,

  // 5xx 服务端错误。
  // 5xx server errors.
    AppErrorCodes.internalServerError => l.error500,
    AppErrorCodes.notImplemented => l.error501,
    AppErrorCodes.badGateway => l.error502,
    AppErrorCodes.serviceUnavailable => l.error503,
    AppErrorCodes.gatewayTimeout => l.error504,

  // 兜底。
  // Fallback.
    _ => l.unknownErrorCode(code.toString()),
  };
}
