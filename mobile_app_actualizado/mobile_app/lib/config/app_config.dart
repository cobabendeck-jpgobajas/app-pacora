import 'package:shared_preferences/shared_preferences.dart';

/// Configuracion de la app: por ahora, solo la URL base del backend
/// (Fase 3). El Plan de Ejecucion aun no define si el backend vivira en
/// un servidor local de la planta o en la nube (seccion 8, riesgos), asi
/// que esto queda configurable desde la app en vez de quedar fijo en el
/// codigo.
class AppConfig {
  static const _prefsKey = 'backend_base_url';

  // Valor por defecto pensado para pruebas en un emulador Android que
  // habla con un backend corriendo en la misma maquina de desarrollo
  // (10.0.2.2 es el alias que el emulador de Android usa para "localhost"
  // del host). En un dispositivo fisico o en produccion, cambiar desde
  // Ajustes por la IP o dominio real del backend.
  static const defaultBaseUrl = 'http://10.0.2.2:8000';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey) ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    // Quita una barra final para que la concatenacion de rutas en
    // ApiClient no produzca "//predict".
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    await prefs.setString(_prefsKey, trimmed);
  }
}
