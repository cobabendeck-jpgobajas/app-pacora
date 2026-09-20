import 'package:connectivity_plus/connectivity_plus.dart';

/// Envuelve connectivity_plus para exponer un stream simple de
/// online/offline. Nota: connectivity_plus solo confirma que hay una
/// interfaz de red activa (wifi/datos), no que el backend sea alcanzable
/// -- por eso ApiClient.verificarConexion() hace ademas un GET /health
/// antes de intentar sincronizar la cola.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged.map(
        (results) => !results.contains(ConnectivityResult.none),
      );

  Future<bool> hayRed() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }
}
