import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';

class DeepLinkService {
  static DeepLinkService? _instance;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final StreamController<Uri> _pendingLinkController = StreamController<Uri>.broadcast();
  bool _initialized = false;

  DeepLinkService._();

  static DeepLinkService get instance {
    _instance ??= DeepLinkService._();
    return _instance!;
  }

  Stream<Uri> get pendingLinks => _pendingLinkController.stream;

  Future<void> initialize(BuildContext? context) async {
    if (_initialized) return;
    _initialized = true;

    _appLinks = AppLinks();

    if (!kIsWeb) {
      try {
        final initialLink = await _appLinks.getInitialLink();
        if (initialLink != null) {
          _handleLink(initialLink);
        }

        _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) => _handleLink(uri),
          onError: (error) {
            debugPrint('DeepLink error: $error');
          },
        );
      } catch (e) {
        debugPrint('DeepLink init error: $e');
      }
    }
  }

  void _handleLink(Uri uri) {
    debugPrint('DeepLink received: $uri');
    _pendingLinkController.add(uri);
  }

  Uri? parseScannedQrData(String rawData) {
    try {
      final trimmed = rawData.trim();

      if (trimmed.startsWith('partnerledger://')) {
        return Uri.parse(trimmed);
      }

      if (trimmed.startsWith('{')) {
        final decoded = Uri(
          scheme: AppConfig.instance.deepLinkScheme,
          host: 'invite',
          queryParameters: Map<String, String>.from(
            Uri.decodeComponent(trimmed) as Map<String, String>,
          ),
        );
        return decoded;
      }

      final parts = trimmed.split('|');
      if (parts.length >= 2) {
        return Uri(
          scheme: AppConfig.instance.deepLinkScheme,
          host: 'invite',
          queryParameters: {
            'businessId': parts[0],
            'token': parts[1],
          },
        );
      }

      return Uri(
        scheme: AppConfig.instance.deepLinkScheme,
        host: 'invite',
        queryParameters: {'token': trimmed},
      );
    } catch (e) {
      debugPrint('QR parse error: $e');
      return null;
    }
  }

  Map<String, String>? extractInviteParams(Uri uri) {
    if (uri.host == 'invite' || uri.pathSegments.contains('invite')) {
      return {
        'businessId': uri.queryParameters['businessId'] ?? '',
        'token': uri.queryParameters['token'] ?? '',
      };
    }

    if (uri.pathSegments.length >= 2 &&
        uri.pathSegments[uri.pathSegments.length - 2] == 'invite') {
      return {
        'businessId': uri.pathSegments[uri.pathSegments.length - 1],
        'token': uri.queryParameters['token'] ?? '',
      };
    }

    return null;
  }

  void navigateToInvite(BuildContext context, Uri link) {
    final params = extractInviteParams(link);
    if (params != null) {
      final token = params['token'];
      final businessId = params['businessId'];
      if (token != null && token.isNotEmpty) {
        context.push('/invite/accept?token=$token&businessId=$businessId');
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _pendingLinkController.close();
    _initialized = false;
  }
}

String buildQrPayload({
  required String businessId,
  required String token,
}) {
  final scheme = AppConfig.instance.deepLinkScheme;
  return '$scheme://invite?businessId=$businessId&token=$token';
}

Uri buildDeepLinkUri({
  required String businessId,
  required String token,
}) {
  final scheme = AppConfig.instance.deepLinkScheme;
  return Uri(
    scheme: scheme,
    host: 'invite',
    queryParameters: {
      'businessId': businessId,
      'token': token,
    },
  );
}
