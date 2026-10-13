class AppFailure implements Exception {
  const AppFailure(this.message, {this.technicalMessage});

  final String message;
  final String? technicalMessage;
}
