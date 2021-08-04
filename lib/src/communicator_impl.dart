import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import 'communicator.dart';
import 'message.dart';
import 'message_transformer.dart';

abstract class _MessageIsolateCommunicator<Send extends Object?, Receive extends Object?>
    extends IsolateCommunicator<Send, Receive> {
  /// Перманентно закрыт
  @override
  @nonVirtual
  bool isClosed = false;

  /// Доступен для прослушивания и отправки сообщений
  @override
  @nonVirtual
  bool get isOpen => !isClosed;

  /// Порт для отправки в другой изолят
  @nonVirtual
  @protected
  final SendPort sendPort;

  /// Порт через который мы слушаем сообщения от другого изолята
  @nonVirtual
  @protected
  final ReceivePort receivePort;

  /// Широковещательный поток сообщений из другого изолята
  /// По умолчанию подписка на изолят не прерывается при ошибке
  @nonVirtual
  @protected
  final Stream<Receive> receiveStream;

  /// Широковещательный поток сервисных сообщений из другого изолята
  /// По умолчанию подписка на изолят не прерывается при ошибке
  @nonVirtual
  @protected
  final Stream<CommunicatorMessageService> serviceStream;

  /// Ссылка на изолят
  /// Для родительского это будет ссылка на дочерний (который создаем)
  /// Для дочернего - ссылка на себя
  @nonVirtual
  @protected
  final Isolate isolate;

  /// Используется для подписки служебными событиями
  @protected
  StreamSubscription<CommunicatorMessageService>? _serviceStreamSub;

  _MessageIsolateCommunicator._({
    required this.sendPort,
    required this.receivePort,
    required this.receiveStream,
    required this.serviceStream,
    required this.isolate,
  }) {
    _serviceStreamSub = serviceStream.listen(
      (event) => event.maybeWhen(
        exit: close,
        ping: () => sendPort.send(const CommunicatorMessageService.pong()),
        orElse: () => null,
      ),
    );
  }

  @override
  @mustCallSuper
  void close() {
    sendPort.send(kIsolateExitCode);
    isClosed = true;
    _serviceStreamSub?.cancel();
    receivePort.close();
    //scheduleMicrotask(isolate.kill); // В этом не должно быть необходимости
  }
}

/// Объект в исходном изоляте для общения с создаваемым
class _MessageIsolateCommunicatorParent<Send extends Object?, Receive extends Object?>
    extends _MessageIsolateCommunicator<Send, Receive>
    with
        _MessageSenderMixin<Send, Receive>,
        _MessageReceiverMixin<Send, Receive>,
        _MessageCompletionMixin<Send, Receive>,
        _PingPongMixin<Send, Receive> {
  _MessageIsolateCommunicatorParent({
    required SendPort sendToChildPort,
    required ReceivePort receiveFromChildPort,
    required Stream<Receive> receiveFromChildStream,
    required Stream<CommunicatorMessageService> serviceFromChildStream,
    required Isolate childIsolate,
  }) : super._(
          sendPort: sendToChildPort,
          receivePort: receiveFromChildPort,
          receiveStream: receiveFromChildStream,
          serviceStream: serviceFromChildStream,
          isolate: childIsolate,
        );
}

/// Объект для созданого изолята для общения с исходным
class _IsolateCommunicatorChild<Send extends Object?, Receive extends Object?>
    extends _MessageIsolateCommunicator<Send, Receive>
    with
        _MessageSenderMixin<Send, Receive>,
        _MessageReceiverMixin<Send, Receive>,
        _MessageCompletionMixin<Send, Receive>,
        _PingPongMixin<Send, Receive> {
  _IsolateCommunicatorChild({
    required SendPort sendToParentPort,
    required ReceivePort receiveFromParentPort,
    required Stream<Receive> receiveFromParentStream,
    required Stream<CommunicatorMessageService> serviceFromChildStream,
    required Isolate thisIsolate,
  }) : super._(
          sendPort: sendToParentPort,
          receivePort: receiveFromParentPort,
          receiveStream: receiveFromParentStream,
          serviceStream: serviceFromChildStream,
          isolate: thisIsolate,
        );
}

mixin _MessageSenderMixin<Send extends Object?, Receive extends Object?> on _MessageIsolateCommunicator<Send, Receive> {
  @override
  void add(Send data) {
    if (isClosed) return;
    data is TransferableTypedData
        ? super.sendPort.send(data)
        : super.sendPort.send(CommunicatorMessageData<Send>(data: data));
  }
}

mixin _PingPongMixin<Send extends Object?, Receive extends Object?> on _MessageIsolateCommunicator<Send, Receive> {
  @override
  Future<Duration> ping() async {
    if (isClosed) return Future<Duration>.value(Duration.zero);
    super.sendPort.send(const CommunicatorMessageService.ping());
    final stopwatch = Stopwatch()..start();
    return super
        .serviceStream
        .firstWhere(
          (element) => element.maybeWhen(
            pong: () => true,
            orElse: () => false,
          ),
        )
        .then((_) => (stopwatch..stop()).elapsed)
        .timeout(const Duration(milliseconds: 15000));
  }
}

