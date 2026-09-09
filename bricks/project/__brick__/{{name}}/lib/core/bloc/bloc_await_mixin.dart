import 'dart:async';

import 'package:bloc/bloc.dart';

/// `runAwait` 的可等待返回结果（Result / Outcome 对象 / sum type）。
///
/// 调用端用 `switch` / `is` 判别结局，不靠异常——这是 MVI 中接近 MVVM
/// `Future<Result<T>>` 手感的关键。
///
/// ⚠️ 命名语义澄清（避免与"业务成败"混淆）：
/// - [AwaitCompleted]：**handler 执行层**成功——handler 跑完且未抛异常。
///   它**不代表业务逻辑成功**；业务失败但没抛错（如 `emit(FailureState())`）
///   仍会得到 [AwaitCompleted]，业务成败请通过 `AwaitCompleted.value`（即 state）自行判断。
/// - [AwaitErrored]：**handler 执行层**失败——handler 抛异常，或派发前 `add()`
///   就失败（如未注册 handler / bloc 已关闭）。
/// - [AwaitDropped]：调度层——事件被 transformer 丢弃（droppable 丢弃 /
///   restartable 顶替），handler 根本没执行。
/// - [AwaitCancelled]：生命周期——bloc 关闭导致等待被废弃。
/// 即：这四种是"await 如何了结"的生命周期结局，**不是业务操作成败**。
sealed class AwaitResolution<T> {
  const new();

  /// 是否 handler 执行层成功完成（跑完且未抛异常）。
  /// 注意：不代表业务逻辑成功，仅表示 await 正常了结且携带了 state。
  bool get isCompleted => this is AwaitCompleted<T>;

  /// 便捷取值：当本次 await 以 [AwaitCompleted] 了结时返回携带的值；
  /// 其余三种结局（[AwaitErrored] / [AwaitDropped] / [AwaitCancelled]）不持有值，
  /// 返回 `null`。
  ///
  /// 这是基类上的**可空便捷入口**——无需先收窄即可安全调用，不会抛异常，
  /// 但返回类型是 `T?`，调用方需自行判空。若你已通过 `switch` / `is` /
  /// `case AwaitCompleted(:final value)` 收窄到 [AwaitCompleted]，应优先用
  /// [AwaitCompleted.value]（非可空 `T`，类型更精确、零判空）。
  ///
  /// 与 [AwaitCompleted.value] 的区别：
  /// - [AwaitCompleted.value]：字段，仅在已收窄到 [AwaitCompleted] 后可用，
  ///   类型是 `T`（非可空），编译期保证有值。
  /// - [completedValue]：基类 getter，任何 [AwaitResolution] 都能调，
  ///   类型是 `T?`，未 completed 时为 `null`。
  T? get completedValue {
    if (isCompleted) {
      return (this as AwaitCompleted<T>).value;
    } else {
      return null;
    }
  }
}

final class AwaitCompleted<T> extends AwaitResolution<T> {
  const new(this.value);

  /// 本次 await 携带的值（即 handler emit 出的 state，或当前 state）。
  /// 仅 [AwaitCompleted] 持有；其余三种结局不持有 value，调用方须先收窄到
  /// [AwaitCompleted]（switch / `is` / `case AwaitCompleted(:final value)`）再访问，
  /// 否则编译期即报错，而非运行时抛错。
  final T value;

  @override
  String toString() => 'AwaitCompleted($value)';
}

final class AwaitErrored<T> extends AwaitResolution<T> {
  const new(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AwaitErrored($error)';
}

final class AwaitCancelled<T> extends AwaitResolution<T> {
  const new();

  @override
  String toString() => 'AwaitCancelled()';
}

/// 被 transformer 处理掉：droppable 丢弃、restartable 顶替等"被 transformer
/// 吃掉"的情形。这是 `onTransition` / `onDone` 看不见、必须由 transformer 回调
/// 才能精确判定的结局。
final class AwaitDropped<T> extends AwaitResolution<T> {
  const new();

