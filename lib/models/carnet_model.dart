// 🎓 MODELO DE DATOS - CARNET ESTUDIANTE UAGRO - BACKEND SASU COMPLETO
// ignore_for_file: avoid_print

class CarnetModel {
  final String id;
  final String matricula;
  final String nombreCompleto;
  final String correo;
  final int edad;
  final String sexo;
  final String categoria;
  final String programa;
  final String tipoSangre;
  final String enfermedadCronica;
  final String unidadMedica;
  final String numeroAfiliacion;
  final String usoSeguroUniversitario;
  final String donante;
  final String emergenciaContacto;
  final String discapacidad;
  final String tipoDiscapacidad;
  final String alergias;
  final String emergenciaTelefono;
  final String expedienteNotas;
  final String expedienteAdjuntos;
  final String? fotoUrl;

  // Campos técnicos de la base de datos (opcionales)
  final String? rid;
  final String? self;
  final String? etag;
  final String? attachments;
  final int? ts;

  CarnetModel({
    required this.id,
    required this.matricula,
    required this.nombreCompleto,
    required this.correo,
    required this.edad,
    required this.sexo,
    required this.categoria,
    required this.programa,
    required this.tipoSangre,
    required this.enfermedadCronica,
    required this.unidadMedica,
    required this.numeroAfiliacion,
    required this.usoSeguroUniversitario,
    required this.donante,
    required this.emergenciaContacto,
    required this.discapacidad,
    required this.tipoDiscapacidad,
    required this.alergias,
    required this.emergenciaTelefono,
    required this.expedienteNotas,
    required this.expedienteAdjuntos,
    this.fotoUrl,
    this.rid,
    this.self,
    this.etag,
    this.attachments,
    this.ts,
  });

