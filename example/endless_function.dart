// ignore_for_file: close_sinks, cancel_subscriptions, unawaited_futures, avoid_print

import 'dart:async';

Future<void> main() async {
  try {
    await someLongFunction().timeout(const Duration(milliseconds: 350));
    return;
  } on TimeoutException {
    print('TimeoutException');
  }
}

Future<void> someLongFunction() async {
  final periodic = Stream<int>.periodic(
    const Duration(milliseconds: 250),
    (i) => i,
  );
  await periodic.take(3).forEach(print);
}
