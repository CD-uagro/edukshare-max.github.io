import 'dart:math';

/// Modelo de datos para un Alebrije único generado algorítmicamente
/// Incluye DNA genético, estado Tamagotchi y historial evolutivo
class AlebrijeModel {
  final String id;
  final String matricula;
  final String nombre;
  final AlebrijeDNA dna;
  final AlebrijeEstado estado;
  final List<EvolucionHistorial> historialEvoluciones;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int nivelEvolucion;
  final int puntosExperiencia;

  AlebrijeModel({
    required this.id,
    required this.matricula,
    required this.nombre,
    required this.dna,
    required this.estado,
    required this.historialEvoluciones,
    required this.createdAt,
    required this.updatedAt,
    this.nivelEvolucion = 1,
    this.puntosExperiencia = 0,
  });

  factory AlebrijeModel.fromJson(Map<String, dynamic> json) {
    return AlebrijeModel(
      id: json['id'] ?? '',
      matricula: json['matricula'] ?? '',
      nombre: json['nombre'] ?? 'Mi Alebrije',
      dna: AlebrijeDNA.fromJson(json['dna'] ?? {}),
      estado: AlebrijeEstado.fromJson(json['estado'] ?? {}),
      historialEvoluciones: (json['historialEvoluciones'] as List<dynamic>?)
              ?.map((e) => EvolucionHistorial.fromJson(e))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      nivelEvolucion: json['nivelEvolucion'] ?? 1,
      puntosExperiencia: json['puntosExperiencia'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricula': matricula,
      'nombre': nombre,
      'dna': dna.toJson(),
      'estado': estado.toJson(),
      'historialEvoluciones': historialEvoluciones.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'nivelEvolucion': nivelEvolucion,
      'puntosExperiencia': puntosExperiencia,
    };
  }

  /// Genera un nuevo alebrije con DNA aleatorio único
  factory AlebrijeModel.generar({
    required String matricula,
    required String especieBase,
    String? nombre,
  }) {
    final random = Random();
    final timestamp = DateTime.now();
    
    // Seed único basado en matrícula y timestamp para generar DNA único
    final seed = '$matricula${timestamp.millisecondsSinceEpoch}'.hashCode;
    final randomWithSeed = Random(seed);

    return AlebrijeModel(
      id: 'alebrije_${matricula}_${timestamp.millisecondsSinceEpoch}',
      matricula: matricula,
      nombre: nombre ?? 'Alebrije de $especieBase',
      dna: AlebrijeDNA.generar(especieBase, randomWithSeed),
      estado: AlebrijeEstado.inicial(),
      historialEvoluciones: [
        EvolucionHistorial(
          nivel: 1,
          fecha: timestamp,
          descripcion: 'Nacimiento del alebrije',
        ),
      ],
      createdAt: timestamp,
      updatedAt: timestamp,
      nivelEvolucion: 1,
      puntosExperiencia: 0,
    );
  }

  /// Calcula si necesita atención urgente (mecánica Tamagotchi)
  bool get necesitaAtencion {
    return estado.hambre < 20 || estado.felicidad < 20 || estado.salud < 20;
  }

  /// Calcula el nivel de salud general (0-100)
  int get saludGeneral {
    return ((estado.hambre + estado.felicidad + estado.salud + estado.energia) / 4).round();
  }

  /// Determina el emoji de estado del alebrije
  String get estadoEmoji {
    if (saludGeneral >= 80) return '🌟';
    if (saludGeneral >= 60) return '😊';
    if (saludGeneral >= 40) return '😐';
    if (saludGeneral >= 20) return '😟';
    return '😰';
  }
}

/// DNA genético del alebrije - define su apariencia única
class AlebrijeDNA {
  final String especieBase; // jaguar, aguila, serpiente, venado, colibri
  final GenCabeza genCabeza;
  final GenCuerpo genCuerpo;
  final GenExtremidades genExtremidades;
  final GenCola genCola;
  final GenAlas genAlas;
  final PaletaColores colores;
  final List<String> patronesGeometricos;

  AlebrijeDNA({
    required this.especieBase,
    required this.genCabeza,
    required this.genCuerpo,
    required this.genExtremidades,
    required this.genCola,
    required this.genAlas,
    required this.colores,
    required this.patronesGeometricos,
  });

