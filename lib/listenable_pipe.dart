library listenable_pipe;

import 'dart:async';

import 'package:flutter/foundation.dart';

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

abstract class PipeValueNotifier<TIn, TOut> extends ValueNotifier<TOut> {
  final ValueListenable previousInChain;
  TOut Function(TIn) transformation;
  bool Function(TIn) selector;
  VoidCallback internalHandler;

  PipeValueNotifier(
    TOut initialValue,
    this.previousInChain,
  ) : super(initialValue);

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

class MapPipeValueNotifier<TIn, TOut> extends PipeValueNotifier<TIn, TOut> {
  TOut Function(TIn) transformation;

  MapPipeValueNotifier(
    TOut initialValue,
    ValueListenable previousInChain,
    this.transformation,
  ) : super(initialValue, previousInChain) {
    internalHandler = () {
      value = transformation(previousInChain.value);
    };
    previousInChain.addListener(internalHandler);
  }
}

class WherePipeValueNotifier<T> extends PipeValueNotifier<T, T> {
  bool Function(T) selector;

  WherePipeValueNotifier(
    T initialValue,
    ValueListenable<T> previousInChain,
    this.selector,
  ) : super(initialValue, previousInChain) {
    internalHandler = () {
      if (selector(previousInChain.value)) {
        value = previousInChain.value;
      }
    };
    previousInChain.addListener(internalHandler);
  }
}

class DebouncedPipeValueNotifier<T> extends PipeValueNotifier<T, T> {
  Timer debounceTimer;
  Duration debounceDuration;

  DebouncedPipeValueNotifier(
    T initialValue,
    ValueListenable<T> previousInChain,
    this.debounceDuration,
  ) : super(initialValue, previousInChain) {
    internalHandler = () {
      if (debounceTimer == null) {
        debounceTimer = Timer(debounceDuration, () => debounceTimer = null);
        value = previousInChain.value;
      }
    };
    previousInChain.addListener(internalHandler);
  }
}
