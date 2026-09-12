sealed class Failure {
  const Failure();
}

class ServerFailure extends Failure {
  final String message;
  const ServerFailure({this.message = 'Server error occurred'});

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure();

  @override
  String toString() => 'No internet connection';
}

class CameraFailure extends Failure {
  final String message;
  const CameraFailure({this.message = 'Failed to access camera'});

  @override
  String toString() => message;
}

class AIProcessingFailure extends Failure {
  final String message;
  const AIProcessingFailure({this.message = 'AI failed to analyze the image'});

  @override
  String toString() => message;
}

class SensorFailure extends Failure {
  final String message;
  const SensorFailure({this.message = 'Pedometer sensor unavailable'});

  @override
  String toString() => message;
}
