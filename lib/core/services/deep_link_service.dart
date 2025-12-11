import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  Stream<Uri> get linkStream => _appLinks.uriLinkStream;

  Future<Uri?> getInitialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (e) {
      debugPrint('[DeepLink] Error getting initial link: $e');
      return null;
    }
  }

  Future<Uri?> getLatestLink() async {
    try {
      return await _appLinks.getLatestLink();
    } catch (e) {
      debugPrint('[DeepLink] Error getting latest link: $e');
      return null;
    }
  }
}
