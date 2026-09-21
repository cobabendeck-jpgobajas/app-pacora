import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Excepcion de alto nivel para errores de la API, con el mensaje ya listo
/// para mostrar al operario (evita filtrar detalles tecnicos a la UI).
class ApiException implements Exception {
  final String mensaje;
  final int? statusCode;
  ApiException(this.mensaje, {this.statusCode});

  @override
  String toString() => mensaje;
}

/// Resultado de una prediccion exitosa (POST /predict), tal como lo
/// devuelve el backend de la Fase 3.
class PrediccionResult {
  final int id;
  final double dosisPredichaMgL;
  final double? turbiedadEstimadaUnt;
  final String modelo;
  final Map<String, dynamic> features;

  PrediccionResult({
    required this.id,
    required this.dosisPredichaMgL,
    this.turbiedadEstimadaUnt,
    required this.modelo,
    required this.features,
  });

  factory PrediccionResult.fromJson(Map<String, dynamic> json) {
    return PrediccionResult(
      id: json['id'] as int,
      dosisPredichaMgL: (json['dosis_predicha_mg_l'] as num).toDouble(),
      // Campo opcional: si el backend del servidor aun no tiene el modelo
      // de turbiedad desplegado, esta clave puede no venir o venir null.
      turbiedadEstimadaUnt: (json['turbiedad_estimada_unt'] as num?)?.toDouble(),
      modelo: json['modelo'] as String,
      features: Map<String, dynamic>.from(json['features'] as Map),
    );
  }
}

/// Cliente HTTP para la API de prediccion (Fase 3, backend/app/main.py).
/// La URL base es configurable (ver AppConfig) porque el Plan de Ejecucion
/// aun no define si el backend correra en un servidor local de planta o
/// en la nube.
class ApiClient {
  final Duration timeout;
  ApiClient({this.timeout = const Duration(seconds: 30)});

  /// Cabecera requerida cuando el backend se expone a traves de un tunel
  /// temporal (ngrok): sin ella, el plan gratuito de ngrok intercepta la
  /// primera peticion con una pagina HTML de advertencia en vez de dejarla
  /// pasar al servidor real, lo que rompe la app aunque la URL este bien
  /// escrita. En un backend sin ngrok (IP local o nube propia) esta
  /// cabecera es inofensiva: el servidor simplemente la ignora.
  static const Map<String, String> _headersBase = {
    'ngrok-skip-browser-warning': 'true',
  };

  Future<bool> verificarConexion() async {
    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final resp = await http
          .get(Uri.parse('$baseUrl/health'), headers: _headersBase)
          .timeout(const Duration(seconds: 6));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Igual que [verificarConexion], pero en vez de devolver solo un booleano
  /// devuelve el detalle tecnico exacto del fallo (excepcion o codigo de
  /// respuesta). Se usa unicamente en la pantalla de Ajustes para poder
  /// diagnosticar problemas de conexion sin adivinar -- devuelve `null`
  /// cuando la conexion fue exitosa.
  Future<String?> probarConexionDetallada() async {
    String baseUrl;
    try {
      baseUrl = await AppConfig.getBaseUrl();
    } catch (e) {
      return 'No se pudo leer la direccion guardada: $e';
    }
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/health'), headers: _headersBase)
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) return null;
      return 'El servidor respondio con codigo ${resp.statusCode} '
          '(se esperaba 200).';
    } catch (e) {
      return e.toString();
    }
  }

  Future<PrediccionResult> predecir(File imagen) async {
    final baseUrl = await AppConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/predict');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headersBase);
    request.files.add(
      await http.MultipartFile.fromPath('imagen', imagen.path),
    );

    try {
      final streamed = await request.send().timeout(timeout);
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200) {
        final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        return PrediccionResult.fromJson(json);
      }
      throw ApiException(
        _mensajeDeError(resp),
        statusCode: resp.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('No se pudo conectar con el servidor: $e');
    }
  }

  Future<void> registrarVerificacion(
    int remoteId, {
    double? dosisRealMgL,
    double? turbiedadRealUnt,
  }) async {
    final baseUrl = await AppConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/predicciones/$remoteId/verificar');

    final body = <String, dynamic>{};
    if (dosisRealMgL != null) body['dosis_real_mg_l'] = dosisRealMgL;
    if (turbiedadRealUnt != null) body['turbiedad_real_unt'] = turbiedadRealUnt;

    final resp = await http
        .patch(
          uri,
          headers: {..._headersBase, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);

    if (resp.statusCode != 200) {
      throw ApiException(_mensajeDeError(resp), statusCode: resp.statusCode);
    }
  }

  String _mensajeDeError(http.Response resp) {
    try {
      final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final detail = json['detail'];
      if (detail is String) return detail;
    } catch (_) {
      // el cuerpo no era JSON: se usa el mensaje generico de abajo
    }
    return 'El servidor respondio con un error (codigo ${resp.statusCode}).';
  }
}
