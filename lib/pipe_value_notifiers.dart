import 'dart:async';

import 'package:flutter/foundation.dart';

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

typedef CombiningFunction2<TIn1, TIn2, TOut> = TOut Function(TIn1, TIn2);

class CombiningPipeValueNotifier<TIn1, TIn2, TOut> extends ValueNotifier<TOut> {
  final ValueListenable<TIn1> previousInChain1;
  final ValueListenable<TIn2> previousInChain2;
  final CombiningFunction2<TIn1, TIn2, TOut> combiner;
  VoidCallback internalHandler;

  CombiningPipeValueNotifier(
    TOut initialValue,
    this.previousInChain1,
    this.previousInChain2,
    this.combiner,
  ) : super(initialValue) {
    internalHandler = () {
      return value = combiner(previousInChain1.value, previousInChain2.value);
    };
    previousInChain1.addListener(internalHandler);
    previousInChain2.addListener(internalHandler);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (!hasListeners) {
      previousInChain1.removeListener(internalHandler);
      previousInChain2.removeListener(internalHandler);
    }
    super.removeListener(listener);
  }

  @override
  void dispose() {
    previousInChain1.removeListener(internalHandler);
    previousInChain2.removeListener(internalHandler);
    super.dispose();
  }
}
