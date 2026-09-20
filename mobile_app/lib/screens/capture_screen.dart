import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'review_screen.dart';

/// Captura guiada (requisito de la Fase 4 en el Plan de Ejecucion): antes
/// de disparar la camara, se muestran las mismas condiciones del
/// protocolo de captura estandarizada usado para construir el dataset
/// (ver 02_extraer_caracteristicas.py, redimensionado 800x800 y Apendice
/// A de la tesis), para que la foto del operario sea comparable a las
/// que entrenaron el modelo.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker = ImagePicker();
  bool _cargando = false;

  static const _consejos = [
    'Llena el vaso de muestra hasta la marca habitual (misma cantidad que en las pruebas de jarras).',
    'Usa buena iluminación, de preferencia luz natural indirecta, sin sombras fuertes.',
    'Evita reflejos: no tomes la foto justo frente a una ventana o luz directa.',
    'Fondo neutro y limpio detrás del vaso, sin objetos que distraigan.',
    'Centra el vaso completo en el encuadre, cámara a la misma altura del agua.',
  ];

  Future<void> _tomarFoto(ImageSource source) async {
    setState(() => _cargando = true);
    try {
      final XFile? foto = await _picker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (foto == null || !mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewScreen(imagen: File(foto.path)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la cámara/galería: $e')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva muestra')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Antes de tomar la foto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _consejos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.teal),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_consejos[i])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_cargando)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton.icon(
                  onPressed: () => _tomarFoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar foto'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _tomarFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Elegir de la galería'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
