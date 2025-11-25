/// 💊 MODELO DE CÁPSULA DE PODER
/// Sistema de recompensas para consultas médicas/psicológicas
/// 
/// Las cápsulas otorgan poderes especiales temporales o permanentes al alebrije
/// Se obtienen visitando servicios de salud universitarios

import 'package:flutter/material.dart';

/// Tipos de cápsulas disponibles
enum TipoCapsula {
  salud,        // 💚 Aumenta salud y regeneración
  fuerza,       // 💪 Aumenta experiencia ganada
  inteligencia, // 🧠 Evoluciona más rápido
  velocidad,    // ⚡ Reduce tiempo de decaimiento
  carisma,      // ✨ Aumenta felicidad y efectos visuales
  resilencia,   // 🛡️ Protege contra decaimiento extremo
  vitalidad,    // ❤️ Aumenta todos los stats temporalmente
}

/// Rareza de las cápsulas
enum RarezaCapsula {
  comun,    // 60% probabilidad - Duración 2 horas
  rara,     // 30% probabilidad - Duración 6 horas
  epica,    // 8% probabilidad - Duración 24 horas
  legendaria, // 2% probabilidad - Efecto permanente
}

/// Modelo de cápsula de poder
class CapsulaPoder {
  final String id;
  final TipoCapsula tipo;
  final RarezaCapsula rareza;
  final String nombre;
  final String descripcion;
  final String emoji;
  final Color color;
  
  // Efectos
  final int bonosSalud;
  final int bonosHambre;
  final int bonosFelicidad;
  final int bonosEnergia;
  final double multiplicadorExperiencia; // 1.0 = normal, 2.0 = doble XP
  final double reduccionDecaimiento; // 0.0 = normal, 0.5 = mitad del decaimiento
  
  // Duración
  final Duration? duracion; // null = permanente
  final DateTime? activadaEn;
  final bool activa;
  
  // Origen
  final String origenServicio; // 'Consulta Médica', 'Consulta Psicológica', 'Vacunación', etc.
  final DateTime obtenidaEn;

  CapsulaPoder({
    required this.id,
    required this.tipo,
    required this.rareza,
    required this.nombre,
    required this.descripcion,
    required this.emoji,
    required this.color,
    this.bonosSalud = 0,
    this.bonosHambre = 0,
    this.bonosFelicidad = 0,
    this.bonosEnergia = 0,
    this.multiplicadorExperiencia = 1.0,
    this.reduccionDecaimiento = 0.0,
    this.duracion,
    this.activadaEn,
    this.activa = false,
    required this.origenServicio,
    required this.obtenidaEn,
  });

  /// Verifica si la cápsula sigue activa
  bool get estaActiva {
    if (!activa || activadaEn == null) return false;
    if (duracion == null) return true; // Permanente
    
    final tiempoTranscurrido = DateTime.now().difference(activadaEn!);
    return tiempoTranscurrido < duracion!;
  }

  /// Tiempo restante de la cápsula
  Duration? get tiempoRestante {
    if (!estaActiva || duracion == null || activadaEn == null) return null;
    
    final tiempoTranscurrido = DateTime.now().difference(activadaEn!);
    final restante = duracion! - tiempoTranscurrido;
    return restante.isNegative ? Duration.zero : restante;
  }

  /// Porcentaje de duración restante (0.0 a 1.0)
  double get porcentajeDuracion {
    if (duracion == null) return 1.0; // Permanente
    if (!estaActiva || activadaEn == null) return 0.0;
    
    final tiempoTranscurrido = DateTime.now().difference(activadaEn!);
    final progreso = tiempoTranscurrido.inMilliseconds / duracion!.inMilliseconds;
    return (1.0 - progreso).clamp(0.0, 1.0);
  }

  /// Copia con cambios
  CapsulaPoder copyWith({
    String? id,
    TipoCapsula? tipo,
    RarezaCapsula? rareza,
    String? nombre,
    String? descripcion,
    String? emoji,
    Color? color,
    int? bonosSalud,
    int? bonosHambre,
    int? bonosFelicidad,
    int? bonosEnergia,
    double? multiplicadorExperiencia,
    double? reduccionDecaimiento,
    Duration? duracion,
    DateTime? activadaEn,
    bool? activa,
    String? origenServicio,
    DateTime? obtenidaEn,
  }) {
    return CapsulaPoder(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      rareza: rareza ?? this.rareza,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      bonosSalud: bonosSalud ?? this.bonosSalud,
      bonosHambre: bonosHambre ?? this.bonosHambre,
      bonosFelicidad: bonosFelicidad ?? this.bonosFelicidad,
      bonosEnergia: bonosEnergia ?? this.bonosEnergia,
      multiplicadorExperiencia: multiplicadorExperiencia ?? this.multiplicadorExperiencia,
      reduccionDecaimiento: reduccionDecaimiento ?? this.reduccionDecaimiento,
      duracion: duracion ?? this.duracion,
      activadaEn: activadaEn ?? this.activadaEn,
      activa: activa ?? this.activa,
      origenServicio: origenServicio ?? this.origenServicio,
      obtenidaEn: obtenidaEn ?? this.obtenidaEn,
    );
  }

