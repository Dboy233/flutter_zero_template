import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/app_exception.dart';
import '../error/error_handler.dart';
import '../result/result.dart';

export '../result/result.dart';

/// 为 BLoC 添加统一的错误处理能力。
///
/// 与 [BlocEffectMixin] / [BlocAwaitMixin] / [BlocCancelTokenMixin] 并列使用，
/// 让 BLoC 不再直接感知 Dio 等传输层异常。所有错误统一经 [ErrorHandler] 转换为
/// [AppException]；主动取消的请求被封装为 [Cancel]，不再和失败混为一谈。
///
/// 框架主推 [message] / [code] 兜底：
/// * 服务端已翻译的 message 直接展示；
/// * 无 message 时按 [AppException.code] 映射通用文案；
/// * 只有业务需要自定义文案时才使用 [ToastEffect.l10nCode]，
///   并需要业务层在 [EffectListener] 中提供对应的 handler。
///
/// ## 用法
///
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with BlocEffectMixin<MyState>, BlocErrorHandlerMixin<MyState> {
///   ...
///   Future<void> _onFetch(event, emit) async {
///     final result = await runToResult(() => repository.fetch());
///
///     result.when(
///       success: (data) => emit(...),
///       failure: (ex) => emitEffect(ex.toToastEffect()),
///       cancel: () {}, // 主动取消，通常无需处理
///     );
///   }
/// }
/// ```
///
/// 如果你更喜欢回调式写法，也可以继续使用 [runWithErrorHandling]：
///
/// ```dart
/// await runWithErrorHandling(
///   () => repository.fetch(),
///   onSuccess: (data) => emit(...),
///   onError: (ex) => emitEffect(ex.toToastEffect()),
/// );
/// ```
///
/// ## 自定义错误处理策略
///
/// 如果项目需要自定义服务端消息字段或认证码集合，覆盖 [errorHandler]：
///
/// ```dart
/// @override
/// ErrorHandler get errorHandler => ErrorHandler(
///   serverMessageExtractor: ServerMessageExtractor(['msg', 'errorMessage']),
/// );
/// ```
///
/// Adds unified error handling to a BLoC.
///
/// Use alongside [BlocEffectMixin], [BlocAwaitMixin], and [BlocCancelTokenMixin]
/// so the BLoC no longer touches transport-layer exceptions such as Dio.
/// All errors are normalized to [AppException] via [ErrorHandler], and
/// intentional cancellations are represented as [Cancel] instead of being
/// mixed with failures.
///
/// The framework prefers the [message] / [code] fallback:
/// * server-translated [message] is displayed directly;
/// * without a message, the generic text is mapped from [AppException.code];
/// * [ToastEffect.l10nCode] is used only when business-specific wording is
///   required, and must be resolved by a business handler in [EffectListener].
mixin BlocErrorHandlerMixin<S> on BlocBase<S> {
  /// 本 BLoC 使用的错误处理器。
  ///
  /// 子类可覆盖以注入自定义提取策略。
  ///
  /// The error handler used by this BLoC.
  ///
  /// Subclasses may override this to inject a custom extraction strategy.
  ErrorHandler get errorHandler => ErrorHandler();

  /// 将任意原始异常转换为 [AppException]。
  ///
  /// 当返回 `null` 时，表示这是主动取消的请求，应静默忽略。
  ///
  /// Converts any raw exception into an [AppException].
  ///
  /// Returns `null` for intentional cancellations, which should be silently
  /// ignored.
  AppException? handleError(Object error, [StackTrace? stackTrace]) =>
      errorHandler.handle(error, stackTrace);

  /// 当错误是主动取消时返回 `true`。
  ///
  /// Returns `true` when the error was an intentional cancellation.
  bool isCancelled(Object error) => errorHandler.isCancelled(error);

  /// 将执行 [action] 的结果封装为 [Result]。
  ///
  /// * 成功 → [Success]
  /// * 主动取消 → [Cancel]（不走 [Failure]）
  /// * 其它异常 → [Failure]，并经过 [ErrorHandler] 转换为 [AppException]
  ///
  /// 这是 BLoC 中处理异步操作的首选方式，可替代手写 try/catch。
  ///
  /// Wraps the execution of [action] in a [Result].
  ///
  /// * Success → [Success]
  /// * Intentional cancellation → [Cancel] (not [Failure])
  /// * Other exceptions → [Failure], converted to [AppException] via [ErrorHandler]
  ///
  /// This is the preferred way to handle async operations in a BLoC,
  /// replacing manual try/catch blocks.
  Future<Result<T>> runToResult<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on Object catch (e, stackTrace) {
      final ex = handleError(e, stackTrace);
      if (ex == null) return const Cancel();
      return Failure<T>(ex);
    }
  }

  /// 在执行 [action] 时统一捕获并处理异常。
  ///
  /// 如果 [action] 抛出异常且不是取消请求，则调用 [onError]；
  /// 如果执行成功且 [onSuccess] 不为空，则调用 [onSuccess]。
  /// 返回 [action] 的结果；出错或被取消时返回 `null`。
  ///
  /// Runs [action] with unified error handling.
  ///
  /// Calls [onError] when an error is thrown and is not a cancellation; calls
  /// [onSuccess] when [action] succeeds if provided. Returns the result of
  /// [action], or `null` on cancellation or error.
  Future<T?> runWithErrorHandling<T>(
    Future<T> Function() action, {
    required void Function(AppException) onError,
    void Function(T result)? onSuccess,
  }) async {
    try {
      final result = await action();
      onSuccess?.call(result);
      return result;
    } on Object catch (e) {
      if (isCancelled(e)) return null;
      final ex = handleError(e);
      if (ex != null) onError(ex);
      return null;
    }
  }
}
