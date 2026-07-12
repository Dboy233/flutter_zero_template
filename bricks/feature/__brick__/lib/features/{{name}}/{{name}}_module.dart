import 'package:get_it/get_it.dart';

import 'package:{{package_name}}/core/network/dio_client.dart';
import 'package:{{package_name}}/features/{{name}}/data/repositories/{{name}}_repository.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 模块依赖注册。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} module dependency registration.
class {{#pascalCase}}{{name}}{{/pascalCase}}Module {
  {{#pascalCase}}{{name}}{{/pascalCase}}Module._();

  /// 注册模块依赖。
  ///
  /// Registers module dependencies.
  static void register(GetIt getIt) {
    getIt.registerLazySingleton<{{#pascalCase}}{{name}}{{/pascalCase}}Repository>(
      () {
        return {{#pascalCase}}{{name}}{{/pascalCase}}Repository(client: getIt<DioClient>());
      },
    );
  }
}
