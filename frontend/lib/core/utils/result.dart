class Result<T> {
  final T? data;
  final String? error;

  const Result._({this.data, this.error});

  bool get isSuccess => error == null;

  factory Result.success(T data) => Result._(data: data);

  factory Result.failure(String error) => Result._(error: error);
}
