import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:{{package_name}}/core/di/injection.dart';
import 'package:{{package_name}}/core/effect/effect.dart';
import 'package:{{package_name}}/features/{{name}}/data/repositories/{{name}}_repository.dart';
import 'package:{{package_name}}/features/{{name}}/presentation/cubit/{{name}}_cubit.dart';
import 'package:{{package_name}}/features/{{name}}/presentation/effects/{{name}}_effect_handle.dart';

part '{{name}}_body.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 页面。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} page.
class {{#pascalCase}}{{name}}{{/pascalCase}}Page extends StatelessWidget {
  /// 创建页面。
  ///
  /// Creates the page.
  const new({super.key, this.cubit});

  /// 仅用于测试注入的 Cubit。生产代码应始终使用 `getIt<{{#pascalCase}}{{name}}{{/pascalCase}}Repository>()` 创建。
  ///
  /// Cubit for **testing only**. Production code should always create the Cubit
  /// via `getIt<{{#pascalCase}}{{name}}{{/pascalCase}}Repository>()`.
  final {{#pascalCase}}{{name}}{{/pascalCase}}Cubit? cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        // 优先使用测试注入的 Cubit；否则新建。
        // Prefer the test-injected Cubit; otherwise create a new one.
        return cubit ??
            {{#pascalCase}}{{name}}{{/pascalCase}}Cubit(
              repository: getIt<{{#pascalCase}}{{name}}{{/pascalCase}}Repository>(),
            );
      },
      child: const EffectListener<{{#pascalCase}}{{name}}{{/pascalCase}}Cubit, {{#pascalCase}}{{name}}{{/pascalCase}}State>(
        effectsHandles: [
          {{#camelCase}}{{name}}{{/camelCase}}EffectHandle,
        ],
        child: _{{#pascalCase}}{{name}}{{/pascalCase}}Body(),
      ),
    );
  }
}
