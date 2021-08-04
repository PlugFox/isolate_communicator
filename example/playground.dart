void main() {
  const int value1 = 1;
  const double value2 = 1.0;
  final buffer = StringBuffer()
    ..writeln('Integer:')
    ..writeln(value1 is double)
    ..writeln(value1 is int)
    ..writeln(value1 is num)
    ..writeln()
    ..writeln('Real:')
    ..writeln(value2 is double)
    ..writeln(value2 is int)
    ..writeln(value2 is num)
    ..writeln()
    ..writeln('Equality:')
    ..writeln(value1 == value2)
    ..writeln(identical(value1, value2));
  print(buffer.toString());
}
