import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:{{package_name}}/core/bloc/bloc.dart';
import 'package:{{package_name}}/core/effect/effect.dart';
import 'package:{{package_name}}/features/{{name}}/data/repositories/{{name}}_repository.dart';

part '{{name}}_event.dart';
part '{{name}}_state.dart';
part '{{name}}_bloc.freezed.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} BLoC。
///
/// 通过 [BlocEffectMixin.emitEffect] 发出一次性 UI 副作用。
/// 项目默认提供 [ToastEffect]、[DialogEffect]、[NavigationEffect]；
/// 如需自定义 Effect，请在 `lib/core/effect/ui_effect.dart` 中新增 `final class`
/// 并在页面层的 [EffectListener.onEffect] 中增加对应分支。
///
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} BLoC.
///
/// Emits one-time UI side effects via [BlocEffectMixin.emitEffect].
/// The project provides [ToastEffect], [DialogEffect], and [NavigationEffect]
/// out of the box. To add a custom effect, declare a new `final class` in
/// `lib/core/effect/ui_effect.dart` and handle it in the page's
/// [EffectListener.onEffect].
class {{#pascalCase}}{{name}}{{/pascalCase}}Bloc extends Bloc<{{#pascalCase}}{{name}}{{/pascalCase}}Event, {{#pascalCase}}{{name}}{{/pascalCase}}State>
    with
        BlocAwaitMixin<{{#pascalCase}}{{name}}{{/pascalCase}}Event, {{#pascalCase}}{{name}}{{/pascalCase}}State>,
        BlocEffectMixin<{{#pascalCase}}{{name}}{{/pascalCase}}State>,
        BlocCancelTokenMixin<{{#pascalCase}}{{name}}{{/pascalCase}}State> {
  /// 创建 BLoC。
  ///
  /// Creates the BLoC.
  {{#pascalCase}}{{name}}{{/pascalCase}}Bloc({
    required this.repository,
  }) : super(const {{#pascalCase}}{{name}}{{/pascalCase}}State.initial());

  /// {{#pascalCase}}{{name}}{{/pascalCase}} 仓库。
  ///
  /// {{#pascalCase}}{{name}}{{/pascalCase}} repository.
  final {{#pascalCase}}{{name}}{{/pascalCase}}Repository repository;

  // Future<void> _onAdd({{#pascalCase}}{{name}}{{/pascalCase}}Add event, Emitter<{{#pascalCase}}{{name}}{{/pascalCase}}State> emit) async {
  //   //<code>
  // }
}
