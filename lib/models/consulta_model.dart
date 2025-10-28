// 📋 MODELO DE CONSULTA MÉDICA
// Representa una consulta médica del alumno

class ConsultaModel {
  final String id;
  final String matricula;
  final String nombreCompleto;
  final DateTime fecha;
  final String diagnostico;
  final String medico;
  final String departamento;
  final String observaciones;
  final String tipo;

  ConsultaModel({
    required this.id,
    required this.matricula,
    required this.nombreCompleto,
    required this.fecha,
    required this.diagnostico,
    required this.medico,
    required this.departamento,
    this.observaciones = '',
    this.tipo = 'Consulta general',
  });

  factory ConsultaModel.fromJson(Map<String, dynamic> json) {
    return ConsultaModel(
      id: json['id'] ?? '',
      matricula: json['matricula'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      fecha: _parseDate(json['fecha']),
      diagnostico: json['diagnostico'] ?? 'Sin diagnóstico registrado',
      medico: json['medico'] ?? 'Servicio Médico UAGro',
      departamento: json['departamento'] ?? 'Consultorio Médico',
      observaciones: json['observaciones'] ?? '',
      tipo: json['tipo'] ?? 'Consulta general',
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is DateTime) return dateValue;
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'nombreCompleto': nombreCompleto,
      'fecha': fecha.toIso8601String(),
      'diagnostico': diagnostico,
      'medico': medico,
      'departamento': departamento,
      'observaciones': observaciones,
      'tipo': tipo,
    };
  }

  @override
  String toString() {
    return 'ConsultaModel(id: $id, matricula: $matricula, nombre: $nombreCompleto, fecha: $fecha, diagnostico: $diagnostico)';
  }
}
