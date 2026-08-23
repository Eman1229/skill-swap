import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _init();
  }

  bool _isOffline = false;
  bool get isOffline => _isOffline;
  bool get isOnline  => !_isOffline;

  StreamSubscription? _subscription;

  void _init() {
    // Check once on startup
    _checkNow();
    // Then listen for changes
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_onChanged);
  }

  Future<void> _checkNow() async {
    final results = await Connectivity().checkConnectivity();
    _onChanged(results);
  }

  void _onChanged(List<ConnectivityResult> results) {
    if (kIsWeb) {
      if (_isOffline) {
        _isOffline = false;
        notifyListeners();
      }
      return;
    }

    // Offline ONLY when the OS reports zero network interfaces
    // WiFi, mobile, ethernet, vpn — any of these = keep running
    final hasAnyNetwork = results.any((r) =>
    r == ConnectivityResult.mobile   ||
        r == ConnectivityResult.wifi     ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn      ||
        r == ConnectivityResult.other);

    final nowOffline = !hasAnyNetwork;

    if (_isOffline != nowOffline) {
      _isOffline = nowOffline;
      debugPrint('ConnectivityService: ${_isOffline ? "OFFLINE" : "ONLINE"}');
      notifyListeners();
    }
  }

  Future<void> retryConnection() async => _checkNow();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}