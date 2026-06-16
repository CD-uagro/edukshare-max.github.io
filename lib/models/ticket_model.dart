class TicketModel {
  final String id;
  final String matricula;
  final String categoria;
  final String prioridad;
  final String titulo;
  final String descripcion;
  final String estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TicketModel({
    required this.id,
    required this.matricula,
    required this.categoria,
    required this.prioridad,
    required this.titulo,
    required this.descripcion,
    required this.estado,
    this.createdAt,
    this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: _readString(json, ['id', '_id', 'ticketId', 'ticket_id']),
      matricula: _readString(json, ['matricula', 'studentId', 'student_id']),
      categoria: _readString(json, ['categoria', 'category']),
      prioridad: _readString(json, [
        'prioridad',
        'priority',
      ], fallback: 'media'),
      titulo: _readString(json, ['titulo', 'title', 'asunto', 'subject']),
      descripcion: _readString(json, [
        'descripcion',
        'descripcionInicial',
        'initialDescription',
        'description',
        'detalle',
        'body',
      ]),
      estado: _readString(json, ['estado', 'status'], fallback: 'abierto'),
      createdAt: _readDate(json, [
        'createdAt',
        'createdAtUtc',
        'created_at',
        'fechaCreacion',
      ]),
      updatedAt: _readDate(json, [
        'updatedAt',
        'updatedAtUtc',
        'updated_at',
        'fechaActualizacion',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'categoria': categoria,
      'prioridad': prioridad,
      'titulo': titulo,
      'descripcion': descripcion,
      'estado': estado,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is DateTime) return value;
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed.toLocal();
      }
    }
    return null;
  }
}

class CrearTicketRequest {
  final String categoria;
  final String prioridad;
  final String titulo;
  final String descripcion;
  final String matricula;
  final String nombreCompleto;
  final String correo;
  final String campus;

  const CrearTicketRequest({
    required this.categoria,
    required this.prioridad,
    required this.titulo,
    required this.descripcion,
    required this.matricula,
    required this.nombreCompleto,
    required this.correo,
    required this.campus,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': matricula,
      'matricula': matricula,
      'nombrePaciente': nombreCompleto,
      'campus': campus,
      'categoria': categoria,
      'prioridad': prioridad,
      'titulo': titulo,
      'descripcionInicial': descripcion,
      'descripcion': descripcion,
      'nombreCompleto': nombreCompleto,
      'correo': correo,
    };
  }
}