  @override
  String toString() => 'AwaitDropped()';
}

/// AwaitTransformer 的回调钩子（透明转发的契约）。
///
/// 实现自己的 transformer 时必须遵守契约：在事件被丢弃时调用 [onDropped]，
/// 在被顶替时调用 [onSuperseded]。`BlocAwaitMixin` 本身实现此钩子。
mixin AwaitTransformerHook {
  /// 事件被当前策略丢弃（droppable 的新事件 / 自定义策略丢弃）。
  void onDropped(Object event) {}

  /// 事件顶替了 in-flight 的另一个事件（restartable 策略）。
  void onSuperseded(Object event) {}
}

/// 自定义 transformer 的抽象工厂（Strategy + Factory Method）。
///
/// 所有内置策略通过 4 个 named factory 集中暴露
/// ([AwaitTransformer.sequential] / [AwaitTransformer.concurrent] /
/// [AwaitTransformer.droppable] / [AwaitTransformer.restartable])，IDE 自动
/// 补全 `AwaitTransformer.` 一次看完，调用方无需 import 任何具体类。
/// **4 个实现以顶层 private const 类形式声明**（Dart 不支持 class 内嵌套 class），整个策略族
/// 真正集中在一个 class 的作用域里。
///
/// **E 在 onAwait 调用侧自动推断**：业务写法
/// `onAwait<Refresh>(..., transformer: AwaitTransformer.droppable())` 不需要
/// 写 `<Refresh>` 显式泛型，编译器从 [BlocAwaitMixin.onAwait] 的
/// `AwaitTransformer<E>?` 参数类型反推 E。
///
/// 自定义 transformer：实现 [build] 即可，hook 由 [BlocAwaitMixin.onAwait] 以
/// `this` 注入，开发者无需手动捕获 bloc 实例。
///
/// `E` 不加 `extends Event` 约束：`Event` 只是每个 Bloc 的泛型参数、并非全局
/// 基类，顶层工厂类无从引用；类型安全由 [BlocAwaitMixin.onAwait] 的
/// `E extends Event` 在调用侧兜底。
abstract class AwaitTransformer<E> {
  /// sequential：排队处理（一次只 active 一个 inner stream，后到事件进 buffer
  /// 等当前 inner stream close 才开始下一个）。无 hook 回调。
  ///
  /// 与 [concurrent] 行为差异示例（handler 各 `await Future.delayed(50ms)`，
  /// 依次派发 e1/e2/e3）：
  /// - `sequential`：e1 完 → e2 完 → e3 完（总 150ms+）
  /// - `concurrent`：e1/e2/e3 几乎同时 start、几乎同时完（总 ≈ 50ms+）
  factory sequential() => _SequentialAwaitTransformer<E>();

  /// concurrent：所有事件并发（每个 outer event 立刻 spawn mapper 子订阅，
  /// 多个 inner stream 同时 active；完成顺序不保证，行为同 bloc 默认）。
  /// 无 hook 回调。
  ///
  /// 注意：`asyncExpand` 自身是 sequential（一次一个 inner），并不能并发；
  /// 这里用 `Stream.multi + events.listen + mapper.listen` 真正让多个 mapper
  /// 子订阅并行 active。
  factory concurrent() => _ConcurrentAwaitTransformer<E>();

  /// droppable：in-flight 期间新事件被丢弃，回调 `hook.onDropped(event)`。
  ///
  /// 注意：不能用 `events.asyncExpand` —— asyncExpand 顺序处理，只有一个
  /// inner stream 活跃，e2 会等 e1 的 mapper stream close 后才被分发。
  /// 这里直接 `events.listen` 并发 dispatch：
  /// - 新事件到，若 in-flight 则 `hook.onDropped`；否则 in-flight=true 并开 mapper 子订阅
  /// - 子订阅 onDone 时 in-flight=false；这样后续事件能继续入队
  factory droppable() => _DroppableAwaitTransformer<E>();

  /// restartable：switchMap 语义——新事件来时**立即**取消旧 inner 订阅（旧
  /// handler 仍跑完，但 dispatch 不阻塞）+ `hook.onSuperseded(inFlightEvent!)`。
  /// 新事件同时被立即派发，不需要等旧 handler 完成。
  ///
  /// 注意：取消 inner **subscription** 不终止 handler 的 Future 本身（旧
  /// handler 仍跑完直到 await 处自然结束）。Transformer 只管调度，handler
  /// 业务应通过 cancel token / 检查 `emit.isDone` 响应 cancellation。
  factory restartable() => _RestartableAwaitTransformer<E>();

