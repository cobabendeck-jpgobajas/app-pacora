import 'package:flutter/material.dart';

/// Tarjeta grande y clara con la dosis predicha, pensada para leerse de
/// un vistazo en planta (el plan exige que la prediccion tome menos de
/// 5 minutos de principio a fin, asi que la respuesta debe ser inmediata
/// de interpretar).
class DoseCard extends StatelessWidget {
  final double dosisMgL;
  final String modelo;

  const DoseCard({super.key, required this.dosisMgL, required this.modelo});

  @override
  Widget build(BuildContext context) {
    final color = _colorPorDosis(dosisMgL);
    return Card(
      elevation: 3,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Text(
              'DOSIS SUGERIDA',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${dosisMgL.toStringAsFixed(0)} mg/L',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sulfato de aluminio · modelo: $modelo',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Colores puramente orientativos (no clinicos): agrupan la dosis en
  /// las mismas tres bandas 200/300/400 mg/L que usa el modelo (ver
  /// 01_construir_dataset.py, BLOCK_DOSE), solo para que el operario
  /// distinga de un vistazo si es una dosis baja, media o alta.
  Color _colorPorDosis(double dosis) {
    if (dosis <= 250) return Colors.green.shade700;
    if (dosis <= 350) return Colors.orange.shade800;
    return Colors.red.shade700;
  }
}
