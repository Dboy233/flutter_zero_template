import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:{{package_name}}/core/di/injection.dart';
import 'package:{{package_name}}/core/effect/effect.dart';
import 'package:{{package_name}}/features/{{name}}/data/repositories/{{name}}_repository.dart';
import 'package:{{package_name}}/features/{{name}}/presentation/bloc/{{name}}_bloc.dart';
import 'package:{{package_name}}/features/{{name}}/presentation/{{name}}_effect_handle.dart';
import 'package:{{package_name}}/features/{{name}}/presentation/pages/{{name}}_body.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 页面。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} page.
class {{#pascalCase}}{{name}}{{/pascalCase}}Page extends StatelessWidget {
  /// 创建页面。
  ///
  /// Creates the page.
  const {{#pascalCase}}{{name}}{{/pascalCase}}Page({super.key, this.bloc});

  /// 仅用于测试注入的 BLoC。生产代码应始终使用 `getIt<{{#pascalCase}}{{name}}{{/pascalCase}}Repository>()` 创建。
  ///
  /// BLoC for **testing only**. Production code should always create the BLoC
  /// via `getIt<{{#pascalCase}}{{name}}{{/pascalCase}}Repository>()`.
  final {{#pascalCase}}{{name}}{{/pascalCase}}Bloc? bloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        // 优先使用测试注入的 BLoC；否则新建。
        // Prefer the test-injected BLoC; otherwise create a new one.
        return bloc ??
            {{#pascalCase}}{{name}}{{/pascalCase}}Bloc(
              repository: getIt<{{#pascalCase}}{{name}}{{/pascalCase}}Repository>(),
            );
      },
      child: const EffectListener<{{#pascalCase}}{{name}}{{/pascalCase}}Bloc, {{#pascalCase}}{{name}}{{/pascalCase}}State>(
        effectsHandles: [
          {{#camelCase}}{{name}}{{/camelCase}}EffectHandle,
        ],
        child: {{#pascalCase}}{{name}}{{/pascalCase}}Body(),
      ),
    );
  }
}
