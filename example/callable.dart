// ignore_for_file: avoid_print

import 'package:meta/meta.dart';

void main() => A.initialize().then<void>(print);

@immutable
abstract class A {
  static const _LazyInitializationA initialize = _LazyInitializationA();

  @literal
  const A._internal();
}

class _AImpl extends A {
  @literal
  const _AImpl() : super._internal();

  @override
  String toString() => '<A>';
}

@immutable
class _LazyInitializationA {
  const _LazyInitializationA();

  @factory
  Future<A> call() async {
    await Future<void>.delayed(Duration.zero);
    // some evals
    return const _AImpl();
  }
}
