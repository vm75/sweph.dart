// ignore_for_file: hash_and_equals, constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'ffi_proxy.dart';

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

extension FfiHelperOnDoubleList on List<double> {
  Pointer<Double> toNativeString(Arena arena) {
    final array = arena<Double>(length);
    for (int i = 0; i < length; i++) {
      array[i] = elementAt(i);
    }
    return array;
  }
}

extension FfiHelperOnDoublePointer on Pointer<Double> {
  List<double> toList(int length) {
    final list = <double>[];
    list.addAll(asTypedList(length));
    return list;
  }
}

extension FfiHelperOnBool on bool {
  int get value {
    return this ? 1 : 0;
  }
}

/// Runs [computation] with a new [Arena], and releases all allocations at the
/// end.
///
/// If the return value of [computation] is a [Future], all allocations are
/// released when the future completes.
///
/// If the isolate is shut down, through `Isolate.kill()`, resources are _not_
/// cleaned up.
R using<R>(R Function(Arena) computation, Allocator wrappedAllocator) {
  final arena = Arena(wrappedAllocator);
  bool isAsync = false;
  try {
    final result = computation(arena);
    if (result is Future) {
      isAsync = true;
      return (result.whenComplete(arena.releaseAll) as R);
    }
    return result;
  } finally {
    if (!isAsync) {
      arena.releaseAll();
    }
  }
}

/// Extension method for converting a`Pointer<Uint8>` to a [String].
extension Utf8Pointer on Pointer<Uint8> {
  /// The number of UTF-8 code units in this zero-terminated UTF-8 string.
  ///
  /// The UTF-8 code units of the strings are the non-zero code units up to the
  /// first zero code unit.
  int get length {
    _ensureNotNullptr('length');
    final codeUnits = cast<Uint8>();
    return _length(codeUnits);
  }

  /// Converts this UTF-8 encoded string to a Dart string.
  String toDartString({int? length}) {
    _ensureNotNullptr('toDartString');
    final codeUnits = cast<Uint8>();
    if (length != null) {
      RangeError.checkNotNegative(length, 'length');
    } else {
      length = _length(codeUnits);
    }
    return utf8.decode(codeUnits.asTypedList(length));
  }

  static int _length(Pointer<Uint8> codeUnits) {
    var length = 0;
    while (codeUnits[length] != 0) {
      length++;
    }
    return length;
  }

  void _ensureNotNullptr(String operation) {
    if (this == nullptr) {
      throw UnsupportedError(
          "Operation '$operation' not allowed on a 'nullptr'.");
    }
  }
}

/// Extension method for converting a [String] to a `Pointer<Uint8>`.
extension StringUtf8Pointer on String {
  /// Creates a zero-terminated [Uint8] code-unit array from this String.
  Pointer<Uint8> toNativeString(Allocator allocator, [int? size]) {
    final units = utf8.encode(this);
    size ??= units.length + 1;
    final Pointer<Uint8> result = allocator<Uint8>(size);
    final Uint8List nativeString = result.asTypedList(size);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    return result.cast();
  }

  int firstChar() {
    return (length > 0) ? codeUnitAt(0) : 0;
  }
}

/// An [Allocator] which frees all allocations at the same time.
///
/// The arena allows you to allocate heap memory, but ignores calls to [free].
/// Instead you call [releaseAll] to release all the allocations at the same
/// time.
///
/// Also allows other resources to be associated with the arena, through the
/// [using] method, to have a release function called for them when the arena
/// is released.
///
/// An [Allocator] can be provided to do the actual allocation and freeing.
/// Defaults to using [calloc].
class Arena implements Allocator {
  /// The [Allocator] used for allocation and freeing.
  final Allocator _wrappedAllocator;

  /// Native memory under management by this [Arena].
  final List<Pointer<NativeType>> _managedMemoryPointers = [];

  /// Callbacks for releasing native resources under management by this [Arena].
  final List<void Function()> _managedResourceReleaseCallbacks = [];

  bool _inUse = true;

  /// Creates a arena of allocations.
  ///
  /// The [allocator] is used to do the actual allocation and freeing of
  /// memory. It defaults to using [calloc].
  Arena(Allocator allocator) : _wrappedAllocator = allocator;

  /// Allocates memory and includes it in the arena.
  ///
  /// Uses the allocator provided to the [Arena] constructor to do the
  /// allocation.
  ///
  /// Throws an [ArgumentError] if the number of bytes or alignment cannot be
  /// satisfied.
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    _ensureInUse();
    final p = _wrappedAllocator.allocate<T>(byteCount, alignment: alignment);
    _managedMemoryPointers.add(p);
    return p;
  }

  /// Registers [resource] in this arena.
  ///
  /// Executes [releaseCallback] on [releaseAll].
  ///
  /// Returns [resource] again, to allow for easily inserting
  /// `arena.using(resource, ...)` where the resource is allocated.
  T using<T>(T resource, void Function(T) releaseCallback) {
    _ensureInUse();
    // releaseCallback = Zone.current.bindUnaryCallback(releaseCallback);
    _managedResourceReleaseCallbacks.add(() => releaseCallback(resource));
    return resource;
  }

  /// Registers [releaseResourceCallback] to be executed on [releaseAll].
  void onReleaseAll(void Function() releaseResourceCallback) {
    _managedResourceReleaseCallbacks.add(releaseResourceCallback);
  }

  /// Releases all resources that this [Arena] manages.
  ///
  /// If [reuse] is `true`, the arena can be used again after resources
  /// have been released. If not, the default, then the [allocate]
  /// and [using] methods must not be called after a call to `releaseAll`.
  ///
  /// If any of the callbacks throw, [releaseAll] is interrupted, and should
  /// be started again.
  void releaseAll({bool reuse = false}) {
    if (!reuse) {
      _inUse = false;
    }
    // The code below is deliberately wirtten to allow allocations to happen
    // during `releaseAll(reuse:true)`. The arena will still be guaranteed
    // empty when the `releaseAll` call returns.
    while (_managedResourceReleaseCallbacks.isNotEmpty) {
      _managedResourceReleaseCallbacks.removeLast()();
    }
    for (final p in _managedMemoryPointers) {
      _wrappedAllocator.free(p);
    }
    _managedMemoryPointers.clear();
  }

  /// Does nothing, invoke [releaseAll] instead.
  @override
  void free(Pointer<NativeType> pointer) {}

  void _ensureInUse() {
    if (!_inUse) {
      throw StateError(
          'Arena no longer in use, `releaseAll(reuse: false)` was called.');
    }
  }
}