  // 🔄 PARSE DESDE JSON BACKEND SASU COMPLETO
  factory CarnetModel.fromJson(Map<String, dynamic> json) {
    print('🔍 PARSING CARNET DATA COMPLETO: $json');
    return CarnetModel(
      id: json['id'] ?? '',
      matricula: json['matricula'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      correo: json['correo'] ?? '',
      edad: json['edad'] ?? 0,
      sexo: json['sexo'] ?? '',
      categoria: json['categoria'] ?? '',
      programa: json['programa'] ?? '',
      tipoSangre: json['tipoSangre'] ?? '',
      enfermedadCronica: json['enfermedadCronica'] ?? '',
      unidadMedica: json['unidadMedica'] ?? '',
      numeroAfiliacion: json['numeroAfiliacion'] ?? '',
      usoSeguroUniversitario: json['usoSeguroUniversitario'] ?? '',
      donante: json['donante'] ?? '',
      emergenciaContacto: json['emergenciaContacto'] ?? '',
      discapacidad: json['discapacidad'] ?? '',
      tipoDiscapacidad: json['tipoDiscapacidad'] ?? '',
      alergias: json['alergias'] ?? '',
      emergenciaTelefono: json['emergenciaTelefono'] ?? '',
      expedienteNotas: json['expedienteNotas'] ?? '',
      expedienteAdjuntos: json['expedienteAdjuntos'] ?? '',
      fotoUrl:
          json['fotoUrl'] ??
          json['photoUrl'] ??
          json['imagenUrl'] ??
          json['imageUrl'] ??
          json['avatarUrl'] ??
          json['foto_url'] ??
          json['photo_url'] ??
          json['imagen_url'] ??
          json['image_url'] ??
          json['avatar_url'] ??
          json['fotografia'] ??
          json['foto'],
      rid: json['_rid'],
      self: json['_self'],
      etag: json['_etag'],
      attachments: json['_attachments'],
      ts: json['_ts'],
    );
  }

  // 📄 GETTERS PARA COMPATIBILIDAD CON UI EXISTENTE
  String get carrera => programa;
  String get estado => categoria;
  String get telefono => emergenciaTelefono;
  String get contactoEmergencia => emergenciaContacto;
  String get seguroMedico => usoSeguroUniversitario == 'Sí'
      ? unidadMedica
      : 'Sin seguro universitario';
  String get email => correo;

  // 🩺 GETTERS PARA INFORMACIÓN MÉDICA
  bool get tieneEnfermedadCronica =>
      enfermedadCronica.toLowerCase() != 'negadas' &&
      enfermedadCronica.toLowerCase() != 'ninguna' &&
      enfermedadCronica.isNotEmpty;
  bool get tieneAlergias =>
      alergias.toLowerCase() != 'negadas' &&
      alergias.toLowerCase() != 'ninguna' &&
      alergias.isNotEmpty;
  bool get tieneDiscapacidad =>
      discapacidad.toLowerCase() == 'sí' || discapacidad.toLowerCase() == 'si';
  bool get esDonante =>
      donante.toLowerCase() == 'sí' || donante.toLowerCase() == 'si';
  bool get usaSeguroUniversitario =>
      usoSeguroUniversitario.toLowerCase() == 'sí' ||
      usoSeguroUniversitario.toLowerCase() == 'si';

  // 📄 CONVERTIR A JSON (para futuras funcionalidades)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'nombreCompleto': nombreCompleto,
      'correo': correo,
      'edad': edad,
      'sexo': sexo,
      'categoria': categoria,
      'programa': programa,
      'tipoSangre': tipoSangre,
      'enfermedadCronica': enfermedadCronica,
      'unidadMedica': unidadMedica,
      'numeroAfiliacion': numeroAfiliacion,
      'usoSeguroUniversitario': usoSeguroUniversitario,
      'donante': donante,
      'emergenciaContacto': emergenciaContacto,
      'discapacidad': discapacidad,
      'tipoDiscapacidad': tipoDiscapacidad,
      'alergias': alergias,
      'emergenciaTelefono': emergenciaTelefono,
      'expedienteNotas': expedienteNotas,
      'expedienteAdjuntos': expedienteAdjuntos,
      if (fotoUrl != null && fotoUrl!.trim().isNotEmpty) 'fotoUrl': fotoUrl,
    };
  }

  // 📄 PARA DEBUG
  CarnetModel copyWith({
    String? id,
    String? matricula,
    String? nombreCompleto,
    String? correo,
    int? edad,
    String? sexo,
    String? categoria,
    String? programa,
    String? tipoSangre,
    String? enfermedadCronica,
    String? unidadMedica,
    String? numeroAfiliacion,
    String? usoSeguroUniversitario,
    String? donante,
    String? emergenciaContacto,
    String? discapacidad,
    String? tipoDiscapacidad,
    String? alergias,
    String? emergenciaTelefono,
    String? expedienteNotas,
    String? expedienteAdjuntos,
    String? fotoUrl,
    bool clearFotoUrl = false,
  }) {
    return CarnetModel(
      id: id ?? this.id,
      matricula: matricula ?? this.matricula,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correo: correo ?? this.correo,
      edad: edad ?? this.edad,
      sexo: sexo ?? this.sexo,
      categoria: categoria ?? this.categoria,
      programa: programa ?? this.programa,
      tipoSangre: tipoSangre ?? this.tipoSangre,
      enfermedadCronica: enfermedadCronica ?? this.enfermedadCronica,
      unidadMedica: unidadMedica ?? this.unidadMedica,
      numeroAfiliacion: numeroAfiliacion ?? this.numeroAfiliacion,
      usoSeguroUniversitario:
          usoSeguroUniversitario ?? this.usoSeguroUniversitario,
      donante: donante ?? this.donante,
      emergenciaContacto: emergenciaContacto ?? this.emergenciaContacto,
      discapacidad: discapacidad ?? this.discapacidad,
      tipoDiscapacidad: tipoDiscapacidad ?? this.tipoDiscapacidad,
      alergias: alergias ?? this.alergias,
      emergenciaTelefono: emergenciaTelefono ?? this.emergenciaTelefono,
      expedienteNotas: expedienteNotas ?? this.expedienteNotas,
      expedienteAdjuntos: expedienteAdjuntos ?? this.expedienteAdjuntos,
      fotoUrl: clearFotoUrl ? null : (fotoUrl ?? this.fotoUrl),
      rid: rid,
      self: self,
      etag: etag,
      attachments: attachments,
      ts: ts,
    );
  }

  @override
  String toString() {
    return 'CarnetModel(id: $id, matricula: $matricula, nombreCompleto: $nombreCompleto, programa: $programa, categoria: $categoria, edad: $edad, sexo: $sexo)';
  }
}
