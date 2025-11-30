/// Base exception for URL launching failures
class UrlLaunchException implements Exception {
  final String message;
  final String url;

  UrlLaunchException(this.message, this.url);

  @override
  String toString() => 'UrlLaunchException: $message (URL: $url)';
}

/// Browser app not available on device
class BrowserNotAvailableException extends UrlLaunchException {
  BrowserNotAvailableException(String url)
      : super('No browser application available', url);
}

/// URL scheme not supported
class UrlNotSupportedException extends UrlLaunchException {
  UrlNotSupportedException(String url)
      : super('URL scheme not supported', url);
}

/// Network connectivity issue
class NetworkException extends UrlLaunchException {
  NetworkException(String url)
      : super('Network connection unavailable', url);
}
