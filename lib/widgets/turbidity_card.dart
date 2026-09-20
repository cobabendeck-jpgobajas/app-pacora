import 'package:flutter/material.dart';

/// Tarjeta secundaria con la turbiedad estimada por el modelo (UNT).
/// Es un dato complementario a la dosis sugerida (ver DoseCard): ayuda al
/// operario a entender por que el modelo sugirio esa dosis, pero no
/// reemplaza una medicion con turbidimetro cuando se requiera precision
/// de laboratorio.
class TurbidityCard extends StatelessWidget {
  final double turbiedadUnt;

  const TurbidityCard({super.key, required this.turbiedadUnt});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        child: Row(
          children: [
            Icon(Icons.opacity_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Turbiedad estimada',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${turbiedadUnt.toStringAsFixed(1)} UNT',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'Estimacion calculada por el modelo a partir de la foto; '
                  'no reemplaza una medicion con turbidimetro.',
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
