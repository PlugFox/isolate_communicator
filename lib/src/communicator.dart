import 'dart:async';

import 'package:meta/meta.dart';

import 'communicator_impl.dart' as communicator;

/// Интерфейс коммуникации с изолятами
@experimental
abstract class IsolateCommunicator<Send extends Object?, Receive extends Object?> extends Stream<Receive>
    implements Sink<Send> {
  /// Создать новый изолят
  /// все ошибки из созданого изолята передаются в основной
  @experimental
  static Future<IsolateCommunicator<Send, Receive>>
      spawn<Send extends Object?, Receive extends Object?, Arg extends Object?>(
    void Function(IsolateCommunicator<Receive, Send> communicator, Arg arguments) entryPoint,
    Arg arguments,
  ) =>
          communicator.spawn<Send, Receive, Arg>(
            entryPoint,
            arguments,
          );

  /// Перманентно закрыт
  bool get isClosed;

  /// Доступен для прослушивания и отправки сообщений
  bool get isOpen;

  /// Замеряет скорость ответа от изолята
  Future<Duration> ping();
}
