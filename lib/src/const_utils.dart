// ignore_for_file: hash_and_equals

N valueOf<T, N extends num>(dynamic val) {
  if (val is N) {
    return val;
  }
  if (val is AbstractVal<T, N>) {
    return val.value;
  }
  throw Exception('Invalid value');
}

abstract class AbstractVal<T, N extends num> {
  final N value;
  const AbstractVal(this.value);

  T create(N value);

  N _valueOf(dynamic other) {
    if (other is N) {
      return other;
    } else if (other is AbstractVal<T, N>) {
      return other.value;
    }
    throw Exception('Invalid value');
  }

  @override
  bool operator ==(dynamic other) {
    return value == _valueOf(other);
  }
}

abstract class AbstractEnum<T> extends AbstractVal<T, int> {
  const AbstractEnum(int value) : super(value);
}

abstract class AbstractConst<T, N extends num> extends AbstractVal<T, N> {
  const AbstractConst(N value) : super(value);

  T operator +(dynamic other) {
    return create((value + _valueOf(other)) as N);
  }

  T operator -(dynamic other) {
    return create((value + _valueOf(other)) as N);
  }

  T operator *(dynamic other) {
    return create((value * _valueOf(other)) as N);
  }

  T operator /(dynamic other) {
    return create((value / _valueOf(other)) as N);
  }
}

abstract class AbstractFlag<T> extends AbstractVal<T, int> {
  const AbstractFlag(int value) : super(value);

  T operator |(dynamic other) {
    return create(value | _valueOf(other));
  }

  T operator &(dynamic other) {
    return create(value & _valueOf(other));
  }
}
