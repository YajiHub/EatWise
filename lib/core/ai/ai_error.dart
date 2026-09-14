class RateLimitedException implements Exception {
  final String providerName;
  const RateLimitedException(this.providerName);
  @override
  String toString() => '$providerName is rate-limited. Trying next provider...';
}

class AiAuthException implements Exception {
  final String providerName;
  const AiAuthException(this.providerName);
  @override
  String toString() => '$providerName API key is invalid.';
}

class AiNetworkException implements Exception {
  final String providerName;
  const AiNetworkException(this.providerName);
  @override
  String toString() => '$providerName network error.';
}

class AiContentFilteredException implements Exception {
  final String providerName;
  const AiContentFilteredException(this.providerName);
  @override
  String toString() => '$providerName refused the content.';
}

class AllProvidersExhaustedException implements Exception {
  final String capability;
  const AllProvidersExhaustedException(this.capability);
  @override
  String toString() => 'All $capability providers are currently unavailable. Try again later.';
}

class AiModelUnavailableException implements Exception {
  final String providerName;
  final String message;
  const AiModelUnavailableException(this.providerName, [this.message = 'Model unavailable']);
  @override
  String toString() => '$providerName: $message';
}
