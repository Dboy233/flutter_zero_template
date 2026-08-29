import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// 为任意 [Bloc] 提供基于 Completer 的通用操作等待能力。
///
/// 解决 MVI 中 `add(Event)` 是 fire-and-forget、UI 无法直接 `await` 的问题。
/// 通过 `runAwait()` 在发送事件前注册 Completer，事件处理结束时由
/// `completeAwait()`（或 `onAwait` 的自动收尾）完成等待。
///
/// 合并策略（single-flight）：以**事件值**作为操作身份。相同事件进行中时
/// 只派发一次事件，后续调用共享同一趟操作；不同参数的事件各自独立执行。
/// 这要求事件实现 `==`/`hashCode`（freezed 事件天然满足；未实现时退化为
/// 恒不合并，即每次调用都会派发，行为安全）。
///
/// 用法：
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with BlocAwaitMixin<MyEvent, MyState> {
///   MyBloc() : super(const MyState()) {
///     onAwait<MyRefresh>(_onRefresh);
///   }
///
///   Future<void> refresh() => runAwait(event: const MyRefresh());
/// }
/// ```
///
/// 页面层：
/// ```dart
/// RefreshIndicator(
///   onRefresh: () => context.read<MyBloc>().refresh(),
///   child: ListView.builder(...),
/// )
/// ```
///
/// 并发策略：`onAwait` 注册的事件按默认并发处理，不提供 transformer 透传。
/// 需要特殊并发策略（`sequential()` / `droppable()` / `restartable()`）的
/// 操作，请退回裸 `on` 并在 handler 的 `finally` 中手动调用 [completeAwait]。
///
/// Provides generic Completer-based operation awaiting for any [Bloc].
///
/// Solves the problem that `add(Event)` is fire-and-forget in MVI, so the UI
/// cannot directly `await` it. `runAwait()` registers a Completer before the
/// event is dispatched; the event handler finishes the wait via
/// `completeAwait()` (or the automatic cleanup of `onAwait`).
///
/// Merging strategy (single-flight): the **event value** is the operation
/// identity. While an identical event is in flight only one event is
/// dispatched and later callers share that operation; events with different
/// arguments run independently. This requires events to implement
/// `==`/`hashCode` (freezed events do; otherwise this degrades to never
/// merging, i.e. every call dispatches, which is safe).
///
/// Concurrency: events registered via `onAwait` use the default concurrent
/// processing; no transformer passthrough is offered. For operations that
/// need a special concurrency policy (`sequential()` / `droppable()` /
/// `restartable()`), fall back to a plain `on` and call [completeAwait]
/// manually in the handler's `finally` block.
mixin BlocAwaitMixin<Event, State> on Bloc<Event, State> {
  /// 以事件值为 key 的等待者表。
  ///
  /// The waiter table keyed by event value.
  final Map<Event, List<Completer<void>>> _awaitCompleters = {};

  /// 触发 [event] 并返回一个 Future，无论事件处理成功、失败或被跳过都会完成。
  ///
  /// 合并策略（single-flight）：相同事件进行中时不再重复派发，本次调用注册
  /// 自己的 Completer，与已有等待者共享同一趟操作。
  ///
  /// 每个调用方拥有独立的超时 Timer，互不影响。默认 30 秒超时：超时后该
  /// 等待者收到 [TimeoutException]，其 Completer 立即从等待列表中移除，
  /// 不影响同事件下其他仍在等待的调用方。
  ///
  /// Dispatches [event] and returns a Future that completes regardless of
  /// whether the event handler succeeds, fails, or returns early.
  ///
  /// Merging strategy (single-flight): while an identical event is in flight
  /// no second event is dispatched; this call registers its own Completer and
  /// shares the ongoing operation.
  ///
  /// Every caller owns an independent timeout timer and they do not affect
  /// each other. Defaults to a 30 second timeout: on timeout the waiter
  /// receives a [TimeoutException], its Completer is removed from the pending
  /// list immediately, and other waiters on the same event that are still
  /// within their own timeouts are not affected.
  Future<void> runAwait({
    required Event event,
    Duration timeout = const Duration(seconds: 30),
  }) {
    if (isClosed) {
      return Future<void>.error(
        StateError('Cannot runAwait on a closed Bloc: $event'),
      );
    }
    final completer = Completer<void>();
    final completers = _awaitCompleters.putIfAbsent(event, () => []);
    // single-flight：已有等待者 => 同一操作正在进行，只合并等待、不重复派发。
    // Single-flight: existing waiters mean the operation is already in
    // flight — join it instead of dispatching a duplicate event.
    final hasPendingOperation = completers.isNotEmpty;
    completers.add(completer);
    // 用独立 Timer 而非 Future.timeout：超时只完成并移除自己的 Completer，
    // 既保证调用方真正收到 TimeoutException，也不污染同事件的其他等待者。
    // Use a dedicated Timer instead of Future.timeout: on timeout only this
    // waiter's Completer is completed (with an error) and removed, so the
    // caller really receives the TimeoutException and other waiters on the
    // same event are not affected.
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('事件 $event 执行超时'));
        completers.remove(completer);
      }
    });
    if (!hasPendingOperation) {
      add(event);
    }
    return completer.future.whenComplete(timer.cancel);
  }

  /// 完成所有正在等待 [event] 操作的 Future。
  ///
  /// 应优先通过 [onAwait] 自动调用；手写 `on` 的 handler 需在 `finally` 中
  /// 调用，确保即使被跳过也能结束等待。
  ///
  /// Completes all Futures waiting for the operation identified by [event].
  ///
  /// Prefer the automatic cleanup of [onAwait]; handlers registered with a
  /// plain `on` must call this in their `finally` block so early returns also
  /// unblock waiters.
  void completeAwait(Event event) {
    final completers = _awaitCompleters.remove(event);
    if (completers != null) {
      for (final completer in completers) {
        if (!completer.isCompleted) completer.complete();
      }
    }
  }

  /// 以「自动收尾」方式注册事件处理器。
  ///
  /// 与 [on] 命名统一、语义相近，区别在于内部用 `try/finally` 自动调用
  /// [completeAwait]，开发者无需在 handler 的 `finally` 中手动书写，避免
  /// 漏写导致 [RefreshIndicator] 挂起。
  ///
  /// Registers an event handler with automatic completion.
  ///
  /// Similar to [on] but wraps [handler] with `try/finally` that
  /// automatically calls [completeAwait], so developers never forget it
  /// (which would hang a [RefreshIndicator]).
  void onAwait<E extends Event>(EventHandler<E, State> handler) {
    on<E>((event, emit) async {
      try {
        await handler(event, emit);
      } finally {
        completeAwait(event);
      }
    });
  }

  /// BLoC 关闭时清理未完成的 Completer，避免内存泄漏和永久挂起。
  ///
  /// 所有等待者以正常方式完成（不抛异常）——页面销毁是正常生命周期，
  /// 等待方（如 [RefreshIndicator]）不应因此收到错误。
  ///
  /// Cleans up pending completers when the BLoC is closed to prevent memory
  /// leaks and permanent hangs.
  ///
  /// All waiters complete normally (no error) — page disposal is a normal
  /// lifecycle event, and waiters (such as a [RefreshIndicator]) should not
  /// receive an error because of it.
  @override
  Future<void> close() {
    for (final entry in _awaitCompleters.entries) {
      for (final completer in entry.value) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }
    _awaitCompleters.clear();
    return super.close();
  }
}