mixin _MessageReceiverMixin<Send extends Object?, Receive extends Object?>
    on _MessageIsolateCommunicator<Send, Receive> {
  @override
  StreamSubscription<Receive> listen(
    void Function(Receive event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError = false,
  }) =>
      super.receiveStream.listen(
            onData,
            onError: onError,
            onDone: onDone,
            cancelOnError: cancelOnError,
          );
}

mixin _MessageCompletionMixin<Send extends Object?, Receive extends Object?>
    on _MessageIsolateCommunicator<Send, Receive> {
  /// Если вызвано в родительском изоляте - закрывает дочерний
  /// Если вызвано в дочернем изоляте - закрывает себя
  @override
  void close() {
    super.close();
  }
}

/// Класс с которым инициализируется изолят
@immutable
class _WorkerPayload<Send extends Object?, Receive extends Object?, Arg extends Object?> {
  final SendPort sendPort;

  final void Function(
    IsolateCommunicator<Send, Receive> communicator,
    Arg arguments,
  ) entryPoint;

  final Arg arguments;

  _IsolateCommunicatorChild<Send, Receive> call({
    required ReceivePort receiveFromParentPort,
  }) {
    Isolate.current.addOnExitListener(
      sendPort,
      response: kIsolateExitCode, // Отправляем kIsolateExitCode при закрытии изолята
    );
    final receiveFromParentStream = receiveFromParentPort.asBroadcastStream();
    // ignore: close_sinks
    final communicator = _IsolateCommunicatorChild<Send, Receive>(
      sendToParentPort: sendPort,
      receiveFromParentPort: receiveFromParentPort,
      thisIsolate: Isolate.current,
      receiveFromParentStream: receiveFromParentStream.communicatorMessageTransformer<Receive>(),
      serviceFromChildStream: receiveFromParentStream.communicatorMessageTransformer<CommunicatorMessageService>(
        serviceMode: true,
        receiveDataMessages: true,
        receiveErrorMessages: false,
      ),
    );
    entryPoint(
      communicator,
      arguments,
    );
    return communicator;
  }

  const _WorkerPayload({
    required this.sendPort,
    required this.entryPoint,
    required this.arguments,
  });
}

/// Создать новый изолят
/// все ошибки из созданого изолята передаются в основной
@internal
Future<IsolateCommunicator<Send, Receive>> spawn<Send extends Object?, Receive extends Object?, Arg extends Object?>(
  void Function(
    IsolateCommunicator<Receive, Send> communicator,
    Arg arguments,
  )
      entryPoint,
  Arg arguments,
) async {
  try {
    final receiveFromIsolatePort = ReceivePort();
    final receiveFromChildStream = receiveFromIsolatePort.asBroadcastStream();
    final sendToIsolateFuture = receiveFromChildStream
        .communicatorMessageTransformer<CommunicatorMessageService>(
          serviceMode: true,
          receiveDataMessages: true,
          receiveErrorMessages: false,
        )
        .where((event) => event.maybeWhen<bool>(orElse: () => false, handshake: () => true))
        .map<SendPort>((event) => event.data as SendPort)
        .first
        .timeout(const Duration(milliseconds: 15000));
    final childIsolate = await Isolate.spawn<_WorkerPayload>(
      _worker,
      _WorkerPayload<Receive, Send, Arg>(
        sendPort: receiveFromIsolatePort.sendPort,
        entryPoint: entryPoint,
        arguments: arguments,
      ),
    ).timeout(const Duration(milliseconds: 15000));
    final sendToIsolate = await sendToIsolateFuture;
    return _MessageIsolateCommunicatorParent<Send, Receive>(
      sendToChildPort: sendToIsolate,
      receiveFromChildPort: receiveFromIsolatePort,
      childIsolate: childIsolate,
      receiveFromChildStream: receiveFromChildStream.communicatorMessageTransformer<Receive>(),
      serviceFromChildStream: receiveFromChildStream.communicatorMessageTransformer<CommunicatorMessageService>(
        serviceMode: true,
        receiveDataMessages: true,
        receiveErrorMessages: false,
      ),
    );
  } on TimeoutException {
    rethrow;
  } on Object {
    rethrow;
  }
}

void _worker(_WorkerPayload workerPayload) => runZonedGuarded(
      () {
        final receiveFromParentPort = ReceivePort();
        workerPayload.sendPort.send(
          CommunicatorMessageService.handshake(receiveFromParentPort.sendPort),
        );
        workerPayload(
          receiveFromParentPort: receiveFromParentPort,
        );
      },
      (error, stackTrace) => workerPayload.sendPort.send(
        CommunicatorMessageException(
          error: error,
          stackTrace: stackTrace.toString(),
        ),
      ),
    );
