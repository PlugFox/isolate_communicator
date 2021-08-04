// ignore_for_file: close_sinks, cancel_subscriptions, unawaited_futures, avoid_print

import 'dart:async';

void main() {
  Future<void>.delayed(const Duration(seconds: 1), () => log(1));
  Future<void>.delayed(Duration.zero, () => log(2));
  Future<void>(() => log(3)).whenComplete(() => log(4));
  Future<void>.sync(() => log(5));
  Future<void>.microtask(() => log(6));
  scheduleMicrotask(() => log(6));
  log(7);
  Future<void>.microtask(() => log(8));
  Future<void>.sync(() => log(9));
  Future<void>(() => log(10));
  Future<void>.delayed(Duration.zero, () => log(11));
  Future<void>.delayed(const Duration(seconds: 1), () => log(12));
}

void log(int i) => print(i.toString());

// sync
// 5 7 9

// microtask
// 6 8

// future / event
// 2 3 4 10 11 1 12
