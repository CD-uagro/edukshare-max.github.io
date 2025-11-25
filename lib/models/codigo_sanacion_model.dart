/// 🏥 SISTEMA DE CÓDIGOS DE SANACIÓN
/// Códigos especiales que solo el personal médico puede proporcionar
/// Sirven para curar alebrijes enfermos por sobrealimentación o agotamiento

import 'dart:math';

/// Tipos de código de sanación según especialidad médica
enum TipoCodigoSanacion {
  consulta,      // 🩺 Médico general - Cura enfermedades básicas
  psicologia,    // 🧠 Psicólogo - Restaura felicidad + cura
  nutricion,     // 🥗 Nutricionista - Equilibra hambre + cura
  enfermeria,    // 💉 Enfermería - Cura rápida de emergencia
  emergencia,    // 🚑 Emergencia - Restauración total
}

/// Modelo de código de sanación
class CodigoSanacion {
  final String codigo;
  final TipoCodigoSanacion tipo;
  final String especialista;
  final DateTime generadoEn;
  final DateTime? expiraEn;
  final bool usado;
  
  // Efectos de curación
  final int restauracionSalud;
  final int restauracionFelicidad;
  final int restauracionHambre;
  final int restauracionEnergia;
  final bool curaEnfermedad; // Elimina efectos negativos por exceso

  CodigoSanacion({
    required this.codigo,
    required this.tipo,
    required this.especialista,
    required this.generadoEn,
    this.expiraEn,
    this.usado = false,
    required this.restauracionSalud,
    required this.restauracionFelicidad,
    required this.restauracionHambre,
    required this.restauracionEnergia,
    this.curaEnfermedad = true,
  });

  factory CodigoSanacion.fromJson(Map<String, dynamic> json) {
    return CodigoSanacion(
      codigo: json['codigo'] ?? '',
      tipo: TipoCodigoSanacion.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoCodigoSanacion.consulta,
      ),
      especialista: json['especialista'] ?? '',
      generadoEn: DateTime.parse(json['generadoEn'] ?? DateTime.now().toIso8601String()),
      expiraEn: json['expiraEn'] != null ? DateTime.parse(json['expiraEn']) : null,
      usado: json['usado'] ?? false,
      restauracionSalud: json['restauracionSalud'] ?? 50,
      restauracionFelicidad: json['restauracionFelicidad'] ?? 30,
      restauracionHambre: json['restauracionHambre'] ?? 30,
      restauracionEnergia: json['restauracionEnergia'] ?? 30,
      curaEnfermedad: json['curaEnfermedad'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'tipo': tipo.name,
    'especialista': especialista,
    'generadoEn': generadoEn.toIso8601String(),
    'expiraEn': expiraEn?.toIso8601String(),
    'usado': usado,
    'restauracionSalud': restauracionSalud,
    'restauracionFelicidad': restauracionFelicidad,
    'restauracionHambre': restauracionHambre,
    'restauracionEnergia': restauracionEnergia,
    'curaEnfermedad': curaEnfermedad,
  };

  /// Verifica si el código está expirado
  bool get estaExpirado {
    if (expiraEn == null) return false;
    return DateTime.now().isAfter(expiraEn!);
  }

  /// Verifica si el código es válido para usar
  bool get esValido => !usado && !estaExpirado;

  /// Genera un código aleatorio de 6 caracteres
  static String generarCodigoAleatorio() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sin I, O, 0, 1 para evitar confusión
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Crea un código según el tipo de especialista
  factory CodigoSanacion.generar({
    required TipoCodigoSanacion tipo,
    required String especialista,
    Duration? validezHoras,
  }) {
    final ahora = DateTime.now();
    final expiracion = validezHoras != null ? ahora.add(validezHoras) : null;

    // Efectos según especialidad
    int salud = 50, felicidad = 30, hambre = 30, energia = 30;
    
    switch (tipo) {
      case TipoCodigoSanacion.consulta:
        salud = 60;
        felicidad = 20;
        hambre = 20;
        energia = 30;
        break;
      case TipoCodigoSanacion.psicologia:
        salud = 40;
        felicidad = 80; // Enfoque en salud mental
        hambre = 10;
        energia = 40;
        break;
      case TipoCodigoSanacion.nutricion:
        salud = 50;
        felicidad = 30;
        hambre = 90; // Enfoque en nutrición
        energia = 50;
        break;
      case TipoCodigoSanacion.enfermeria:
        salud = 70; // Curación rápida
        felicidad = 30;
        hambre = 30;
        energia = 40;
        break;
      case TipoCodigoSanacion.emergencia:
        salud = 100; // Restauración total
        felicidad = 80;
        hambre = 80;
        energia = 100;
        break;
    }

    return CodigoSanacion(
      codigo: generarCodigoAleatorio(),
      tipo: tipo,
      especialista: especialista,
      generadoEn: ahora,
      expiraEn: expiracion,
      restauracionSalud: salud,
      restauracionFelicidad: felicidad,
      restauracionHambre: hambre,
      restauracionEnergia: energia,
      curaEnfermedad: true,
    );
  }

  /// Obtiene el emoji según el tipo
  String get emoji {
    switch (tipo) {
      case TipoCodigoSanacion.consulta:
        return '🩺';
      case TipoCodigoSanacion.psicologia:
        return '🧠';
      case TipoCodigoSanacion.nutricion:
        return '🥗';
      case TipoCodigoSanacion.enfermeria:
        return '💉';
      case TipoCodigoSanacion.emergencia:
        return '🚑';
    }
  }

  /// Obtiene el nombre legible del tipo
  String get nombreTipo {
    switch (tipo) {
      case TipoCodigoSanacion.consulta:
        return 'Consulta Médica';
      case TipoCodigoSanacion.psicologia:
        return 'Atención Psicológica';
      case TipoCodigoSanacion.nutricion:
        return 'Consulta Nutricional';
      case TipoCodigoSanacion.enfermeria:
        return 'Atención de Enfermería';
      case TipoCodigoSanacion.emergencia:
        return 'Emergencia Médica';
    }
  }

  /// Copia el código con cambios
  CodigoSanacion copyWith({
    String? codigo,
    TipoCodigoSanacion? tipo,
    String? especialista,
    DateTime? generadoEn,
    DateTime? expiraEn,
    bool? usado,
    int? restauracionSalud,
    int? restauracionFelicidad,
    int? restauracionHambre,
    int? restauracionEnergia,
    bool? curaEnfermedad,
  }) {
    return CodigoSanacion(
      codigo: codigo ?? this.codigo,
      tipo: tipo ?? this.tipo,
      especialista: especialista ?? this.especialista,
      generadoEn: generadoEn ?? this.generadoEn,
      expiraEn: expiraEn ?? this.expiraEn,
      usado: usado ?? this.usado,
      restauracionSalud: restauracionSalud ?? this.restauracionSalud,
      restauracionFelicidad: restauracionFelicidad ?? this.restauracionFelicidad,
      restauracionHambre: restauracionHambre ?? this.restauracionHambre,
      restauracionEnergia: restauracionEnergia ?? this.restauracionEnergia,
      curaEnfermedad: curaEnfermedad ?? this.curaEnfermedad,
    );
  }
}
