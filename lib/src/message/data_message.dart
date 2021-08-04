import 'package:meta/meta.dart';

import 'communicator_message.dart';

/// Сообщение с данными
@internal
class CommunicatorMessageData<T extends Object?> extends CommunicatorMessage<T>
    with _CommunicatorMessageWithoutErrorMixin<T> {
  @override
  bool get hasData => data != null;

  @override
  final T? data;

  /// Сообщение об исключении
  const CommunicatorMessageData({this.data});
}

/// Миксин отсутсвия ошибок в сообщении
mixin _CommunicatorMessageWithoutErrorMixin<T extends Object?> on CommunicatorMessage<T> {
  @override
  bool get hasError => false;

  @override
  Object? get error => null;

  @override
  String? get stackTrace => null;
}