  factory AlebrijeDNA.fromJson(Map<String, dynamic> json) {
    return AlebrijeDNA(
      especieBase: json['especieBase'] ?? 'jaguar',
      genCabeza: GenCabeza.fromJson(json['genCabeza'] ?? {}),
      genCuerpo: GenCuerpo.fromJson(json['genCuerpo'] ?? {}),
      genExtremidades: GenExtremidades.fromJson(json['genExtremidades'] ?? {}),
      genCola: GenCola.fromJson(json['genCola'] ?? {}),
      genAlas: GenAlas.fromJson(json['genAlas'] ?? {}),
      colores: PaletaColores.fromJson(json['colores'] ?? {}),
      patronesGeometricos: List<String>.from(json['patronesGeometricos'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'especieBase': especieBase,
      'genCabeza': genCabeza.toJson(),
      'genCuerpo': genCuerpo.toJson(),
      'genExtremidades': genExtremidades.toJson(),
      'genCola': genCola.toJson(),
      'genAlas': genAlas.toJson(),
      'colores': colores.toJson(),
      'patronesGeometricos': patronesGeometricos,
    };
  }

  /// Genera DNA aleatorio basado en especie base
  factory AlebrijeDNA.generar(String especieBase, Random random) {
    return AlebrijeDNA(
      especieBase: especieBase,
      genCabeza: GenCabeza.aleatorio(especieBase, random),
      genCuerpo: GenCuerpo.aleatorio(especieBase, random),
      genExtremidades: GenExtremidades.aleatorio(especieBase, random),
      genCola: GenCola.aleatorio(especieBase, random),
      genAlas: GenAlas.aleatorio(especieBase, random),
      colores: PaletaColores.aleatorio(random),
      patronesGeometricos: _generarPatrones(random),
    );
  }

  static List<String> _generarPatrones(Random random) {
    final patronesDisponibles = [
      'espirales', 'ondas', 'zigzag', 'puntos', 'rayas',
      'grecas', 'flores', 'estrellas', 'circulos', 'triangulos'
    ];
    final numPatrones = 2 + random.nextInt(3); // 2-4 patrones
    patronesDisponibles.shuffle(random);
    return patronesDisponibles.take(numPatrones).toList();
  }

  /// Aplica mutación genética (para evolución)
  AlebrijeDNA mutar(Random random, double intensidad) {
    return AlebrijeDNA(
      especieBase: especieBase,
      genCabeza: genCabeza.mutar(random, intensidad),
      genCuerpo: genCuerpo.mutar(random, intensidad),
      genExtremidades: genExtremidades.mutar(random, intensidad),
      genCola: genCola.mutar(random, intensidad),
      genAlas: genAlas.mutar(random, intensidad),
      colores: colores.mutar(random, intensidad),
      patronesGeometricos: _mutarPatrones(random, intensidad),
    );
  }

  List<String> _mutarPatrones(Random random, double intensidad) {
    if (random.nextDouble() > intensidad) return patronesGeometricos;
    return _generarPatrones(random);
  }
}

/// Gen de la cabeza
class GenCabeza {
  final String forma; // felina, aviar, reptil, cervido, pequena
  final String orejas; // puntiagudas, redondeadas, largas, ausentes
  final String cuernos; // ausentes, ramificados, espirales, pequenos
  final String ojos; // grandes, rasgados, brillantes, misteriosos

  GenCabeza({
    required this.forma,
    required this.orejas,
    required this.cuernos,
    required this.ojos,
  });

  factory GenCabeza.fromJson(Map<String, dynamic> json) {
    return GenCabeza(
      forma: json['forma'] ?? 'felina',
      orejas: json['orejas'] ?? 'puntiagudas',
      cuernos: json['cuernos'] ?? 'ausentes',
      ojos: json['ojos'] ?? 'brillantes',
    );
  }

  Map<String, dynamic> toJson() => {'forma': forma, 'orejas': orejas, 'cuernos': cuernos, 'ojos': ojos};

  factory GenCabeza.aleatorio(String especieBase, Random random) {
    final formas = _getFormasParaEspecie(especieBase);
    final orejasList = ['puntiagudas', 'redondeadas', 'largas', 'ausentes'];
    final cuernosList = ['ausentes', 'ramificados', 'espirales', 'pequenos'];
    final ojosList = ['grandes', 'rasgados', 'brillantes', 'misteriosos'];

    return GenCabeza(
      forma: formas[random.nextInt(formas.length)],
      orejas: orejasList[random.nextInt(orejasList.length)],
      cuernos: cuernosList[random.nextInt(cuernosList.length)],
      ojos: ojosList[random.nextInt(ojosList.length)],
    );
  }

  static List<String> _getFormasParaEspecie(String especie) {
    switch (especie) {
      case 'jaguar': return ['felina', 'misteriosa'];
      case 'aguila': return ['aviar', 'majestuosa'];
      case 'serpiente': return ['reptil', 'alargada'];
      case 'venado': return ['cervido', 'elegante'];
      case 'colibri': return ['pequena', 'delicada'];
      default: return ['felina', 'aviar', 'reptil'];
    }
  }

  GenCabeza mutar(Random random, double intensidad) {
    return GenCabeza(
      forma: random.nextDouble() < intensidad ? _getFormasParaEspecie('')[random.nextInt(3)] : forma,
      orejas: random.nextDouble() < intensidad ? ['puntiagudas', 'redondeadas', 'largas'][random.nextInt(3)] : orejas,
      cuernos: random.nextDouble() < intensidad ? ['ausentes', 'ramificados', 'espirales'][random.nextInt(3)] : cuernos,
      ojos: ojos, // Los ojos raramente mutan
    );
  }
}

/// Gen del cuerpo
class GenCuerpo {
  final String tamano; // pequeno, mediano, grande, masivo
  final String textura; // escamas, plumas, pelo, liso
  final String forma; // compacto, alargado, robusto, esbelto
  final double proporcion; // 0.5 - 2.0

  GenCuerpo({
    required this.tamano,
    required this.textura,
    required this.forma,
    required this.proporcion,
  });

  factory GenCuerpo.fromJson(Map<String, dynamic> json) {
    return GenCuerpo(
      tamano: json['tamano'] ?? 'mediano',
      textura: json['textura'] ?? 'pelo',
      forma: json['forma'] ?? 'compacto',
      proporcion: (json['proporcion'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'tamano': tamano, 'textura': textura, 'forma': forma, 'proporcion': proporcion};

  factory GenCuerpo.aleatorio(String especieBase, Random random) {
    final tamanos = ['pequeno', 'mediano', 'grande'];
    final texturas = _getTexturasParaEspecie(especieBase);
    final formas = ['compacto', 'alargado', 'robusto', 'esbelto'];
    
    return GenCuerpo(
      tamano: tamanos[random.nextInt(tamanos.length)],
      textura: texturas[random.nextInt(texturas.length)],
      forma: formas[random.nextInt(formas.length)],
      proporcion: 0.7 + random.nextDouble() * 1.3, // 0.7 - 2.0
    );
  }

  static List<String> _getTexturasParaEspecie(String especie) {
    switch (especie) {
      case 'serpiente': return ['escamas', 'liso'];
      case 'aguila':
      case 'colibri': return ['plumas', 'suave'];
      case 'jaguar':
      case 'venado': return ['pelo', 'suave'];
      default: return ['escamas', 'plumas', 'pelo'];
    }
  }

  GenCuerpo mutar(Random random, double intensidad) {
    return GenCuerpo(
      tamano: random.nextDouble() < intensidad ? ['pequeno', 'mediano', 'grande'][random.nextInt(3)] : tamano,
      textura: textura, // Textura raramente cambia
      forma: random.nextDouble() < intensidad * 0.5 ? ['compacto', 'alargado', 'robusto'][random.nextInt(3)] : forma,
      proporcion: random.nextDouble() < intensidad ? proporcion + (random.nextDouble() - 0.5) * 0.3 : proporcion,
    );
  }
}

/// Gen de extremidades (patas)
class GenExtremidades {
  final int numeroPatas; // 0, 2, 4, 6
  final String tipo; // garras, pezunas, dedos, aletas
  final String tamano; // pequenas, medianas, grandes, poderosas

  GenExtremidades({
    required this.numeroPatas,
    required this.tipo,
    required this.tamano,
  });

  factory GenExtremidades.fromJson(Map<String, dynamic> json) {
    return GenExtremidades(
      numeroPatas: json['numeroPatas'] ?? 4,
      tipo: json['tipo'] ?? 'garras',
      tamano: json['tamano'] ?? 'medianas',
    );
  }

  Map<String, dynamic> toJson() => {'numeroPatas': numeroPatas, 'tipo': tipo, 'tamano': tamano};

  factory GenExtremidades.aleatorio(String especieBase, Random random) {
    final tipos = _getTiposParaEspecie(especieBase);
    final tamanos = ['pequenas', 'medianas', 'grandes', 'poderosas'];
    
    int patas;
    switch (especieBase) {
      case 'serpiente': patas = 0;
        break;
      case 'aguila':
      case 'colibri': patas = 2;
        break;
      default: patas = 4;
    }

    return GenExtremidades(
      numeroPatas: patas,
      tipo: tipos[random.nextInt(tipos.length)],
      tamano: tamanos[random.nextInt(tamanos.length)],
    );
  }

  static List<String> _getTiposParaEspecie(String especie) {
    switch (especie) {
      case 'jaguar': return ['garras', 'poderosas'];
      case 'aguila':
      case 'colibri': return ['garras', 'dedos'];
      case 'venado': return ['pezunas', 'elegantes'];
      case 'serpiente': return ['ausentes'];
      default: return ['garras', 'pezunas', 'dedos'];
    }
  }

  GenExtremidades mutar(Random random, double intensidad) {
    return GenExtremidades(
      numeroPatas: numeroPatas, // Número de patas no muta
      tipo: random.nextDouble() < intensidad * 0.3 ? ['garras', 'pezunas', 'dedos'][random.nextInt(3)] : tipo,
      tamano: random.nextDouble() < intensidad ? ['pequenas', 'medianas', 'grandes'][random.nextInt(3)] : tamano,
    );
  }
}

/// Gen de la cola
class GenCola {
  final bool tiene;
  final String tipo; // larga, corta, plumosa, escamosa, espiral
  final String punta; // normal, mechon, aguijon, plumas

  GenCola({
    required this.tiene,
    required this.tipo,
    required this.punta,
  });

  factory GenCola.fromJson(Map<String, dynamic> json) {
    return GenCola(
      tiene: json['tiene'] ?? true,
      tipo: json['tipo'] ?? 'larga',
      punta: json['punta'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() => {'tiene': tiene, 'tipo': tipo, 'punta': punta};

  factory GenCola.aleatorio(String especieBase, Random random) {
    final tipos = ['larga', 'corta', 'plumosa', 'escamosa', 'espiral'];
    final puntas = ['normal', 'mechon', 'aguijon', 'plumas'];
    
    return GenCola(
      tiene: especieBase != 'colibri' || random.nextBool(),
      tipo: tipos[random.nextInt(tipos.length)],
      punta: puntas[random.nextInt(puntas.length)],
    );
  }

  GenCola mutar(Random random, double intensidad) {
    return GenCola(
      tiene: tiene,
      tipo: random.nextDouble() < intensidad ? ['larga', 'corta', 'plumosa', 'escamosa'][random.nextInt(4)] : tipo,
      punta: random.nextDouble() < intensidad * 0.5 ? ['normal', 'mechon', 'aguijon'][random.nextInt(3)] : punta,
    );
  }
}

/// Gen de las alas
class GenAlas {
  final bool tiene;
  final String tipo; // plumas, membrana, energia, cristal
  final String tamano; // pequenas, medianas, grandes, majestuosas

  GenAlas({
    required this.tiene,
    required this.tipo,
    required this.tamano,
  });

  factory GenAlas.fromJson(Map<String, dynamic> json) {
    return GenAlas(
      tiene: json['tiene'] ?? false,
      tipo: json['tipo'] ?? 'plumas',
      tamano: json['tamano'] ?? 'medianas',
    );
  }

  Map<String, dynamic> toJson() => {'tiene': tiene, 'tipo': tipo, 'tamano': tamano};

  factory GenAlas.aleatorio(String especieBase, Random random) {
    bool tieneAlas;
    switch (especieBase) {
      case 'aguila':
      case 'colibri':
        tieneAlas = true;
        break;
      default:
        tieneAlas = random.nextDouble() < 0.4; // 40% probabilidad
    }

    final tipos = ['plumas', 'membrana', 'energia', 'cristal'];
    final tamanos = ['pequenas', 'medianas', 'grandes', 'majestuosas'];

    return GenAlas(
      tiene: tieneAlas,
      tipo: tipos[random.nextInt(tipos.length)],
      tamano: tamanos[random.nextInt(tamanos.length)],
    );
  }

  GenAlas mutar(Random random, double intensidad) {
    // Las alas pueden aparecer en evoluciones avanzadas
    final nuevasTieneAlas = tiene || (random.nextDouble() < intensidad * 0.1);
    
    return GenAlas(
      tiene: nuevasTieneAlas,
      tipo: random.nextDouble() < intensidad && tiene ? ['plumas', 'membrana', 'energia'][random.nextInt(3)] : tipo,
      tamano: random.nextDouble() < intensidad && tiene ? ['medianas', 'grandes', 'majestuosas'][random.nextInt(3)] : tamano,
    );
  }
}

/// Paleta de colores del alebrije (colores mexicanos vibrantes)
class PaletaColores {
  final String colorPrimario;
  final String colorSecundario;
  final String colorTerciario;
  final String colorAcento;
  final double brillantez; // 0.0 - 1.0

  PaletaColores({
    required this.colorPrimario,
    required this.colorSecundario,
    required this.colorTerciario,
    required this.colorAcento,
    required this.brillantez,
  });

  factory PaletaColores.fromJson(Map<String, dynamic> json) {
    return PaletaColores(
      colorPrimario: json['colorPrimario'] ?? '#FF6B35',
      colorSecundario: json['colorSecundario'] ?? '#F7931E',
      colorTerciario: json['colorTerciario'] ?? '#C1272D',
      colorAcento: json['colorAcento'] ?? '#8B1538',
      brillantez: (json['brillantez'] ?? 0.7).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'colorPrimario': colorPrimario,
    'colorSecundario': colorSecundario,
    'colorTerciario': colorTerciario,
    'colorAcento': colorAcento,
    'brillantez': brillantez,
  };

  factory PaletaColores.aleatorio(Random random) {
    // Colores inspirados en alebrijes tradicionales mexicanos
    final coloresMexicanos = [
      '#FF6B35', // Naranja fuego
      '#F7931E', // Amarillo sol
      '#C1272D', // Rojo intenso
      '#8B1538', // Rojo UAGro
      '#1565C0', // Azul cielo
      '#00A8E8', // Azul turquesa
      '#7209B7', // Morado místico
      '#F72585', // Rosa mexicano
      '#06FFA5', // Verde jade
      '#FFD700', // Oro
    ];

    coloresMexicanos.shuffle(random);

    return PaletaColores(
      colorPrimario: coloresMexicanos[0],
      colorSecundario: coloresMexicanos[1],
      colorTerciario: coloresMexicanos[2],
      colorAcento: coloresMexicanos[3],
      brillantez: 0.6 + random.nextDouble() * 0.4, // 0.6 - 1.0
    );
  }

  PaletaColores mutar(Random random, double intensidad) {
    if (random.nextDouble() > intensidad * 0.5) {
      return this; // 50% de mantener colores
    }
    return PaletaColores.aleatorio(random);
  }
}

/// Estado Tamagotchi del alebrije
class AlebrijeEstado {
  final int hambre; // 0-100 (100 = satisfecho)
  final int felicidad; // 0-100
  final int salud; // 0-100
  final int energia; // 0-100
  final DateTime ultimaAlimentacion;
  final DateTime ultimaInteraccion;
  final DateTime ultimoCuidado;
  final int diasConsecutivos;
  
  // Contadores diarios de interacciones con límites
  final int alimentacionesHoy;
  final int juegosHoy;
  final int curacionesHoy;
  final int descansosHoy;
  final DateTime ultimaAccionFecha;
  
  // 🎮 Sistema de cooldown para minijuegos (5 minutos)
  final DateTime ultimoMinijuego;
  final int bonusCooldownSegundos; // Segundos de bonus acumulados por puntos
  static const int cooldownMinijuegoSegundos = 300; // 5 minutos = 300 segundos

  AlebrijeEstado({
    required this.hambre,
    required this.felicidad,
    required this.salud,
    required this.energia,
    required this.ultimaAlimentacion,
    required this.ultimaInteraccion,
    required this.ultimoCuidado,
    this.diasConsecutivos = 0,
    this.alimentacionesHoy = 0,
    this.juegosHoy = 0,
    this.curacionesHoy = 0,
    this.descansosHoy = 0,
    DateTime? ultimaAccionFecha,
    DateTime? ultimoMinijuego,
    this.bonusCooldownSegundos = 0,
  }) : ultimaAccionFecha = ultimaAccionFecha ?? DateTime.now(),
       ultimoMinijuego = ultimoMinijuego ?? DateTime.now().subtract(const Duration(minutes: 10));
  
  // Límites máximos diarios
  static const int maxAlimentacionesDia = 5;
  static const int maxJuegosDia = 8;
  static const int maxCuracionesDia = 3;
  static const int maxDescansosDia = 5;
  
  // Verificar si ha pasado una hora desde la última acción
  bool get esNuevaHora {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(ultimaAccionFecha);
    return diferencia.inHours >= 1;
  }
  
  // Verificar límites alcanzados
  bool get puedeAlimentar => esNuevaHora || alimentacionesHoy < maxAlimentacionesDia;
  bool get puedeJugar => esNuevaHora || juegosHoy < maxJuegosDia;
  bool get puedeCurar => esNuevaHora || curacionesHoy < maxCuracionesDia;
  bool get puedeDescansar => esNuevaHora || descansosHoy < maxDescansosDia;
  
  // 🎮 Verificar cooldown de minijuego (5 minutos - bonus)
  bool get puedeJugarMinijuego {
    final ahora = DateTime.now();
    final cooldownReal = cooldownMinijuegoSegundos - bonusCooldownSegundos;
    final segundosDesdeUltimo = ahora.difference(ultimoMinijuego).inSeconds;
    return segundosDesdeUltimo >= cooldownReal || cooldownReal <= 0;
  }
  
  /// Segundos restantes para poder jugar minijuego
  int get segundosRestantesMinijuego {
    if (puedeJugarMinijuego) return 0;
    final ahora = DateTime.now();
    final cooldownReal = cooldownMinijuegoSegundos - bonusCooldownSegundos;
    final segundosDesdeUltimo = ahora.difference(ultimoMinijuego).inSeconds;
    return (cooldownReal - segundosDesdeUltimo).clamp(0, cooldownMinijuegoSegundos);
  }

  factory AlebrijeEstado.fromJson(Map<String, dynamic> json) {
    return AlebrijeEstado(
      hambre: json['hambre'] ?? 100,
      felicidad: json['felicidad'] ?? 100,
      salud: json['salud'] ?? 100,
      energia: json['energia'] ?? 100,
      ultimaAlimentacion: DateTime.parse(json['ultimaAlimentacion'] ?? DateTime.now().toIso8601String()),
      ultimaInteraccion: DateTime.parse(json['ultimaInteraccion'] ?? DateTime.now().toIso8601String()),
      ultimoCuidado: DateTime.parse(json['ultimoCuidado'] ?? DateTime.now().toIso8601String()),
      diasConsecutivos: json['diasConsecutivos'] ?? 0,
      alimentacionesHoy: json['alimentacionesHoy'] ?? 0,
      juegosHoy: json['juegosHoy'] ?? 0,
      curacionesHoy: json['curacionesHoy'] ?? 0,
      descansosHoy: json['descansosHoy'] ?? 0,
      ultimaAccionFecha: json['ultimaAccionFecha'] != null
          ? DateTime.parse(json['ultimaAccionFecha'])
          : DateTime.now(),
      ultimoMinijuego: json['ultimoMinijuego'] != null
          ? DateTime.parse(json['ultimoMinijuego'])
          : DateTime.now().subtract(const Duration(minutes: 10)),
      bonusCooldownSegundos: json['bonusCooldownSegundos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'hambre': hambre,
    'felicidad': felicidad,
    'salud': salud,
    'energia': energia,
    'ultimaAlimentacion': ultimaAlimentacion.toIso8601String(),
    'ultimaInteraccion': ultimaInteraccion.toIso8601String(),
    'ultimoCuidado': ultimoCuidado.toIso8601String(),
    'diasConsecutivos': diasConsecutivos,
    'alimentacionesHoy': alimentacionesHoy,
    'juegosHoy': juegosHoy,
    'curacionesHoy': curacionesHoy,
    'descansosHoy': descansosHoy,
    'ultimaAccionFecha': ultimaAccionFecha.toIso8601String(),
    'ultimoMinijuego': ultimoMinijuego.toIso8601String(),
    'bonusCooldownSegundos': bonusCooldownSegundos,
  };

  factory AlebrijeEstado.inicial() {
    final now = DateTime.now();
    return AlebrijeEstado(
      hambre: 100,
      felicidad: 100,
      salud: 100,
      energia: 100,
      ultimaAlimentacion: now,
      ultimaInteraccion: now,
      ultimoCuidado: now,
      diasConsecutivos: 1,
      alimentacionesHoy: 0,
      juegosHoy: 0,
      curacionesHoy: 0,
      descansosHoy: 0,
      ultimaAccionFecha: now,
    );
  }

  /// Calcula el decaimiento natural basado en tiempo transcurrido
  AlebrijeEstado aplicarDecaimiento() {
    final now = DateTime.now();
    final horasSinAlimentar = now.difference(ultimaAlimentacion).inHours;
    final horasSinInteractuar = now.difference(ultimaInteraccion).inHours;
    final horasSinCuidar = now.difference(ultimoCuidado).inHours;

    // Decaimiento: -5 puntos cada 6 horas
    final decaimientoHambre = (horasSinAlimentar / 6 * 5).round();
    final decaimientoFelicidad = (horasSinInteractuar / 8 * 5).round();
    final decaimientoSalud = (horasSinCuidar / 12 * 3).round();
    final decaimientoEnergia = (horasSinInteractuar / 4 * 5).round();

    // Resetear contadores si es una nueva hora
    final nuevosContadores = esNuevaHora
        ? {'alimentacionesHoy': 0, 'juegosHoy': 0, 'curacionesHoy': 0, 'descansosHoy': 0}
        : {'alimentacionesHoy': alimentacionesHoy, 'juegosHoy': juegosHoy, 'curacionesHoy': curacionesHoy, 'descansosHoy': descansosHoy};
    
    return AlebrijeEstado(
      hambre: (hambre - decaimientoHambre).clamp(0, 100),
      felicidad: (felicidad - decaimientoFelicidad).clamp(0, 100),
      salud: (salud - decaimientoSalud).clamp(0, 100),
      energia: (energia - decaimientoEnergia).clamp(0, 100),
      ultimaAlimentacion: ultimaAlimentacion,
      ultimaInteraccion: ultimaInteraccion,
      ultimoCuidado: ultimoCuidado,
      diasConsecutivos: _calcularDiasConsecutivos(now),
      alimentacionesHoy: nuevosContadores['alimentacionesHoy']!,
      juegosHoy: nuevosContadores['juegosHoy']!,
      curacionesHoy: nuevosContadores['curacionesHoy']!,
      descansosHoy: nuevosContadores['descansosHoy']!,
      ultimaAccionFecha: esNuevaHora ? now : ultimaAccionFecha,
    );
  }

  int _calcularDiasConsecutivos(DateTime now) {
    final diferenciaDias = now.difference(ultimaInteraccion).inDays;
    if (diferenciaDias == 0) return diasConsecutivos; // Mismo día
    if (diferenciaDias == 1) return diasConsecutivos + 1; // Día consecutivo
    return 1; // Se rompió la racha
  }

  /// Alimentar al alebrije (usando consultas médicas)
  AlebrijeEstado alimentar(int cantidad) {
    final ahora = DateTime.now();
    final resetearContadores = esNuevaHora;
    
    // Si ya alcanzó el límite y no es nueva hora, no hacer nada
    if (!puedeAlimentar && !resetearContadores) {
      return this;
    }
    
    return AlebrijeEstado(
      hambre: (hambre + cantidad).clamp(0, 100),
      felicidad: (felicidad + (cantidad * 0.3).round()).clamp(0, 100),
      salud: salud,
      energia: energia,
      ultimaAlimentacion: ahora,
      ultimaInteraccion: ahora,
      ultimoCuidado: ultimoCuidado,
      diasConsecutivos: diasConsecutivos,
      alimentacionesHoy: resetearContadores ? 1 : alimentacionesHoy + 1,
      juegosHoy: resetearContadores ? 0 : juegosHoy,
      curacionesHoy: resetearContadores ? 0 : curacionesHoy,
      descansosHoy: resetearContadores ? 0 : descansosHoy,
      ultimaAccionFecha: ahora,
      ultimoMinijuego: ultimoMinijuego,
      bonusCooldownSegundos: bonusCooldownSegundos,
    );
  }

  /// Jugar con el alebrije
  AlebrijeEstado jugar() {
    final ahora = DateTime.now();
    final resetearContadores = esNuevaHora;
    
    if (!puedeJugar && !resetearContadores) {
      return this;
    }
    
    return AlebrijeEstado(
      hambre: (hambre - 10).clamp(0, 100),
      felicidad: (felicidad + 20).clamp(0, 100),
      salud: (salud + 5).clamp(0, 100),
      energia: (energia - 15).clamp(0, 100),
      ultimaAlimentacion: ultimaAlimentacion,
      ultimaInteraccion: ahora,
      ultimoCuidado: ultimoCuidado,
      diasConsecutivos: diasConsecutivos,
      alimentacionesHoy: resetearContadores ? 0 : alimentacionesHoy,
      juegosHoy: resetearContadores ? 1 : juegosHoy + 1,
      curacionesHoy: resetearContadores ? 0 : curacionesHoy,
      descansosHoy: resetearContadores ? 0 : descansosHoy,
      ultimaAccionFecha: ahora,
      ultimoMinijuego: ultimoMinijuego,
      bonusCooldownSegundos: bonusCooldownSegundos,
    );
  }

  /// Curar al alebrije (usando vacunas)
  AlebrijeEstado curar(int cantidad) {
    final ahora = DateTime.now();
    final resetearContadores = esNuevaHora;
    
    if (!puedeCurar && !resetearContadores) {
      return this;
    }
    
    return AlebrijeEstado(
      hambre: hambre,
      felicidad: (felicidad + (cantidad * 0.2).round()).clamp(0, 100),
      salud: (salud + cantidad).clamp(0, 100),
      energia: (energia + (cantidad * 0.5).round()).clamp(0, 100),
      ultimaAlimentacion: ultimaAlimentacion,
      ultimaInteraccion: ahora,
      ultimoCuidado: ahora,
      diasConsecutivos: diasConsecutivos,
      alimentacionesHoy: resetearContadores ? 0 : alimentacionesHoy,
      juegosHoy: resetearContadores ? 0 : juegosHoy,
      curacionesHoy: resetearContadores ? 1 : curacionesHoy + 1,
      descansosHoy: resetearContadores ? 0 : descansosHoy,
      ultimaAccionFecha: ahora,
      ultimoMinijuego: ultimoMinijuego,
      bonusCooldownSegundos: bonusCooldownSegundos,
    );
  }

  /// Descansar (recuperar energía)
  AlebrijeEstado descansar() {
    final ahora = DateTime.now();
    final resetearContadores = esNuevaHora;
    
    if (!puedeDescansar && !resetearContadores) {
      return this;
    }
    
    return AlebrijeEstado(
      hambre: (hambre - 5).clamp(0, 100),
      felicidad: (felicidad + 10).clamp(0, 100),
      salud: (salud + 5).clamp(0, 100),
      energia: 100,
      ultimaAlimentacion: ultimaAlimentacion,
      ultimaInteraccion: ahora,
      ultimoCuidado: ultimoCuidado,
      diasConsecutivos: diasConsecutivos,
      alimentacionesHoy: resetearContadores ? 0 : alimentacionesHoy,
      juegosHoy: resetearContadores ? 0 : juegosHoy,
      curacionesHoy: resetearContadores ? 0 : curacionesHoy,
      descansosHoy: resetearContadores ? 1 : descansosHoy + 1,
      ultimaAccionFecha: ahora,
      ultimoMinijuego: ultimoMinijuego,
      bonusCooldownSegundos: bonusCooldownSegundos,
    );
  }
  
  /// 🎮 Registrar que se jugó un minijuego y agregar bonus de tiempo
  /// puntos: puntos obtenidos en el minijuego
  /// Cada 100 puntos = 30 segundos de bonus para el próximo juego
  AlebrijeEstado registrarMinijuego(int puntos) {
    final ahora = DateTime.now();
    // Calcular bonus: cada 100 puntos = 30 segundos de reducción
    final bonusGanado = (puntos / 100 * 30).round();
    // El bonus máximo es el cooldown completo (5 min = 300 seg)
    final nuevoBonus = (bonusCooldownSegundos + bonusGanado).clamp(0, cooldownMinijuegoSegundos);
    
    return AlebrijeEstado(
      hambre: hambre,
      felicidad: felicidad,
      salud: salud,
      energia: energia,
      ultimaAlimentacion: ultimaAlimentacion,
      ultimaInteraccion: ultimaInteraccion,
      ultimoCuidado: ultimoCuidado,
      diasConsecutivos: diasConsecutivos,
      alimentacionesHoy: alimentacionesHoy,
      juegosHoy: juegosHoy,
      curacionesHoy: curacionesHoy,
      descansosHoy: descansosHoy,
      ultimaAccionFecha: ultimaAccionFecha,
      ultimoMinijuego: ahora,
      bonusCooldownSegundos: nuevoBonus,
    );
  }
  
  /// 🔥 Usar el bonus acumulado (resetear después de jugar)
  AlebrijeEstado usarBonus() {
    return AlebrijeEstado(
      hambre: hambre,
      felicidad: felicidad,
      salud: salud,
      energia: energia,
      ultimaAlimentacion: ultimaAlimentacion,
      ultimaInteraccion: ultimaInteraccion,
      ultimoCuidado: ultimoCuidado,
      diasConsecutivos: diasConsecutivos,
      alimentacionesHoy: alimentacionesHoy,
      juegosHoy: juegosHoy,
      curacionesHoy: curacionesHoy,
      descansosHoy: descansosHoy,
      ultimaAccionFecha: ultimaAccionFecha,
      ultimoMinijuego: ultimoMinijuego,
      bonusCooldownSegundos: 0, // Resetear bonus después de usarlo
    );
  }
}

/// Registro de evolución
class EvolucionHistorial {
  final int nivel;
  final DateTime fecha;
  final String descripcion;

  EvolucionHistorial({
    required this.nivel,
    required this.fecha,
    required this.descripcion,
  });

  factory EvolucionHistorial.fromJson(Map<String, dynamic> json) {
    return EvolucionHistorial(
      nivel: json['nivel'] ?? 1,
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
      descripcion: json['descripcion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nivel': nivel,
    'fecha': fecha.toIso8601String(),
    'descripcion': descripcion,
  };
}
