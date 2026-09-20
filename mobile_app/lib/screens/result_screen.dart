import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/muestra.dart';
import '../services/api_client.dart';
import '../services/database_service.dart';
import '../widgets/dose_card.dart';
import 'dart:io';

/// Muestra el resultado de la prediccion y permite, mas adelante,
/// registrar el valor real (turbiedad medida con turbidimetro y/o la
/// dosis que finalmente se aplico en planta). Ese dato es justamente el
/// insumo que la Fase 5 (aprendizaje continuo) necesita para reentrenar
/// el modelo -- por eso el backend ya expone
/// PATCH /predicciones/{id}/verificar (ver Fase 3).
class ResultScreen extends StatefulWidget {
  final Muestra muestra;
  const ResultScreen({super.key, required this.muestra});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Muestra _muestra;
  final _dosisRealCtrl = TextEditingController();
  final _turbiedadRealCtrl = TextEditingController();
  bool _guardandoVerificacion = false;

  @override
  void initState() {
    super.initState();
    _muestra = widget.muestra;
  }

  @override
  void dispose() {
    _dosisRealCtrl.dispose();
    _turbiedadRealCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarVerificacion() async {
    final remoteId = _muestra.remoteId;
    if (remoteId == null) return;

    final dosisReal = double.tryParse(_dosisRealCtrl.text.trim());
    final turbiedadReal = double.tryParse(_turbiedadRealCtrl.text.trim());
    if (dosisReal == null && turbiedadReal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa al menos un valor real para registrar.')),
      );
      return;
    }

    setState(() => _guardandoVerificacion = true);
    try {
      await ApiClient().registrarVerificacion(
        remoteId,
        dosisRealMgL: dosisReal,
        turbiedadRealUnt: turbiedadReal,
      );
      final actualizada = _muestra.copyWith(
        dosisRealMgL: dosisReal,
        turbiedadRealUnt: turbiedadReal,
      );
      await DatabaseService.instance.update(actualizada);
      if (!mounted) return;
      setState(() => _muestra = actualizada);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor real registrado. Gracias — esto ayuda a mejorar el modelo.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _guardandoVerificacion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dosis = _muestra.dosisPredichaMgL;
    final yaVerificada = _muestra.dosisRealMgL != null || _muestra.turbiedadRealUnt != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_muestra.imagePath),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              DateFormat('d MMM y, HH:mm', 'es').format(_muestra.creadoEn),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (dosis != null)
              DoseCard(dosisMgL: dosis, modelo: _muestra.modelo ?? '—')
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Esta muestra todavía no tiene una predicción (revisa la cola offline).'),
                ),
              ),
            const SizedBox(height: 28),
            if (_muestra.remoteId != null) ...[
              Text(
                yaVerificada ? 'Valor real registrado' : '¿Ya mediste el valor real?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Registrar la dosis o turbiedad real ayuda a mejorar el modelo con el tiempo.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (yaVerificada)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_muestra.turbiedadRealUnt != null)
                      Text('Turbiedad real: ${_muestra.turbiedadRealUnt} UNT'),
                    if (_muestra.dosisRealMgL != null)
                      Text('Dosis real aplicada: ${_muestra.dosisRealMgL} mg/L'),
                  ],
                )
              else ...[
                TextField(
                  controller: _turbiedadRealCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Turbiedad real (UNT), si la mediste',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _dosisRealCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Dosis real aplicada (mg/L), si fue distinta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _guardandoVerificacion ? null : _guardarVerificacion,
                  icon: _guardandoVerificacion
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.fact_check_outlined),
                  label: const Text('Registrar valor real'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
