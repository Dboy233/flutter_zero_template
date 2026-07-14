import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/bloc_effect_mixin.dart';
import 'effect_handle/default_dialog_effect_handle.dart';
import 'effect_handle/default_loading_effect_handle.dart';
import 'effect_handle/default_toast_effect_handle.dart';
import 'ui_effect.dart';

typedef EffectHandle = bool Function(BuildContext context, UIEffect effect);

class EffectListener<B extends BlocBase<S>, S> extends StatelessWidget {
  /// 创建副作用监听组件。
  ///
  /// Creates the effect-listening widget.
  const EffectListener({
    required this.child,
    this.effectsHandles = const [],
    super.key,
  });

  final List<EffectHandle> effectsHandles;

  /// 子组件。
  ///
  /// Child widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 业务处理器优先；框架级通用处理器作为兜底自动追加到链尾。
    // 第一个返回 true 的处理器胜出，命中即停止。
    // Business handlers run first; the framework-level generic handlers are
    // appended at the chain tail as fallbacks. The first handler returning
    // true wins.
    // 注意：不可对入参列表直接 add（调用方可能传入 const 列表），
    // 这里构造一份新的可变列表再下传。
    final handles = [
      ...effectsHandles,
      defaultToastHandle,
      defaultDialogHandle,
      defaultLoadingHandle,
    ];

    final bloc = context.read<B>();
    if (bloc is! BlocEffectMixin<S>) {
      throw StateError(
        '$B must use BlocEffectMixin<$S> to support effects. '
        'Add `with BlocEffectMixin<$S>` to your BLoC class.',
      );
    }
    return _EffectStreamListener<S>(
      bloc: bloc,
      effectsHandles: handles,
      child: child,
    );
  }
}

class _EffectStreamListener<S> extends StatefulWidget {
  const _EffectStreamListener({
    required this.bloc,
    required this.effectsHandles,
    required this.child,
  });

  final BlocEffectMixin<S> bloc;
  final List<EffectHandle> effectsHandles;
  final Widget child;

  @override
  State<_EffectStreamListener<S>> createState() =>
      _EffectStreamListenerState<S>();
}

class _EffectStreamListenerState<S> extends State<_EffectStreamListener<S>> {
  late final StreamSubscription<UIEffect> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.bloc.effectStream.listen(_onEffect);
  }

  void _onEffect(UIEffect effect) {
    for (final handle in widget.effectsHandles) {
      if (handle.call(context, effect)) {
        return;
      }
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
