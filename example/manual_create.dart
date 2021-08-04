// ignore_for_file: close_sinks, cancel_subscriptions, unawaited_futures, avoid_print, avoid_types_on_closure_parameters

import 'dart:async';
import 'dart:isolate';

void main() => runZoned(() async {
      final sendPortToIsolate = await initIsolate();
      sendPortToIsolate.send('Hello world');
    });

Future<SendPort> initIsolate() async {
  final completer = Completer<SendPort>();
  final isolateToMainStream = ReceivePort();
  late StreamSubscription sub;
  sub = isolateToMainStream.listen((Object? data) {
    if (!completer.isCompleted && data is SendPort) {
      final mainToIsolateStream = data;
      completer.complete(mainToIsolateStream);
    } else {
      print('[Main isolate] $data');
      sub.cancel();
      isolateToMainStream.close();
    }
  });

  final createdIsolateInstance = await Isolate.spawn(
    createdIsolate,
    isolateToMainStream.sendPort,
  );
  final sendPortFromIsolate = await completer.future;
  return sendPortFromIsolate;
}

void createdIsolate(SendPort isolateToMainStream) {
  final mainToIsolateStream = ReceivePort();
  isolateToMainStream.send(mainToIsolateStream.sendPort);

  mainToIsolateStream.listen((Object? data) {
    print('[Created isolate] $data');
    isolateToMainStream.send(data);
    Isolate.current.kill();
  });
}
