/// Estado de una muestra en el flujo local de la app.
enum EstadoMuestra {
  enCola, // capturada, esperando conexion o envio
  enviando, // subiendo/prediciendo en este momento
  predicha, // el backend ya respondio con la dosis
  error, // el envio fallo (se reintentara)
}

EstadoMuestra estadoDesdeTexto(String texto) {
  return EstadoMuestra.values.firstWhere(
    (e) => e.name == texto,
    orElse: () => EstadoMuestra.error,
  );
}

/// Representa una muestra de agua capturada por el operario, tanto si ya
/// fue predicha por el backend como si sigue en la cola offline.
class Muestra {
  final int? id; // id local (sqflite)
  final int? remoteId; // id devuelto por POST /predict
  final String imagePath; // ruta local de la foto
  final DateTime creadoEn;
  final EstadoMuestra estado;
  final double? dosisPredichaMgL;
  final String? modelo;
  final double? dosisRealMgL;
  final double? turbiedadRealUnt;
  final String? errorMsg;

  const Muestra({
    this.id,
    this.remoteId,
    required this.imagePath,
    required this.creadoEn,
    required this.estado,
    this.dosisPredichaMgL,
    this.modelo,
    this.dosisRealMgL,
    this.turbiedadRealUnt,
    this.errorMsg,
  });

  Muestra copyWith({
    int? id,
    int? remoteId,
    String? imagePath,
    DateTime? creadoEn,
    EstadoMuestra? estado,
    double? dosisPredichaMgL,
    String? modelo,
    double? dosisRealMgL,
    double? turbiedadRealUnt,
    String? errorMsg,
  }) {
    return Muestra(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      imagePath: imagePath ?? this.imagePath,
      creadoEn: creadoEn ?? this.creadoEn,
      estado: estado ?? this.estado,
      dosisPredichaMgL: dosisPredichaMgL ?? this.dosisPredichaMgL,
      modelo: modelo ?? this.modelo,
      dosisRealMgL: dosisRealMgL ?? this.dosisRealMgL,
      turbiedadRealUnt: turbiedadRealUnt ?? this.turbiedadRealUnt,
      errorMsg: errorMsg ?? this.errorMsg,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'remote_id': remoteId,
      'image_path': imagePath,
      'creado_en': creadoEn.toIso8601String(),
      'estado': estado.name,
      'dosis_predicha_mg_l': dosisPredichaMgL,
      'modelo': modelo,
      'dosis_real_mg_l': dosisRealMgL,
      'turbiedad_real_unt': turbiedadRealUnt,
      'error_msg': errorMsg,
    };
  }

  factory Muestra.fromMap(Map<String, Object?> map) {
    return Muestra(
      id: map['id'] as int?,
      remoteId: map['remote_id'] as int?,
      imagePath: map['image_path'] as String,
      creadoEn: DateTime.parse(map['creado_en'] as String),
      estado: estadoDesdeTexto(map['estado'] as String),
      dosisPredichaMgL: (map['dosis_predicha_mg_l'] as num?)?.toDouble(),
      modelo: map['modelo'] as String?,
      dosisRealMgL: (map['dosis_real_mg_l'] as num?)?.toDouble(),
      turbiedadRealUnt: (map['turbiedad_real_unt'] as num?)?.toDouble(),
      errorMsg: map['error_msg'] as String?,
    );
  }
}
