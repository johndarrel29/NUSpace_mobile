import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/utils/internalserverdialog.dart';
import 'package:nuspace_app/widgets/snackbarhelper.dart';
import 'package:http/http.dart' as http;

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _internetChecker =
      InternetConnectionChecker.createInstance();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool wasOffline = false;
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Stream<bool> get connectionStream => _connectionController.stream;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late StreamSubscription<InternetConnectionStatus>
  _internetCheckerSubscription;

  ConnectivityService() {
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    _internetCheckerSubscription = _internetChecker.onStatusChange.listen(
      _updateInternetStatus,
    );
  }

  Future<void> _initConnectivity() async {
    try {
      List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      await _updateConnectionStatus(results, isStartup: true);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error initializing connectivity: $e");
        print(stackTrace);
      }
    }
  }

  Future<void> _updateConnectionStatus(
    List<ConnectivityResult> results, {
    bool isStartup = false,
  }) async {
    bool previousStatus = _isConnected;

    if (results.contains(ConnectivityResult.none)) {
      _isConnected = false;
    } else {
      _isConnected = await _internetChecker.hasConnection;
    }

    //only update UI if the connection status actually changes
    if (previousStatus != _isConnected) {
      _connectionController.add(_isConnected);
      print("Connected to $results");
      notifyListeners();

      if (!_isConnected) {
        wasOffline = true;
        SnackbarHelper.showConnectivityStatus(false);
      } else if (wasOffline) {
        wasOffline = false;
        SnackbarHelper.showConnectivityStatus(true);
      }
    }
  }

  void _updateInternetStatus(InternetConnectionStatus status) {
    bool hasInternet = (status == InternetConnectionStatus.connected);

    if (_isConnected != hasInternet) {
      _isConnected = hasInternet;
      _connectionController.add(hasInternet);
      print("Has $status");
      notifyListeners();

      if (!hasInternet) {
        wasOffline = true;
        SnackbarHelper.showConnectivityStatus(false);
      } else if (wasOffline) {
        wasOffline = false;
        SnackbarHelper.showConnectivityStatus(true);
      }
    }
  }

  //check if the server is reachable or else show internal server error screen
  Future<bool> checkServerHealth(
    BuildContext context,
    String? previousRoute,
  ) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrl}/api/health'))
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        _isConnected = true;
        return true;
      } else {
        throw Exception("Internal Server Error");
      }
    } on TimeoutException {
      print("Server timeout: Possibly no internet.");
      _isConnected = false;
      notifyListeners();

      //navigate to Internal Server error screen if the internet is available but server is down
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const InternalServerDialog(),
        );
      }
      return false;
    } catch (e) {
      print("Server is unreachable: $e");
      _isConnected = false;
      notifyListeners();

      //navigate to internal server error screen
      if (context.mounted) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const InternalServerDialog(),
          );
        }
      }

      return false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _internetCheckerSubscription.cancel();
    _connectionController.close();
    super.dispose();
  }
}
