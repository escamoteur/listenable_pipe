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

  ValueListenable<TOut> combineLatest<T, TIn2, TOut>(
      ValueListenable<TIn2> combineWith,
      CombiningFunction2<T, TIn2, TOut> combiner) {
    return CombiningPipeValueNotifier<T, TIn2, TOut>(
      combiner(this.value, combineWith.value),
      this,
      combineWith,
      combiner,
    );
  }

  ListenableSubscription listen(void Function(T) handler) {
    final interalHandler = () => handler(this.value);
    this.addListener(interalHandler);
    return ListenableSubscription(this, interalHandler);
  }
}

class ListenableSubscription {
  final Listenable source;
  final VoidCallback handler;

  ListenableSubscription(this.source, this.handler);

  void cancel() {
    source.removeListener(handler);
  }
}
