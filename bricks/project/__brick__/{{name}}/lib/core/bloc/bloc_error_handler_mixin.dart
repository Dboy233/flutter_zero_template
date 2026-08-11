import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../result/result.dart';

export '../result/result.dart';

/// 为 BLoC 添加 try-catch → [Result] 的错误包装能力。
///
/// 与 [BlocEffectMixin] / [BlocCancelTokenMixin] 并列使用。
///
/// ## 用法
///
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with BlocEffectMixin, BlocErrorHandlerMixin {
///   Future<void> _onFetch(event, emit) async {
///     final result = await runCatching(() => repository.fetch());
///     result.when(
///       success: (data) => emit(state.copyWith(items: data)),
///       failure: (ex) => emitEffect(ex.toToastEffect()),
///     );
///   }
/// }
/// ```
///
/// ## 自定义取消判断
///
/// 默认按 Dio 的 [DioExceptionType.cancel] 判断。使用其他 HTTP 客户端时覆盖 [isCancelled]。
mixin BlocErrorHandlerMixin<S> on BlocBase<S> {
  bool isCancelled(Object error) =>
      error is DioException && error.type == DioExceptionType.cancel;

  /// 将 [action] 的执行结果封装为 [Result]。
  ///
  /// * 成功 → [Success]
  /// * [Exception] → [Failure]
  /// * 主动取消 → [Cancel]
  /// * 其它异常 → [Failure]（无消息，走兜底文案）
  Future<Result<T>> runCatching<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on Object catch (e) {
      if (isCancelled(e)) return const Cancel();
      if(e is Exception){
        return Failure<T>(e);
      }
      return Failure(Exception('unknown exception'));
    }
  }
}