  /// Serialización JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo.name,
      'rareza': rareza.name,
      'nombre': nombre,
      'descripcion': descripcion,
      'emoji': emoji,
      'color': color.value,
      'bonosSalud': bonosSalud,
      'bonosHambre': bonosHambre,
      'bonosFelicidad': bonosFelicidad,
      'bonosEnergia': bonosEnergia,
      'multiplicadorExperiencia': multiplicadorExperiencia,
      'reduccionDecaimiento': reduccionDecaimiento,
      'duracion': duracion?.inMilliseconds,
      'activadaEn': activadaEn?.toIso8601String(),
      'activa': activa,
      'origenServicio': origenServicio,
      'obtenidaEn': obtenidaEn.toIso8601String(),
    };
  }

  /// Deserialización JSON
  factory CapsulaPoder.fromJson(Map<String, dynamic> json) {
    return CapsulaPoder(
      id: json['id'],
      tipo: TipoCapsula.values.firstWhere((e) => e.name == json['tipo']),
      rareza: RarezaCapsula.values.firstWhere((e) => e.name == json['rareza']),
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      emoji: json['emoji'],
      color: Color(json['color']),
      bonosSalud: json['bonosSalud'] ?? 0,
      bonosHambre: json['bonosHambre'] ?? 0,
      bonosFelicidad: json['bonosFelicidad'] ?? 0,
      bonosEnergia: json['bonosEnergia'] ?? 0,
      multiplicadorExperiencia: json['multiplicadorExperiencia'] ?? 1.0,
      reduccionDecaimiento: json['reduccionDecaimiento'] ?? 0.0,
      duracion: json['duracion'] != null ? Duration(milliseconds: json['duracion']) : null,
      activadaEn: json['activadaEn'] != null ? DateTime.parse(json['activadaEn']) : null,
      activa: json['activa'] ?? false,
      origenServicio: json['origenServicio'],
      obtenidaEn: DateTime.parse(json['obtenidaEn']),
    );
  }
}

/// Generador de cápsulas aleatorias
class CapsulaPowerGenerator {
  /// Genera una cápsula aleatoria basada en el servicio de salud
  static CapsulaPoder generarCapsula(String servicioSalud) {
    final random = DateTime.now().millisecondsSinceEpoch;
    
    // Determinar rareza (probabilidad)
    final rarezaRoll = (random % 100);
    late RarezaCapsula rareza;
    late Duration? duracion;
    
    if (rarezaRoll < 2) {
      rareza = RarezaCapsula.legendaria;
      duracion = null; // Permanente
    } else if (rarezaRoll < 10) {
      rareza = RarezaCapsula.epica;
      duracion = Duration(hours: 24);
    } else if (rarezaRoll < 40) {
      rareza = RarezaCapsula.rara;
      duracion = Duration(hours: 6);
    } else {
      rareza = RarezaCapsula.comun;
      duracion = Duration(hours: 2);
    }

    // Tipo de cápsula basado en servicio
    late TipoCapsula tipo;
    if (servicioSalud.toLowerCase().contains('médic')) {
      tipo = TipoCapsula.values[(random % 3)]; // salud, fuerza, resilencia
    } else if (servicioSalud.toLowerCase().contains('psicol')) {
      tipo = TipoCapsula.values[2 + (random % 3)]; // inteligencia, velocidad, carisma
    } else {
      tipo = TipoCapsula.values[random % TipoCapsula.values.length];
    }

    return _crearCapsulaPorTipo(tipo, rareza, duracion, servicioSalud);
  }

