import 'package:flutter/foundation.dart';

mixin ViewModelMixin on ChangeNotifier {

  final Map<int, bool> _busyStates = <int, bool>{};
  final Map<int, dynamic> _errorStates = <int, dynamic>{};

  bool _disposed = false;
  bool get disposed => _disposed;

  /// Returns the busy status for an object if it exists. Returns false if not present
  bool busy(Object? object) => _busyStates[object.hashCode] ?? false;

  dynamic error(Object object) => _errorStates[object.hashCode];

  /// Returns the busy status of the ViewModel
  bool get isBusy => busy(this);

  bool get isAnyBusy => _busyStates.values.any((busy) => busy);

  /// Returns the error status of the ViewModel
  bool get hasError => error(this) != null;
  bool get hasAnyError => _errorStates.values.where((it) => it != null).isNotEmpty;

  /// Returns the error status of the ViewModel
  dynamic get modelError => error(this);

  /// Marks the ViewModel as busy and calls notify listeners
  void setBusy(bool value) {
    setBusyForObject(this, value);
  }

  /// Sets the error for the ViewModel
  void setError(dynamic error) {
    setErrorForObject(this, error);
  }

  /// Returns a boolean that indicates if the ViewModel has an error for the key
  bool hasErrorForKey(Object key) => error(key) != null;

  /// Clears all the errors
  void clearErrors() {
    _errorStates.clear();
  }

  /// Sets the busy state for the object equal to the value passed in and notifies Listeners
  /// If you're using a primitive type the value SHOULD NOT BE CHANGED, since Hashcode uses == value
  void setBusyForObject(Object? object, bool value) {
    _busyStates[object.hashCode] = value;
    notifyListeners();
  }

  /// Sets the error state for the object equal to the value passed in and notifies Listeners
  /// If you're using a primitive type the value SHOULD NOT BE CHANGED, since Hashcode uses == value
  void setErrorForObject(Object object, dynamic value) {
    _errorStates[object.hashCode] = value;
    notifyListeners();
  }

  /// Function that is called when a future throws an error
  void onFutureError(dynamic error, Object? key) {}

  /// Sets the ViewModel to busy, runs the future and then sets it to not busy when complete.
  ///
  /// rethrows [Exception] after setting busy to false for object or class
  Future<T> runBusyFuture<T>(Future<T> busyFuture,
      {Object? key, Object? busyObject, bool hideException = false}) async {
    _setBusyForModelOrObject(true, key: key);
    try {
      return await runErrorFuture(busyFuture, key: key ?? busyObject, hideException: hideException);
    } catch (e) {
      if (!hideException) {
        rethrow;
      }
      return Future.value();
    } finally {
      _setBusyForModelOrObject(false, key: key);
    }
  }

  Future<T> runErrorFuture<T>(Future<T> future, {Object? key, bool hideException = false}) async {
    try {
      _setErrorForModelOrObject(null, key: key);
      return await future;
    } catch (e, st) {
      _setErrorForModelOrObject(e, key: key);
      onFutureError(e, key);
      if (!hideException) {
        rethrow;
      }
      return Future.value();
    }
  }

  void _setBusyForModelOrObject(bool value, {Object? key}) {
    if (key != null) {
      setBusyForObject(key, value);
    } else {
      setBusyForObject(this, value);
    }
  }

  void _setErrorForModelOrObject(dynamic value, {Object? key}) {
    if (key != null) {
      setErrorForObject(key, value);
    } else {
      setErrorForObject(this, value);
    }
  }

  @override
  void notifyListeners() {
    if (!disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}