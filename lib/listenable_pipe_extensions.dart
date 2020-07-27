library listenable_pipe;

import 'package:flutter/foundation.dart';
import 'package:listenable_pipe/pipe_value_notifiers.dart';

extension ListenablePipe<T> on ValueListenable<T> {
  ValueListenable<TResult> map<TResult>(TResult Function(T) convert) {
    return MapPipeValueNotifier<T, TResult>(
      convert(this.value),
      this,
      convert,
    );
  }

  ValueListenable<T> where(bool Function(T) selector) {
    return WherePipeValueNotifier(this.value, this, selector);
  }

  ValueListenable<T> debounce(Duration timeOut) {
    return DebouncedPipeValueNotifier(this.value, this, timeOut);
  }

  ValueListenable<TOut> combineLatest<TIn2, TOut>(
      ValueListenable<TIn2> combineWith,
      CombiningFunction2<T, TIn2, TOut> combiner) {
    return CombiningPipeValueNotifier<T, TIn2, TOut>(
      combiner(this.value, combineWith.value),
      this,
      combineWith,
      combiner,
    );
  }

  ListenableSubscription listen(
      void Function(T, ListenableSubscription) handler) {
    final subscription = ListenableSubscription(this);
    subscription.handler = () => handler(this.value, subscription);
    this.addListener(subscription.handler);
    return subscription;
  }
}

class ListenableSubscription {
  final ValueListenable endOfPipe;
  VoidCallback handler;

  ListenableSubscription(this.endOfPipe);

  void cancel() {
    assert(handler != null);
    endOfPipe.removeListener(handler);
  }
}
