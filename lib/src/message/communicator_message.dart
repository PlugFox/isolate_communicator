import 'package:meta/meta.dart';

/// Описание сообщения передаваемого между изолятами
@immutable
@internal
abstract class CommunicatorMessage<T extends Object?> {
  /// Есть данные
  bool get hasData;

  /// Содержит ошибку
  bool get hasError;

  /// Данные
  T? get data;

  /// Ошибка
  Object? get error;

  /// Стектрейс
  String? get stackTrace;

  /// Описание сообщения передаваемого между изолятами
  const CommunicatorMessage();
}
