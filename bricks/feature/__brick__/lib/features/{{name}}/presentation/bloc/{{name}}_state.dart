part of '{{name}}_bloc.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 状态。
///
/// 实现 [EffectState]，用于承载由 [BlocEffectMixin] 写入的一次性 UI 副作用。
/// 项目默认提供 [ToastEffect]、[DialogEffect]、[NavigationEffect]；
/// 自定义 Effect 需同步修改 `lib/core/effect/ui_effect.dart`。
///
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} state.
///
/// Implements [EffectState] to hold one-time UI side effects written by
/// [BlocEffectMixin]. The project provides [ToastEffect], [DialogEffect],
/// and [NavigationEffect] by default. Custom effects must be added to
/// `lib/core/effect/ui_effect.dart`.
@freezed
abstract class {{#pascalCase}}{{name}}{{/pascalCase}}State extends EffectState with _${{#pascalCase}}{{name}}{{/pascalCase}}State {
  /// 初始状态。
  ///
  /// Initial state.
  const factory {{#pascalCase}}{{name}}{{/pascalCase}}State.initial({
    /// 待消费的 UI 副作用。
    ///
    /// Pending UI effect.
    UIEffect? effect,
  }) = _Initial;

  const {{#pascalCase}}{{name}}{{/pascalCase}}State._();

  @override
  {{#pascalCase}}{{name}}{{/pascalCase}}State copyWithEffect({UIEffect? effect}) {
    return copyWith(effect: effect);
  }
}
