import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import 'message.dart';

/// Преобразование CommunicatorMessage в сообщение и ошибки
@immutable
class CommunicatorMessageTransformer<T> extends StreamTransformerBase<Object?, T> {
  /// Режим получения только вспомогательных данных
  final bool serviceMode;

  /// Передавать дальше сообщения с данными
  final bool receiveDataMessages;

  /// Передавать дальше сообщения с ошибками
  final bool receiveErrorMessages;

  /// Преобразование CommunicatorMessage в сообщение и ошибки
  const CommunicatorMessageTransformer({
    this.serviceMode = false,
    this.receiveDataMessages = true,
    this.receiveErrorMessages = true,
  });

  @override
  Stream<T> bind(Stream<Object?> stream) {
    StreamSubscription<Object?>? sub;
    final sc = StreamController<T>(
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () => sub?.cancel(),
      sync: false,
    );
    sub = stream.listen(
      (value) {
        if (value is TransferableTypedData && value is T) {
          // Сразу помещаем TransferableTypedData и завершаем итерацию
          sc.add(value as T);
          return;
        } else if (value is! CommunicatorMessage) {
          if (value == kIsolateExitCode) {
            // Это особый сигнал о закрытии либо изолята,
            // либо соединения с изолятом.
            // Преобразуем сигнал в сервисное сообщение,
            // отправляем его дальше,
            // затем закрываем все подписки
            if (serviceMode) {
              sc.add(const CommunicatorMessageService.exit() as T);
            }
            sc.close();
            sub?.cancel();
          }
          return;
        }
        if (receiveErrorMessages && value.hasError) {
          final error = value.error;
          if (error != null) sc.addError(value.error!, StackTrace.fromString(value.stackTrace!));
        }
        if (receiveDataMessages && value.hasData) {
          if (value is T) {
            // Помещаем CommunicatorMessageService
            sc.add(value as T);
          } else {
            // Помещаем передаваемые данные
            final data = value.data;
            if (data is T) sc.add(data);
          }
        }
      },
      onDone: sc.close,
      onError: sc.addError,
      cancelOnError: false,
    );
    return stream.isBroadcast ? sc.stream.asBroadcastStream() : sc.stream;
  }
}

/// sourceStream.communicatorMessageTransformer<T>()
extension CommunicatorMessageTransformerExtensions on Stream<Object?> {
  /// Преобразование CommunicatorMessage в сообщение и ошибки
  Stream<T> communicatorMessageTransformer<T extends Object?>({
    bool serviceMode = false,
    bool receiveDataMessages = true,
    bool receiveErrorMessages = true,
  }) =>
      transform<T>(
        CommunicatorMessageTransformer<T>(
          serviceMode: serviceMode,
          receiveDataMessages: receiveDataMessages,
          receiveErrorMessages: receiveErrorMessages,
        ),
      );
}
