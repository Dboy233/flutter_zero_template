import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../effect/ui_effect.dart';

/// 为 BLoC 添加一次性 UI 副作用能力（基于独立 Stream）。
///
/// 项目默认提供 [ToastEffect]、[DialogEffect]、[LoadingEffect]（位于
/// `lib/core/effect/ui_effect.dart`）。由于 [UIEffect] 是开放基类，自定义
/// Effect 可在任意库中直接 `extends UIEffect` 新增类型，本 Mixin 无需修改。
///
/// 副作用通过 [effectStream] 发出，由 UI 层的 [EffectListener] 订阅消费，
/// **不污染**状态对象，也不存在单槽覆盖 / 重复投递问题。
///
/// 用法：
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with BlocEffectMixin<MyState> { ... }
/// ```
///
/// 触发副作用：
/// ```dart
/// emitEffect(const ToastEffect(l10nCode: 'homeLoadFailed'));
/// ```
///
/// 若不使用国际化，也可以直接传递固定文本：
/// ```dart
/// emitEffect(const ToastEffect(message: '加载失败'));
/// ```
///
///
/// Adds one-time UI side-effect support to a BLoC (via a dedicated Stream).
///
/// The project provides [ToastEffect], [DialogEffect], and [LoadingEffect]
/// (in `lib/core/effect/ui_effect.dart`). Because [UIEffect] is an open base
/// class, a custom effect can be added in any library simply by extending
/// [UIEffect]; this mixin does not need to be changed.
///
/// Effects are emitted through [effectStream] and consumed by the UI layer's
/// [EffectListener]. This keeps the state object clean and avoids single-slot
/// overwrites or duplicate deliveries.
///
/// Usage:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with BlocEffectMixin<MyState> { ... }
/// ```
///
/// Emit an effect:
/// ```dart
/// emitEffect(const ToastEffect(l10nCode: 'homeLoadFailed'));
/// ```
///
/// If the project does not use internationalization, fixed text can be passed
/// directly:
/// ```dart
/// emitEffect(const ToastEffect(message: 'Loading failed'));
/// ```
mixin BlocEffectMixin<S> on BlocBase<S> {
  final StreamController<UIEffect> _effectController =
      StreamController<UIEffect>.broadcast();

  /// 一次性 UI 副作用流。UI 层通过 [EffectListener] 订阅并消费。
  ///
  /// One-time UI effect stream. The UI layer subscribes and consumes it via
  /// [EffectListener].
  Stream<UIEffect> get effectStream => _effectController.stream;

  /// 触发一次性 UI 副作用。
  ///
  /// Emits a one-time UI side effect.
  void emitEffect(UIEffect effect) => _effectController.add(effect);

  @override
  Future<void> close() {
    unawaited(_effectController.close());
    return super.close();
  }
}
