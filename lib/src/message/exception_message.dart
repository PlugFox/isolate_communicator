import 'package:meta/meta.dart';

import 'communicator_message.dart';

/// Сообщение об исключении
@internal
class CommunicatorMessageException extends CommunicatorMessage with _CommunicatorMessageWithoutDataMixin {
  @override
  bool get hasError => true;

  @override
  final Object error;

  @override
  final String stackTrace;

  /// Сообщение об исключении
  const CommunicatorMessageException({
    required this.error,
    required this.stackTrace,
  });
}

/// Миксин отсутсвия данных в сообщении
mixin _CommunicatorMessageWithoutDataMixin on CommunicatorMessage {
  @override
  bool get hasData => false;

  @override
  Object? get data => null;
}
