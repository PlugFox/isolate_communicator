import 'dart:isolate' show Capability, SendPort;

import 'package:meta/meta.dart';

import 'communicator_message.dart';

/// Код значащий о закрытии изолята
const Object? kIsolateExitCode = null;

/// Сервисное сообщение
@internal
abstract class CommunicatorMessageService extends CommunicatorMessage<Object?> implements Capability {
  /// Идентификатор сервисного сообщения
  final int id;

  @override
  bool get hasData => true;

  @override
  bool get hasError => false;

  @override
  Object? get error => null;

  @override
  String? get stackTrace => null;

  @override
  final Object? data;

  /// Сервисное сообщение
  const CommunicatorMessageService._(this.id, [this.data]);

  /// Сообщение о закрытии изолята
  /// Преобразуется из специального сигнала 'null'
  @literal
  const factory CommunicatorMessageService.exit() = _Exit;

  /// Завершение рукопожатия с отправкой порта назад
  const factory CommunicatorMessageService.handshake(SendPort sendPort) = _Handshake;

  /// Проверить доступность изолята
  @literal
  const factory CommunicatorMessageService.ping() = _Ping;

  /// Ответить на запрос доступности изолята
  @literal
  const factory CommunicatorMessageService.pong() = _Pong;

  /// Коллбэк на основании текущего типа
  ServiceResult when<ServiceResult extends Object?>({
    required ServiceResult Function() exit,
    required ServiceResult Function() handshake,
    required ServiceResult Function() ping,
    required ServiceResult Function() pong,
  });

  /// Коллбэк на основании текущего типа
  /// c фоллбэк функцией
  ServiceResult maybeWhen<ServiceResult extends Object?>({
    required ServiceResult Function() orElse,
    ServiceResult Function()? exit,
    ServiceResult Function()? handshake,
    ServiceResult Function()? ping,
    ServiceResult Function()? pong,
  }) =>
      when(
        exit: exit ?? orElse,
        handshake: handshake ?? orElse,
        ping: ping ?? orElse,
        pong: pong ?? orElse,
      );

  @override
  bool operator ==(Object other) => identical(other, this) && other is CommunicatorMessageService && other.id == id;

  @override
  int get hashCode => id;
}

class _Exit extends CommunicatorMessageService {
  const _Exit() : super._(-1);

  @override
  ServiceResult when<ServiceResult extends Object?>({
    required ServiceResult Function() exit,
    required ServiceResult Function() handshake,
    required ServiceResult Function() ping,
    required ServiceResult Function() pong,
  }) =>
      exit();
}

class _Handshake extends CommunicatorMessageService {
  const _Handshake(SendPort sendPort) : super._(0, sendPort);

  @override
  ServiceResult when<ServiceResult extends Object?>({
    required ServiceResult Function() exit,
    required ServiceResult Function() handshake,
    required ServiceResult Function() ping,
    required ServiceResult Function() pong,
  }) =>
      handshake();
}

class _Ping extends CommunicatorMessageService {
  const _Ping() : super._(1);

  @override
  ServiceResult when<ServiceResult extends Object?>({
    required ServiceResult Function() exit,
    required ServiceResult Function() handshake,
    required ServiceResult Function() ping,
    required ServiceResult Function() pong,
  }) =>
      ping();
}

class _Pong extends CommunicatorMessageService {
  const _Pong() : super._(2);

  @override
  ServiceResult when<ServiceResult extends Object?>({
    required ServiceResult Function() exit,
    required ServiceResult Function() handshake,
    required ServiceResult Function() ping,
    required ServiceResult Function() pong,
  }) =>
      pong();
}
