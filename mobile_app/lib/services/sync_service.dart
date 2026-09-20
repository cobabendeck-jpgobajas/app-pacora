import 'dart:io';

import '../models/muestra.dart';
import 'api_client.dart';
import 'database_service.dart';

/// Procesa la cola offline: toma las muestras capturadas que aun no se
/// han enviado (o que fallaron) y las envia al backend en orden, una por
/// una, actualizando su estado en la base local a medida que avanza.
///
/// Se usa tanto al recuperar conectividad (ver HomeScreen) como con un
/// boton manual de "Sincronizar ahora", para que el operario no dependa
/// solo de la deteccion automatica.
class SyncService {
  final ApiClient _api;
  final DatabaseService _db;
  bool _sincronizando = false;

  SyncService({ApiClient? api, DatabaseService? db})
      : _api = api ?? ApiClient(),
        _db = db ?? DatabaseService.instance;

  bool get sincronizando => _sincronizando;

  /// Devuelve cuantas muestras se enviaron con exito en esta corrida.
  Future<int> sincronizarPendientes({
    void Function(Muestra actualizada)? onProgreso,
  }) async {
    if (_sincronizando) return 0;
    _sincronizando = true;
    var enviadas = 0;

    try {
      final conectado = await _api.verificarConexion();
      if (!conectado) return 0;

      final pendientes = await _db.listPendientes();
      for (final muestra in pendientes) {
        final enviando = muestra.copyWith(estado: EstadoMuestra.enviando);
        await _db.update(enviando);
        onProgreso?.call(enviando);

        try {
          final archivo = File(muestra.imagePath);
          if (!await archivo.exists()) {
            final fallo = muestra.copyWith(
              estado: EstadoMuestra.error,
              errorMsg: 'La foto ya no esta disponible en el dispositivo.',
            );
            await _db.update(fallo);
            onProgreso?.call(fallo);
            continue;
          }

          final resultado = await _api.predecir(archivo);
          final actualizada = muestra.copyWith(
            estado: EstadoMuestra.predicha,
            remoteId: resultado.id,
            dosisPredichaMgL: resultado.dosisPredichaMgL,
            turbiedadEstimadaUnt: resultado.turbiedadEstimadaUnt,
            modelo: resultado.modelo,
            errorMsg: null,
          );
          await _db.update(actualizada);
          onProgreso?.call(actualizada);
          enviadas++;
        } on ApiException catch (e) {
          final fallo = muestra.copyWith(
            estado: EstadoMuestra.error,
            errorMsg: e.mensaje,
          );
          await _db.update(fallo);
          onProgreso?.call(fallo);
          // Un error de un item no detiene la cola: se sigue con el resto.
        }
      }
    } finally {
      _sincronizando = false;
    }

    return enviadas;
  }
}
