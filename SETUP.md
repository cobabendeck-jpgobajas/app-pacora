# App móvil — Fase 4 (Aguas Manantiales de Pácora)

Código fuente de la versión mínima viable en Flutter (Android). Este entorno de
trabajo en la nube no tiene acceso de red a los servidores de descarga del SDK
de Flutter/Android, así que este paquete **no incluye un APK compilado**: son
los archivos Dart + `pubspec.yaml` listos para integrarse en un proyecto
Flutter y compilarse en una máquina que sí tenga el SDK instalado.

## Qué contiene

- `lib/` — todo el código de la app (pantallas, servicios, modelos, widgets).
- `pubspec.yaml` — dependencias.

Lo que falta (se genera automáticamente en el paso 1 de abajo, no se escribe a
mano): las carpetas `android/`, `ios/`, `web/`, etc. con el proyecto nativo,
porque su contenido exacto depende de la versión del SDK de Flutter instalada.

## Pasos para compilar

Requisitos previos: [Flutter SDK](https://docs.flutter.dev/get-started/install)
(canal stable) instalado y `flutter doctor` sin errores para Android.

```bash
# 1. Crear el proyecto base (genera android/, ios/, etc.)
flutter create app_pacora
cd app_pacora

# 2. Reemplazar el codigo generado por el de este paquete
rm -rf lib
cp -r ../mobile_app/lib .
cp ../mobile_app/pubspec.yaml .

# 3. Instalar dependencias
flutter pub get

# 4. Agregar el permiso de camara en android/app/src/main/AndroidManifest.xml
#    (el permiso de INTERNET ya viene incluido en la plantilla de flutter create):
#    <uses-permission android:name="android.permission.CAMERA" />
#    justo antes de la etiqueta <application ...>

# 5. Compilar el APK
flutter build apk --release
# El instalable queda en build/app/outputs/flutter-apk/app-release.apk
```

## Configuración del backend

La URL de la API (Fase 3) es configurable desde la app (pantalla Ajustes), no
está fija en el código — porque el Plan de Ejecución todavía no define si el
backend vivirá en un servidor local de la planta o en la nube. Por defecto la
app apunta a `http://10.0.2.2:8000` (alias del emulador Android hacia
`localhost` de la máquina de desarrollo); en un dispositivo físico, cambiarla
desde Ajustes a la IP o dominio real del servidor.

## Qué falta para producción

Este código cubre la meta de la Fase 4 (captura guiada, predicción, cola
offline). Antes de distribuirlo a los operarios de planta:

- Probarlo en un dispositivo Android real (no solo en el emulador), con la
  API de la Fase 3 corriendo en una IP alcanzable desde la planta.
- Revisar los textos de la captura guiada con quien opera la prueba de
  jarras en planta, por si el protocolo real difiere del usado al construir
  el dataset.
- Firmar el APK para distribución (o publicarlo en Play Store / gestión
  interna de dispositivos, según defina la empresa).
