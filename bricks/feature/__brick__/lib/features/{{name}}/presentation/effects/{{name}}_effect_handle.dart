import 'package:flutter/material.dart';
import 'package:{{package_name}}/core/effect/ui_effect.dart';

/// {{#pascalCase}}{{name}}{{/pascalCase}} 模块的副作用处理器（责任链中的一个 handle）。
///
/// 返回 `true` 表示已处理（责任链命中即止），`false` 表示交给后续处理器。
///
/// {{#pascalCase}}{{name}}{{/pascalCase}} effect handler (one handle in the
/// responsibility chain).
///
/// Return `true` to signal "handled" (the chain stops on the first match),
/// `false` to let subsequent handlers run.
bool {{#camelCase}}{{name}}{{/camelCase}}EffectHandle(
  BuildContext context,
  UIEffect effect,
) {
  // 不认领，交给框架默认 handle。
  // Do not claim other types; let the framework defaults run.
  return false;
}
