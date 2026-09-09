import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:{{package_name}}/core/bloc/bloc.dart';
import 'package:{{package_name}}/features/{{name}}/data/repositories/{{name}}_repository.dart';

part '{{name}}_cubit.freezed.dart';
part '{{name}}_state.dart';


/// {{#pascalCase}}{{name}}{{/pascalCase}} Cubit。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} Cubit.
///
class {{#pascalCase}}{{name}}{{/pascalCase}}Cubit extends Cubit<{{#pascalCase}}{{name}}{{/pascalCase}}State>
    with
        BlocEffectMixin<{{#pascalCase}}{{name}}{{/pascalCase}}State>,
        BlocCancelTokenMixin<{{#pascalCase}}{{name}}{{/pascalCase}}State>,
        BlocErrorHandlerMixin<{{#pascalCase}}{{name}}{{/pascalCase}}State> {
  /// 创建 Cubit。
  ///
  /// Creates the Cubit.
  new({
    required this.repository,
  }) : super(const {{#pascalCase}}{{name}}{{/pascalCase}}State());

  /// {{#pascalCase}}{{name}}{{/pascalCase}} 仓库。
  ///
  /// {{#pascalCase}}{{name}}{{/pascalCase}} repository.
  final {{#pascalCase}}{{name}}{{/pascalCase}}Repository repository;

}