  /// 每次 `onAwait` 注册时调用一次，产出一个全新的 [EventTransformer]。
  ///
  /// 闭包内的 in-flight 等可变状态随闭包隔离，多次注册互不干扰；本类实现
  /// 因此保持无状态（factory 每次返回新实例）。
  EventTransformer<E> build(AwaitTransformerHook hook);
}

// ============================================================
// AwaitTransformer 私有实现类
// ============================================================
// ⚠️ Dart 暂不支持 class 内嵌套 class（analyzer 报 `class_in_class`），
// 故 4 个实现以**顶层 private const 类**形式独立声明，但调用方只通过
// 4 个 [AwaitTransformer.sequential] / [.concurrent] / [.droppable] /
// [.restartable] factory 接触，私有类对外不可见。设计意图仍是「策略族集中
// 在 [AwaitTransformer] 抽象类下」——factory 是唯一公开入口。

class _SequentialAwaitTransformer<E> implements AwaitTransformer<E> {
  @override
  EventTransformer<E> build(AwaitTransformerHook hook) =>
      (events, mapper) => events.asyncExpand(mapper);
}

class _ConcurrentAwaitTransformer<E> implements AwaitTransformer<E> {
  @override
  EventTransformer<E> build(AwaitTransformerHook hook) => (events, mapper) {
    return Stream<dynamic>.multi((mc) {
      events.listen(
        (event) {
          // 每个 outer event 立刻 mapper 派发，独立 listen
          mapper(event)
              .listen(mc.add, onError: mc.addError, cancelOnError: false);
        },
        onError: mc.addError,
        onDone: mc.close,
        cancelOnError: false,
      );
    }).cast<E>();
  };
}

class _DroppableAwaitTransformer<E> implements AwaitTransformer<E> {
  @override
  EventTransformer<E> build(AwaitTransformerHook hook) {
    return (events, mapper) {
      var inFlight = false;
      return Stream<dynamic>.multi((mc) {
        events.listen(
          (event) {
            if (inFlight) {
              hook.onDropped(event!);
              return;
            }
            inFlight = true;
            mapper(event).listen(
              mc.add,
              onError: mc.addError,
              onDone: () {
                inFlight = false;
              },
              cancelOnError: false,
            );
          },
          onError: mc.addError,
          onDone: mc.close,
          cancelOnError: false,
        );
      }).cast<E>();
    };
  }
}

class _RestartableAwaitTransformer<E> implements AwaitTransformer<E> {
  @override
  EventTransformer<E> build(AwaitTransformerHook hook) {
    return (events, mapper) {
      // 真正的 switchMap 语义：新 event 来时立即取消旧 inner 订阅（不等待旧
      // handler 跑完）并立即派发新 event。**不能**用 `controller.stream.asyncExpand`
      // —— asyncExpand 会串行等待当前 inner stream close，新 event 必须等旧
      // handler 跑完才能被派发，这会让 restartable 退化成「async sequential +
      // drop superseded」。
      //
      // 用 `Stream.multi + events.listen + mapper(event).listen` 直派：
      // - 新 event 到，若 in-flight 则 `unawaited(currentSub.cancel())` +
      //   `hook.onSuperseded(inFlightEvent!)`；否则直接派发
      // - 每个 outer event 立刻独立 mapper 订阅，多 inner stream 切换
      //
      // 注意：取消 inner **subscription** 不终止 handler 的 Future 本身——旧
      // handler 仍会跑完（被 transform 的 cancel 只能影响 stream 订阅，不影响
      // Future/async 路径）。这要求 handler 内部能响应 cancellation（cancel
      // token / 检查 emit.isDone）才能真正"立即停止旧工作"；transformer 只能
      // 管调度，终止 handler 业务是 handler 的责任。
      return Stream<dynamic>.multi((mc) {
        StreamSubscription<dynamic>? currentSub;
        E? inFlightEvent;
        events.listen(
          (event) {
            if (currentSub != null) {
              unawaited(currentSub!.cancel());
              if (inFlightEvent != null) hook.onSuperseded(inFlightEvent!);
            }
            inFlightEvent = event;
            currentSub = mapper(event)
                .listen(mc.add, onError: mc.addError, cancelOnError: false);
          },
          onError: mc.addError,
          onDone: mc.close,
          cancelOnError: false,
        );
      }).cast<E>();
    };
  }
}

// ============================================================
// 内部 pending 条目
// ============================================================

/// 内部 pending 条目。T 在 `runAwait` 创建时通过闭包捕获。
class _AwaitEntry<S> {
  new({
    required this.recordTransition,
    required this.resolveSuccess,
    required this.resolveFailure,
    required this.resolveDropped,
    required this.resolveCancelled,
  });

