// ignore_for_file: close_sinks, cancel_subscriptions, unawaited_futures, avoid_print
import 'dart:async';

import 'package:playground/src/communicator.dart';

// computer
// worker_manager

// compute

void main() => runZonedGuarded(() async {
      final communicator = await IsolateCommunicator.spawn<String, int, int>(
        helloWorld,
        123,
      );
      //Timer(const Duration(seconds: 2), communicator.close);
      communicator
        ..listen((event) => print('Get: $event'))
        ..add('1')
        ..add('2')
        ..add('3');
    }, (error, stackTrace) {
      print('Top level exception: "$error"\n$stackTrace');
    });

void helloWorld(
  IsolateCommunicator<int, String> communicator,
  int text,
) {
  print('Initial argument: $text');
  communicator.forEach(
    (event) {
      final result = int.parse(event);
      communicator.add(result);
    },
  );
}
