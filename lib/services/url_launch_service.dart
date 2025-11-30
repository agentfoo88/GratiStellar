import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/error/url_exceptions.dart';

/// Service for launching URLs with comprehensive error handling
class UrlLaunchService {
  /// Launch a URL with proper error detection
  ///
  /// Returns true on success, throws UrlLaunchException on failure
  static Future<bool> launchUrlSafely(String urlString) async {
    final uri = Uri.parse(urlString);

    // 1. Check network connectivity first
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasConnection = connectivityResults.any(
      (result) => result != ConnectivityResult.none
    );

    if (!hasConnection) {
      throw NetworkException(urlString);
    }

    // 2. Validate URL scheme
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw UrlNotSupportedException(urlString);
    }

    // 3. Check if browser is available
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) {
      throw BrowserNotAvailableException(urlString);
    }

    // 4. Attempt to launch
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw UrlLaunchException('Failed to launch URL', urlString);
    }

    return true;
  }
}
