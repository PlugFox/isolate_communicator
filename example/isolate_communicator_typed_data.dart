// ignore_for_file: close_sinks, cancel_subscriptions, unawaited_futures, avoid_print
import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:playground/src/communicator.dart';

void main() => runZonedGuarded(() async {
      final communicator = await IsolateCommunicator.spawn<TransferableTypedData, TransferableTypedData, String>(
        helloWorld,
        'Hello world',
      );
      final file = io.File('example/assets/large-file.json');
      final binaryData = file.readAsBytesSync();
      print('Прочитан с диска файл ${file.lengthSync() ~/ 1024} килобайт');
      final sendData = TransferableTypedData.fromList([binaryData]);
      communicator.add(sendData);
      print('Отправлено в изолят ${binaryData.lengthInBytes ~/ 1024} килобайт');
      communicator.first.then((receiveData) {
        final binaryData = receiveData.materialize().asUint8List();
        print('Получено из изолята ${binaryData.lengthInBytes ~/ 1024} килобайт');
        communicator.close();
      });
    }, (error, stackTrace) {
      print('Top level exception: "$error"\n$stackTrace');
    });

void helloWorld(
  IsolateCommunicator<TransferableTypedData, TransferableTypedData> communicator,
  String text,
) {
  print('Initial argument: $text');
  communicator.listen((receiveData) {
    final binaryData = receiveData.materialize().asUint8List();
    print('В изоляте получено ${binaryData.lengthInBytes ~/ 1024} килобайт');
    communicator.add(TransferableTypedData.fromList([binaryData]));
    print('Отправлено назад');
  });
}
