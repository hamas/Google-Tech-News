/// A generic Result type representing either a Success or a Failure.
/// Using a sealed class for pattern matching exhaustiveness.
sealed class Result<T> {
  const Result();

  /// Returns true if the result is a success.
  bool get isSuccess => this is Success<T>;

  /// Returns true if the result is a failure.
  bool get isFailure => this is Failure<T>;

  /// Fold method to handle both cases.
  R fold<R>(
    R Function(Failure<T> failure) onFailure,
    R Function(T value) onSuccess,
  );
}

/// Represents a successful operation returning [value].
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  R fold<R>(
    R Function(Failure<T> failure) onFailure,
    R Function(T value) onSuccess,
  ) {
    return onSuccess(value);
  }
}

/// Represents a failed operation with a generic [error] and optional [stackTrace].
class Failure<T> extends Result<T> {
  final Object error;
  final StackTrace? stackTrace;

  const Failure(this.error, [this.stackTrace]);

  @override
  R fold<R>(
    R Function(Failure<T> failure) onFailure,
    R Function(T value) onSuccess,
  ) {
    return onFailure(this);
  }
}
