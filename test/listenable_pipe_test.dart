import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listenable_pipe/listenable_pipe_extensions.dart';

void main() {
  test('Map Test', () {
    final sourceListenable = ValueNotifier<int>(0);
    final destListenable = sourceListenable.map<String>((x) {
      return x.toString();
    });

    String destValue;
    final handler = () => destValue = destListenable.value;
    destListenable.addListener(handler);

    sourceListenable.value = 42;

    expect(destListenable.value, '42');
    expect(destValue, '42');

    destListenable.removeListener(handler);

    sourceListenable.value = 4711;

    expect(destValue, '42');
  });

  test('Listen Test', () {
    final listenable = ValueNotifier<int>(0);

    int destValue;
    final subscription = listenable.listen((x, _) => destValue = x);

    listenable.value = 42;

    expect(destValue, 42);

    subscription.cancel();

    listenable.value = 4711;

    expect(destValue, 42);
  });

  test('Where Test', () {
    final listenable = ValueNotifier<int>(0);

    final destValues = <int>[];
    final subscription =
        listenable.where((x) => x.isEven).listen((x, _) => destValues.add(x));

    listenable.value = 42;
    listenable.value = 43;
    listenable.value = 44;
    listenable.value = 45;

    expect(destValues, [42, 44]);

    subscription.cancel();

    listenable.value = 46;

    expect(destValues.length, 2);
  });

  test('Debounce Test', () async {
    final listenable = ValueNotifier<int>(0);

    final destValues = <int>[];
    listenable
        .debounce(const Duration(milliseconds: 500))
        .listen((x, _) => destValues.add(x));

    listenable.value = 42;
    await Future.delayed(const Duration(milliseconds: 100));
    listenable.value = 43;
    await Future.delayed(const Duration(milliseconds: 100));
    listenable.value = 44;
    await Future.delayed(const Duration(milliseconds: 350));
    listenable.value = 45;
    await Future.delayed(const Duration(milliseconds: 550));
    listenable.value = 46;

    expect(destValues, [42, 45]);
  });

  test('combineLatest Test', () {
    final listenable1 = ValueNotifier<int>(0);
    final listenable2 = ValueNotifier<String>('Start');

    final destValues = <StingIntWrapper>[];
    final subscription = listenable1
        .combineLatest<String, StingIntWrapper>(
            listenable2, (i, s) => StingIntWrapper(s, i))
        .listen((x, _) {
      destValues.add(x);
    });

    listenable1.value = 42;
    listenable1.value = 43;
    listenable2.value = 'First';
    listenable1.value = 45;

    expect(destValues[0].toString(), 'Start:42');
    expect(destValues[1].toString(), 'Start:43');
    expect(destValues[2].toString(), 'First:43');
    expect(destValues[3].toString(), 'First:45');

    subscription.cancel();

    listenable1.value = 46;

    expect(destValues.length, 4);
  });
}

class StingIntWrapper {
  final String s;
  final int i;

  StingIntWrapper(this.s, this.i);

  @override
  String toString() {
    return '$s:$i';
  }
}
