import 'package:meta/meta.dart';

import '../error/app_exception.dart';

/// 一个统一的成功 / 失败 / 取消结果类型。
///
/// 用于把底层异步操作（网络请求、解析等）的三种终态显式化，
/// 避免 BLoC 中反复写 `try / catch / if-cancelled` 样板。
///
/// ## 用法
///
/// ```dart
/// final result = await runToResult(() => repository.login(...));
///
/// result.when(
///   success: (user) => emit(state.copyWith(user: user)),
///   failure: (ex) => emitEffect(ex.toToastEffect()),
///   cancel: () { /* 请求被主动取消，通常什么都不做 */ },
/// );
/// ```
///
/// A unified success / failure / cancellation result type.
///
/// Makes the three possible outcomes of a low-level async operation
/// (network request, parsing, etc.) explicit, so BLoCs do not need to
/// repeat `try / catch / if-cancelled` boilerplate.
sealed class Result<T> {
  const Result();
}

/// 操作成功，携带返回值。
///
/// Operation succeeded with a returned value.
@immutable
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// 操作失败，携带已转换为应用层异常的 [AppException]。
///
/// Operation failed with an exception already converted to [AppException].
@immutable
final class Failure<T> extends Result<T> {
  const Failure(this.exception);

  final AppException exception;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          exception == other.exception;

  @override
  int get hashCode => exception.hashCode;

  @override
  String toString() => 'Failure($exception)';
}

/// 操作被主动取消。
///
/// 多数业务不需要处理此分支，但 [Result.when] 要求显式处理，
/// 可以提醒开发者注意到取消语义。
///
/// Operation was intentionally cancelled.
///
/// Most business code does not need to handle this branch, but [Result.when]
/// requires it explicitly, which reminds developers that cancellation is a
/// first-class outcome.
@immutable
final class Cancel<T> extends Result<T> {
  const Cancel();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cancel<T> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Cancel()';
}

/// [Result] 的便捷扩展方法。
///
/// Convenience extensions for [Result].
extension ResultWhen<T> on Result<T> {
  /// 处理三种结果分支。
  ///
  /// Handles all three result branches.
  R? when<R>({
    required R Function(T value) success,
    required R Function(AppException ex) failure,
    R Function()? cancel,
  }) {
    switch (this) {
      case Success<T>(:final value):
        return success(value);
      case Failure<T>(:final exception):
        return failure(exception);
      case Cancel<T>():
        return cancel?.call();
    }
  }

  /// 仅处理成功分支，失败 / 取消返回 `null`。
  ///
  /// Returns the success value or `null` on failure / cancellation.
  T? get valueOrNull {
    return switch (this) {
      Success<T>(:final value) => value,
      Failure<T>() || Cancel<T>() => null,
    };
  }

  /// 是否是成功结果。
  ///
  /// Whether this result is a success.
  bool get isSuccess => this is Success<T>;

  /// 是否是失败结果。
  ///
  /// Whether this result is a failure.
  bool get isFailure => this is Failure<T>;

  /// 是否是取消结果。
  ///
  /// Whether this result is a cancellation.
  bool get isCancel => this is Cancel<T>;
}
