import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum SyncStatus {
  synced,       // ✅ All changes synced to cloud
  pending,      // ⏱️ Changes waiting to sync
  syncing,      // 🔄 Currently syncing
  offline,      // 📵 No connectivity
  error,        // ❌ Sync failed
}

/// Service for managing sync status and connectivity
class SyncStatusService extends ChangeNotifier {
  SyncStatus _status = SyncStatus.synced;
  String? _errorMessage;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _hasConnectivity = true;

  SyncStatusService() {
    _initConnectivity();
  }

  SyncStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get hasConnectivity => _hasConnectivity;
  bool get canSync => _hasConnectivity && _status != SyncStatus.syncing;

  void _initConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasConnection = results.any((result) =>
      result != ConnectivityResult.none
      );

      if (hasConnection != _hasConnectivity) {
        _hasConnectivity = hasConnection;

        if (!hasConnection) {
          _updateStatus(SyncStatus.offline, null);
        } else if (_status == SyncStatus.offline) {
          // Connectivity restored
          _updateStatus(SyncStatus.pending, null);
        }

        notifyListeners();
      }
    });
  }

  void markPending() {
    if (_hasConnectivity) {
      _updateStatus(SyncStatus.pending, null);
    } else {
      _updateStatus(SyncStatus.offline, null);
    }
  }

  void markSyncing() {
    // Clear any error state when starting sync
    _updateStatus(SyncStatus.syncing, null);
  }

  void markSynced() {
    _updateStatus(SyncStatus.synced, null);
  }

  void markError(String error) {
    _updateStatus(SyncStatus.error, error);
  }

  void _updateStatus(SyncStatus newStatus, String? error) {
    _status = newStatus;
    _errorMessage = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}