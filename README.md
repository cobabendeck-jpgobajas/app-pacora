# Compilación del APK — App Pácora (Fase 4)

Este paquete permite compilar el instalable Android (`.apk`) de la app móvil
**sin instalar el SDK de Flutter/Android en ningún equipo local**, usando
GitHub Actions (ejecución gratuita en la nube de GitHub para repositorios
públicos, y con cupo gratuito mensual también para repositorios privados).

## Qué contiene

```
mobile_app_repo/
├── .github/workflows/build-apk.yml   ← receta de compilación automática
├── mobile_app/                       ← código fuente Flutter (Fase 4)
│   ├── lib/
│   ├── pubspec.yaml
│   └── SETUP.md                      ← alternativa: compilar en un equipo local
└── README.md                         ← este archivo
```

## Pasos para obtener el APK

1. **Crear un repositorio en GitHub** (gratuito): entrar a
   [github.com/new](https://github.com/new), elegir un nombre (por ejemplo
   `app-pacora`) y crearlo vacío, sin README ni licencia.

2. **Subir el contenido de esta carpeta** (`mobile_app_repo/`) al
   repositorio, conservando la estructura de carpetas tal como está
   (especialmente `.github/workflows/build-apk.yml`, que debe quedar en esa
   misma ruta). Dos formas de hacerlo:
   - Desde la web de GitHub: botón "Add file → Upload files", arrastrar
     todo el contenido de la carpeta.
   - Desde línea de comandos, si el equipo tiene `git` instalado:
     ```bash
     cd mobile_app_repo
     git init
     git add .
     git commit -m "App Pacora - Fase 4"
     git branch -M main
     git remote add origin https://github.com/<tu-usuario>/app-pacora.git
     git push -u origin main
     ```

3. **La compilación se dispara automáticamente** en cuanto el push llega a
   la rama `main` (o se puede lanzar manualmente: pestaña **Actions** del
   repositorio → seleccionar el flujo "Build APK (App Pácora)" → botón
   **Run workflow**).

4. **Esperar a que termine** (normalmente 5–8 minutos). Se puede seguir el
   progreso en tiempo real en la pestaña **Actions**.

5. **Descargar el APK**: al terminar con éxito (ícono verde ✓), entrar a esa
   ejecución del flujo y, en la sección **Artifacts** (parte inferior de la
   página), descargar `app-pacora-release-apk.zip`. Al descomprimirlo
   contiene `app-release.apk`, listo para instalar en un dispositivo Android
   (activando previamente "Instalar apps de origen desconocido" en el
   dispositivo, ya que no proviene de Play Store).

## Alternativa: compilar en un equipo local

Si se prefiere no usar GitHub, `mobile_app/SETUP.md` documenta los pasos
para compilar con el SDK de Flutter instalado directamente en un equipo
(Windows, macOS o Linux). Es el mismo código fuente; la diferencia es solo
dónde ocurre la compilación.

## Nota sobre costos

Este flujo no tiene costo: GitHub Actions ofrece minutos gratuitos cada mes
(2000 minutos/mes en cuentas gratuitas para repositorios privados, e
ilimitado para repositorios públicos), y una compilación de este proyecto
consume aproximadamente 5–8 minutos.
