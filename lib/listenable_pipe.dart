library listenable_pipe;

import 'dart:async';

import 'package:flutter/foundation.dart';

extension ListenablePipe<T> on ValueListenable<T> {
  ValueListenable<TResult> map<TResult>(TResult Function(T) convert) {
    return PipeValueNotifier<T, TResult>(
      convert(this.value),
      this,
      convert,
    );
  }

  ValueListenable<T> where(bool Function(T) selector) {
    return PipeValueNotifier.where(this.value, this, selector);
  }

  ValueListenable<T> debounce(Duration timeOut) {
    return PipeValueNotifier.debounce(this.value, this, timeOut);
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

class PipeValueNotifier<TIn, TOut> extends ValueNotifier<TOut> {
  final ValueListenable previousInChain;
  TOut Function(TIn) transformation;
  bool Function(TIn) selector;
  VoidCallback internalHandler;
  Timer debounceTimer;
  Duration debounceDuration;

  PipeValueNotifier(
    TOut initialValue,
    this.previousInChain,
    this.transformation,
  ) : super(initialValue) {
    internalHandler = () {
      value = transformation(previousInChain.value);
    };
    previousInChain.addListener(internalHandler);
  }

  PipeValueNotifier.where(
    TOut initialValue,
    this.previousInChain,
    this.selector,
  ) : super(initialValue) {
    internalHandler = () {
      if (selector(previousInChain.value)) {
        value = previousInChain.value;
      }
    };
    previousInChain.addListener(internalHandler);
  }

  PipeValueNotifier.debounce(
    TOut initialValue,
    this.previousInChain,
    this.debounceDuration,
  ) : super(initialValue) {
    internalHandler = () {
      if (debounceTimer == null) {
        debounceTimer = Timer(debounceDuration, () => debounceTimer = null);
        value = previousInChain.value;
      }
    };
    previousInChain.addListener(internalHandler);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (!hasListeners) {
      previousInChain.removeListener(internalHandler);
    }
    super.removeListener(listener);
  }

  @override
  void dispose() {
    previousInChain.removeListener(internalHandler);
    super.dispose();
  }
}