  final void Function(S nextState) recordTransition;
  final void Function() resolveSuccess;
  final void Function(Object error, StackTrace? stackTrace) resolveFailure;
  final void Function() resolveDropped;
  final void Function() resolveCancelled;

  bool resolved = false;
}

int _awaitIdSeed = 0;

String _newRequestId() => 'await-${_awaitIdSeed++}';

// ============================================================
// 主 mixin（内含 transformer 工厂）
// ============================================================

/// 在 MVI 架构下提供接近 MVVM 的异步调用：
/// Command(`runAwait` 通过 Expando 身份键关联 event) +
/// Result(`<AwaitResolution<State>>`) + Promise(Completer) + Observer(`onTransition + onDone`)
/// + Drop-aware Transformer（`AwaitTransformer.droppable() / .restartable()`
/// 在抽象类内集中暴露）。
///
/// **关键设计：Expando 身份键关联 + 内置 transformer**
/// - 用户的领域事件**完全不变**：不实现接口、不带 requestId 字段
/// - `runAwait<E>(event)` 接收原始 event，返回固定为 `AwaitResolution<State>`，
///   按对象 identity 把 event 映射到 requestId，然后 `add(event)` 派发原始事件
/// - `onTransition` / `onDone` 读 `transition.event` / `doneEvent`，按 Expando
///   反查 id 关联 pending
/// - transformer 丢包 / 顶替时回调 `hook.onDropped / onSuperseded(event)`，
///   同样按 Expando 反查 id
///
/// **完成信号双钩子**：`onTransition` 记录最后 nextState，`onDone` 决定 completed /
/// errored 并 resolve；dropped 由 transformer 通过 hook 回调 resolve。
/// 注意：completed / errored 描述的是 **handler 执行层**成败（跑完 / 抛错），
/// 不是业务成败——业务失败未抛错仍记为 completed。
///
/// **无 timeout**：正常 handler 总有 `onDone`；不结束的 handler 应使用 cancel token
/// / Dio 超时；dispose 走 `close()` -> `AwaitCancelled`。
mixin BlocAwaitMixin<Event, State> on Bloc<Event, State>
    implements AwaitTransformerHook {
  final Map<String, _AwaitEntry<State>> _pending = {};

  /// 按对象 identity 把用户 event 关联到 requestId（WeakMap 语义，event GC 后自动清理）。
  final Expando<String> _eventToRequestId = Expando<String>();

  /// 发起一次 awaitable 请求，返回固定为 `<AwaitResolution<State>>`。
  ///
  /// `E` 从 `event` 推断。mixin 用 Expando 把 `event`（identity）映射到 requestId，
  /// 然后 `add(event)` 派发原始事件。expando 反查路径：
  /// `onTransition` / `onDone` / `hook.onDropped` / `hook.onSuperseded` 收到 event 后
  /// 都能找到对应的 pending。
  ///
  /// **返回类型固定为 `State`**（当前 BLoC 的 State），不再暴露自由泛型 `T` 与
  /// `extract` 参数：避免"写了 `T` 却忘了传 `extract` / 传了 `extract` 却忘了改
  /// `T` 类型"的二选一陷阱。调用端需要哪些字段，直接从 `AwaitCompleted.value`
  /// （即 emit 后或当前的 `state`）中取即可。
  Future<AwaitResolution<State>> runAwait<E extends Event>(E event) {
    if (isClosed) return Future.value(AwaitCancelled<State>());
    final id = _newRequestId();
    final completer = Completer<AwaitResolution<State>>();
    State? lastNextState;
    late _AwaitEntry<State> entry;
    entry = _AwaitEntry<State>(
      recordTransition: (s) {
        if (entry.resolved) return;
        lastNextState = s;
      },
      resolveSuccess: () {
        if (entry.resolved) return;
        entry.resolved = true;
        _pending.remove(id);
        // 固定携带 emit 后或当前的 state（即运行类型 State）。
        final State value = lastNextState ?? state;
        completer.complete(AwaitCompleted<State>(value));
      },
      resolveFailure: (error, st) {
        if (entry.resolved) return;
        entry.resolved = true;
        _pending.remove(id);
        completer.complete(AwaitErrored<State>(error, st));
      },
      resolveDropped: () {
        if (entry.resolved) return;
        entry.resolved = true;
        _pending.remove(id);
        completer.complete(AwaitDropped<State>());
      },
      resolveCancelled: () {
        if (entry.resolved) return;
        entry.resolved = true;
        _pending.remove(id);
        completer.complete(AwaitCancelled<State>());
      },
    );
    _pending[id] = entry;
    _eventToRequestId[event as Object] = id;
    try {
      add(event);
      // 这里需要 catch 所有 throwable（add 既可能因 assert 抛 StateError，也可能
      // 因 controller 关闭抛其他 Error/Exception），不限定 on 子句。
      // ignore: avoid_catches_without_on_clauses
    } catch (error, stackTrace) {
      // `add` 内部会 assert handler 已注册 / bloc 未关闭；任一不满足都会抛
      // `StateError`。捕获后清理 pending + 立即 resolve 为 `AwaitErrored`，
      // 避免 caller 的 Future 永久挂起。
      _pending.remove(id);
      completer.complete(AwaitErrored<State>(error, stackTrace));
    }
    return completer.future;
  }

  /// 注册一个 awaitable 事件处理器。
  ///
  /// 与 [Bloc.on] 的区别：本方法接受 [AwaitTransformer]（策略对象），内部调用
  /// `transformer.build(this)` 注入 [AwaitTransformerHook]。transformer 丢包 / 顶替时
  /// 回调 `hook.onDropped / onSuperseded`，从而把对应 waiter resolve 为
  /// [AwaitDropped]。未提供 transformer 时使用 bloc 默认（concurrent，永不 drop）。
  ///
  /// 只有通过 `onAwait` 注册的事件才支持 `runAwait` 等待——这是显式 opt-in。
  /// 通过 `Bloc.on` 注册的事件无法等待。
  void onAwait<E extends Event>(
    EventHandler<E, State> handler, {
    AwaitTransformer<E>? transformer,
  }) {
    on<E>(handler, transformer: transformer?.build(this));
  }

  // ============================================================
  // Observer 钩子 / Hook 实现
  // ============================================================

  /// Observer 第一钩子：记录最后一次与本请求相关的 transition 的 nextState。
  @override
  void onTransition(Transition<Event, State> transition) {
    final id = _eventToRequestId[transition.event as Object];
    if (id != null) {
      final entry = _pending[id];
      if (entry != null) entry.recordTransition(transition.nextState);
    }
    super.onTransition(transition);
  }

  /// Observer 第二钩子：决定 completed / errored 并 resolve（基于 handler 执行层
  /// 成败，非业务成败）。
  @override
  void onDone(Event event, [Object? error, StackTrace? stackTrace]) {
    final id = _eventToRequestId[event as Object];
    if (id != null) {
      final entry = _pending.remove(id);
      if (entry != null) {
        if (error != null) {
          entry.resolveFailure(error, stackTrace);
        } else {
          entry.resolveSuccess();
        }
      }
    }
    super.onDone(event, error, stackTrace);
  }

  /// AwaitTransformerHook 实现：transformer 丢包时 resolve `AwaitDropped`。
  @override
  void onDropped(Object event) {
    final id = _eventToRequestId[event];
    if (id == null) return;
    final entry = _pending[id];
    if (entry == null) return;
    _pending.remove(id);
    if (!entry.resolved) {
      entry.resolveDropped();
    }
  }

  /// AwaitTransformerHook 实现：restartable 顶替旧事件时同样 resolve `AwaitDropped`。
  @override
  void onSuperseded(Object event) {
    onDropped(event);
  }

  /// BLoC 关闭：所有未决请求以 `AwaitCancelled` 收尾。
  @override
  Future<void> close() {
    final entries = _pending.values.toList();
    _pending.clear();
    for (final entry in entries) {
      entry.resolveCancelled();
    }
    return super.close();
  }
}
