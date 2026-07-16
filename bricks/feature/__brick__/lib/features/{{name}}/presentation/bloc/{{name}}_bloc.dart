import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:{{package_name}}/core/bloc/bloc.dart';
import 'package:{{package_name}}/features/{{name}}/data/repositories/{{name}}_repository.dart';

part '{{name}}_event.dart';
part '{{name}}_state.dart';
part '{{name}}_bloc.freezed.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} BLoC。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} BLoC.
///
class {{#pascalCase}}{{name}}{{/pascalCase}}Bloc extends Bloc<{{#pascalCase}}{{name}}{{/pascalCase}}Event, {{#pascalCase}}{{name}}{{/pascalCase}}State>
    with
        BlocAwaitMixin<{{#pascalCase}}{{name}}{{/pascalCase}}Event, {{#pascalCase}}{{name}}{{/pascalCase}}State>,
        BlocEffectMixin<{{#pascalCase}}{{name}}{{/pascalCase}}State>,
        BlocCancelTokenMixin<{{#pascalCase}}{{name}}{{/pascalCase}}State>,
        BlocErrorHandlerMixin<{{#pascalCase}}{{name}}{{/pascalCase}}State>{
  /// 创建 BLoC。
  ///
  /// Creates the BLoC.
  {{#pascalCase}}{{name}}{{/pascalCase}}Bloc({
    required this.repository,
  }) : super(const {{#pascalCase}}{{name}}{{/pascalCase}}State());

  /// {{#pascalCase}}{{name}}{{/pascalCase}} 仓库。
  ///
  /// {{#pascalCase}}{{name}}{{/pascalCase}} repository.
  final {{#pascalCase}}{{name}}{{/pascalCase}}Repository repository;

  // Future<void> _onAdd({{#pascalCase}}{{name}}{{/pascalCase}}Add event, Emitter<{{#pascalCase}}{{name}}{{/pascalCase}}State> emit) async {
  //   //<code>
  // }
}
