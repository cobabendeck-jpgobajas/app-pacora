import 'package:flutter/material.dart';

import '../models/muestra.dart';

/// Chip visual de estado, para que el operario vea de un vistazo cuales
/// muestras siguen en la cola offline sin tener que abrir cada una.
class EstadoChip extends StatelessWidget {
  final EstadoMuestra estado;
  const EstadoChip({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (estado) {
      EstadoMuestra.enCola => ('En cola', Colors.orange, Icons.cloud_off),
      EstadoMuestra.enviando => ('Enviando...', Colors.blue, Icons.cloud_upload),
      EstadoMuestra.predicha => ('Predicha', Colors.green, Icons.check_circle),
      EstadoMuestra.error => ('Error, reintentar', Colors.red, Icons.error_outline),
    };

    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.4)),
    );
  }
}