  static CapsulaPoder _crearCapsulaPorTipo(
    TipoCapsula tipo,
    RarezaCapsula rareza,
    Duration? duracion,
    String servicio,
  ) {
    final multiplicador = _getMultiplicadorRareza(rareza);
    final id = 'cap_${DateTime.now().millisecondsSinceEpoch}';

    switch (tipo) {
      case TipoCapsula.salud:
        return CapsulaPoder(
          id: id,
          tipo: tipo,
          rareza: rareza,
          nombre: 'Cápsula de Vitalidad',
          descripcion: 'Restaura y protege la salud del alebrije',
          emoji: '💚',
          color: Colors.green,
          bonosSalud: (30 * multiplicador).round(),
          bonosEnergia: (10 * multiplicador).round(),
          duracion: duracion,
          origenServicio: servicio,
          obtenidaEn: DateTime.now(),
        );

      case TipoCapsula.fuerza:
        return CapsulaPoder(
          id: id,
          tipo: tipo,
          rareza: rareza,
          nombre: 'Cápsula de Poder',
          descripcion: 'Aumenta la experiencia ganada',
          emoji: '💪',
          color: Colors.red,
          bonosHambre: (20 * multiplicador).round(),
          multiplicadorExperiencia: 1.0 + (0.5 * multiplicador),
          duracion: duracion,
          origenServicio: servicio,
          obtenidaEn: DateTime.now(),
        );

      case TipoCapsula.inteligencia:
        return CapsulaPoder(
          id: id,
          tipo: tipo,
          rareza: rareza,
          nombre: 'Cápsula de Sabiduría',
          descripcion: 'Acelera la evolución del alebrije',
          emoji: '🧠',
          color: Colors.purple,
          bonosFelicidad: (15 * multiplicador).round(),
          multiplicadorExperiencia: 1.0 + (1.0 * multiplicador),
          duracion: duracion,
          origenServicio: servicio,
          obtenidaEn: DateTime.now(),
        );

      case TipoCapsula.velocidad:
        return CapsulaPoder(
          id: id,
          tipo: tipo,
          rareza: rareza,
          nombre: 'Cápsula de Agilidad',
          descripcion: 'Reduce el decaimiento de estadísticas',
          emoji: '⚡',
          color: Colors.yellow,
          bonosEnergia: (25 * multiplicador).round(),
          reduccionDecaimiento: 0.2 * multiplicador,
          duracion: duracion,
          origenServicio: servicio,
          obtenidaEn: DateTime.now(),
        );

      case TipoCapsula.carisma:
        return CapsulaPoder(
          id: id,
          tipo: tipo,
          rareza: rareza,
          nombre: 'Cápsula de Alegría',
          descripcion: 'Aumenta la felicidad y mejora el aura',
          emoji: '✨',
          color: Colors.pink,
          bonosFelicidad: (30 * multiplicador).round(),
          bonosHambre: (10 * multiplicador).round(),
          duracion: duracion,
          origenServicio: servicio,
          obtenidaEn: DateTime.now(),
        );

      case TipoCapsula.resilencia:
        return CapsulaPoder(
          id: id,
          tipo: tipo,
          rareza: rareza,
          nombre: 'Cápsula de Protección',
          descripcion: 'Protege contra decaimiento extremo',
          emoji: '🛡️',
          color: Colors.blue,
          bonosSalud: (20 * multiplicador).round(),
          reduccionDecaimiento: 0.3 * multiplicador,
          duracion: duracion,
          origenServicio: servicio,
          obtenidaEn: DateTime.now(),
        );

      case TipoCapsula.vitalidad:
        return CapsulaPoder(
          id: id,
          tipo: tipo,
          rareza: rareza,
          nombre: 'Cápsula Suprema',
          descripcion: 'Potencia todas las habilidades',
          emoji: '❤️',
          color: Colors.orange,
          bonosSalud: (25 * multiplicador).round(),
          bonosHambre: (25 * multiplicador).round(),
          bonosFelicidad: (25 * multiplicador).round(),
          bonosEnergia: (25 * multiplicador).round(),
          multiplicadorExperiencia: 1.0 + (0.75 * multiplicador),
          reduccionDecaimiento: 0.15 * multiplicador,
          duracion: duracion,
          origenServicio: servicio,
          obtenidaEn: DateTime.now(),
        );
    }
  }

  static double _getMultiplicadorRareza(RarezaCapsula rareza) {
    switch (rareza) {
      case RarezaCapsula.comun:
        return 1.0;
      case RarezaCapsula.rara:
        return 1.5;
      case RarezaCapsula.epica:
        return 2.5;
      case RarezaCapsula.legendaria:
        return 5.0;
    }
  }

  /// Obtiene el color del borde según rareza
  static Color getColorRareza(RarezaCapsula rareza) {
    switch (rareza) {
      case RarezaCapsula.comun:
        return Colors.grey;
      case RarezaCapsula.rara:
        return Colors.blue;
      case RarezaCapsula.epica:
        return Colors.purple;
      case RarezaCapsula.legendaria:
        return Colors.amber;
    }
  }

  /// Obtiene el nombre de la rareza
  static String getNombreRareza(RarezaCapsula rareza) {
    switch (rareza) {
      case RarezaCapsula.comun:
        return 'Común';
      case RarezaCapsula.rara:
        return 'Rara';
      case RarezaCapsula.epica:
        return 'Épica';
      case RarezaCapsula.legendaria:
        return '¡LEGENDARIA!';
    }
  }
}
