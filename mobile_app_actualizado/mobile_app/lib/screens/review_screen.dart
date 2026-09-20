import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/muestra.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import 'result_screen.dart';

/// Ultimo paso antes de enviar: el operario confirma que la foto quedo
/// bien tomada (o vuelve atras a repetirla) antes de gastar tiempo/datos
/// enviandola.
class ReviewScreen extends StatefulWidget {
  final File imagen;
  const ReviewScreen({super.key, required this.imagen});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _procesando = false;

  Future<File> _guardarCopiaPersistente(File original) async {
    // image_picker puede devolver un archivo en un directorio temporal
    // que el sistema operativo podria limpiar; se guarda una copia en el
    // almacenamiento propio de la app para que la cola offline sobreviva
    // a reinicios del telefono.
    final dir = await getApplicationDocumentsDirectory();
    final muestrasDir = Directory(p.join(dir.path, 'muestras'));
    if (!await muestrasDir.exists()) {
      await muestrasDir.create(recursive: true);
    }
    final nombre = 'muestra_${DateTime.now().millisecondsSinceEpoch}'
        '${p.extension(original.path)}';
    final destino = File(p.join(muestrasDir.path, nombre));
    return original.copy(destino.path);
  }

  Future<void> _confirmarYPredecir() async {
    setState(() => _procesando = true);
    try {
      final copia = await _guardarCopiaPersistente(widget.imagen);

      var muestra = Muestra(
        imagePath: copia.path,
        creadoEn: DateTime.now(),
        estado: EstadoMuestra.enCola,
      );
      muestra = await DatabaseService.instance.insert(muestra);

      // Intento inmediato: si hay conexion, el operario ve la dosis en
      // el momento (la meta de la Fase 4 es responder en menos de 5
      // minutos); si no hay conexion, queda en la cola offline y se
      // reintentara automaticamente mas adelante (ver HomeScreen).
      final sync = SyncService();
      await sync.sincronizarPendientes();

      if (!mounted) return;

      final actualizada = (await DatabaseService.instance.listAll())
          .firstWhere((m) => m.id == muestra.id, orElse: () => muestra);

      if (actualizada.estado == EstadoMuestra.predicha) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResultScreen(muestra: actualizada)),
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sin conexión con el servidor: la muestra quedó en la cola '
              'y se enviará automáticamente cuando haya señal.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la muestra: $e')),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar muestra')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(widget.imagen, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              if (_procesando)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton.icon(
                  onPressed: _confirmarYPredecir,
                  icon: const Icon(Icons.send),
                  label: const Text('Confirmar y predecir dosis'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.replay),
                  label: const Text('Repetir foto'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
