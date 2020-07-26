import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listenable_pipe/listenable_pipe.dart';

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
    final sourceListenable = ValueNotifier<int>(0);

    int destValue;
    final subscription = sourceListenable.listen((x) => destValue = x);

    sourceListenable.value = 42;

    expect(destValue, 42);

    subscription.cancel();

    sourceListenable.value = 4711;

    expect(destValue, 42);
  });

  test('Where Test', () {
    final sourceListenable = ValueNotifier<int>(0);

    final destValues = <int>[];
    final subscription = sourceListenable
        .where((x) => x.isEven)
        .listen((x) => destValues.add(x));

    sourceListenable.value = 42;
    sourceListenable.value = 43;
    sourceListenable.value = 44;
    sourceListenable.value = 45;

    expect(destValues, [42, 44]);

    subscription.cancel();

    sourceListenable.value = 46;

    expect(destValues.length, 2);
  });
  test('Debounce Test', () async {
    final sourceListenable = ValueNotifier<int>(0);

    final destValues = <int>[];
    final subscription = sourceListenable
        .debounce(const Duration(milliseconds: 500))
        .listen((x) => destValues.add(x));

    sourceListenable.value = 42;
    await Future.delayed(const Duration(milliseconds: 100));
    sourceListenable.value = 43;
    await Future.delayed(const Duration(milliseconds: 100));
    sourceListenable.value = 44;
    await Future.delayed(const Duration(milliseconds: 350));
    sourceListenable.value = 45;
    await Future.delayed(const Duration(milliseconds: 550));
    sourceListenable.value = 46;

    expect(destValues, [42, 45, 46]);
  });
}
