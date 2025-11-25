import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/alebrije_model.dart';
import '../models/capsula_poder_model.dart';
import '../models/codigo_sanacion_model.dart';
import '../providers/session_provider.dart';
import '../services/api_service.dart';
import 'dart:math';

/// Proveedor de estado para el sistema de Alebrije Tamagotchi
class AlebrijeProvider extends ChangeNotifier {
  AlebrijeModel? _alebrije;
  bool _isLoading = false;
  String? _error;
  DateTime _ultimaActualizacion = DateTime.now();
  
  // 💊 Sistema de cápsulas
  List<CapsulaPoder> _capsulas = [];
  List<CapsulaPoder> _capsulasPendientes = []; // Cápsulas no aplicadas aún
  
  // 🏥 Sistema de códigos de sanación
  List<CodigoSanacion> _codigosUsados = []; // Historial de códigos aplicados

  AlebrijeModel? get alebrije => _alebrije;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Getters de cápsulas
  List<CapsulaPoder> get capsulasActivas => _capsulas.where((c) => c.estaActiva).toList();
  List<CapsulaPoder> get capsulasPendientes => _capsulasPendientes;
  List<CapsulaPoder> get todasLasCapsulas => _capsulas;
  
  // Efectos acumulados de cápsulas activas
  int get bonosSaludTotal => capsulasActivas.fold(0, (sum, c) => sum + c.bonosSalud);
  int get bonosHambreTotal => capsulasActivas.fold(0, (sum, c) => sum + c.bonosHambre);
  int get bonosFelicidadTotal => capsulasActivas.fold(0, (sum, c) => sum + c.bonosFelicidad);
  int get bonosEnergiaTotal => capsulasActivas.fold(0, (sum, c) => sum + c.bonosEnergia);
  double get multiplicadorExperienciaTotal => capsulasActivas.fold(1.0, (mult, c) => mult * c.multiplicadorExperiencia);
  double get reduccionDecaimientoTotal => capsulasActivas.fold(0.0, (sum, c) => sum + c.reduccionDecaimiento).clamp(0.0, 0.9);
  
  /// Genera o recupera el alebrije del estudiante
  Future<void> inicializarAlebrije(String matricula, {String? especieBase}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ⚠️ ESTRATEGIA DE SINCRONIZACIÓN FORZADA:
      // Azure Cosmos DB es la ÚNICA fuente de verdad
      // localStorage es solo caché temporal y se borra si difiere
      
      final token = prefs.getString('auth_token');
      if (token == null) {
        print('❌ No hay token de autenticación - requiere login');
        _error = 'Sesión expirada. Por favor inicia sesión nuevamente.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      AlebrijeModel? alebrijeBackend;
      try {
        alebrijeBackend = await _cargarDesdeBackend(token);
      } catch (e) {
        print('❌ Error al cargar desde Cosmos DB: $e');
        _error = 'No se pudo conectar con el servidor. Verifica tu conexión.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      if (alebrijeBackend != null) {
        // ✅ COSMOS DB TIENE DATOS - ESTA ES LA VERDAD ABSOLUTA
        print('✅ Alebrije recuperado desde Cosmos DB (Azure)');
        print('   - Nombre: ${alebrijeBackend.nombre}');
        print('   - Nivel: ${alebrijeBackend.nivelEvolucion}');
        print('   - DNA: ${alebrijeBackend.dna.especieBase}');
        
        // ⚠️ BORRAR SIEMPRE localStorage para evitar conflictos
        print('🗑️ Borrando localStorage anterior (Azure es la única fuente)');
        await prefs.remove('alebrije_data');
        await prefs.remove('alebrije_capsulas');
        
        _alebrije = alebrijeBackend;
        
        // Actualizar localStorage como caché (solo después de confirmar es correcto)
        await prefs.setString('alebrije_data', jsonEncode(_alebrije!.toJson()));
        
        // Cargar cápsulas
        final capsulasJson = prefs.getString('alebrije_capsulas');
        if (capsulasJson != null) {
          final List<dynamic> capsulasList = jsonDecode(capsulasJson);
          _capsulas = capsulasList.map((json) => CapsulaPoder.fromJson(json)).toList();
          _capsulas.removeWhere((c) => !c.estaActiva && c.duracion != null);
          print('💊 ${capsulasActivas.length} cápsulas activas cargadas');
        }
        
        // 🏥 Cargar historial de códigos de sanación
        await _cargarHistorialCodigos();
        
        // Aplicar decaimiento y terminar
        _alebrije = _alebrije!.copyWith(
          estado: _alebrije!.estado.aplicarDecaimiento(),
          updatedAt: DateTime.now(),
        );
        
        _ultimaActualizacion = DateTime.now();
        _isLoading = false;
        notifyListeners();
        await _verificarBonusDiario();
        _verificarNecesidadesYNotificar();
        return;
      }
      
      // PRIORIDAD 2: No existe en Cosmos DB - usuario nuevo debe elegir especie
      // Si especieBase es null, el usuario debe elegir primero
      if (especieBase == null) {
        print('🎨 Usuario nuevo: debe elegir especie de alebrije');
        _alebrije = null; // Mantener null para mostrar diálogo de selección
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Si se proporcionó especieBase, generar alebrije
      _alebrije = AlebrijeModel.generar(
        matricula: matricula,
        especieBase: especieBase,
      );
      
      print('🎨 Nuevo alebrije generado: ${_alebrije!.nombre} (${_alebrije!.dna.especieBase})');
      
      // Guardar inmediatamente el nuevo alebrije
      await _guardarEstado();

      // Aplicar decaimiento desde última actualización
      _alebrije = _alebrije!.copyWith(
        estado: _alebrije!.estado.aplicarDecaimiento(),
        updatedAt: DateTime.now(),
      );

      _ultimaActualizacion = DateTime.now();
      _isLoading = false;
      notifyListeners();

      // Verificar bonus diario por buen cuidado
      await _verificarBonusDiario();
      
      // Verificar si necesita atención
      _verificarNecesidadesYNotificar();
    } catch (e) {
      _error = 'Error al inicializar alebrije: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Alimentar al alebrije
  Future<void> alimentar(int cantidad) async {
    if (_alebrije == null) return;

    _alebrije = _alebrije!.copyWith(
      estado: _alebrije!.estado.alimentar(cantidad),
      updatedAt: DateTime.now(),
    );

    // Ganar experiencia por interacción (aumentado para progresión más rápida)
    await agregarExperiencia(15, 'Alimentar');
    
    await _guardarEstado();
    notifyListeners();
  }

  /// Jugar con el alebrije
  Future<void> jugar() async {
    if (_alebrije == null) return;

    _alebrije = _alebrije!.copyWith(
      estado: _alebrije!.estado.jugar(),
      updatedAt: DateTime.now(),
    );

    // Ganar experiencia por interacción (aumentado para progresión más rápida)
    await agregarExperiencia(25, 'Jugar');
    
    await _guardarEstado();
    notifyListeners();
  }
  
  /// Renombrar el alebrije
  Future<void> renombrar(String nuevoNombre) async {
    if (_alebrije == null) return;
    
    _alebrije = _alebrije!.copyWith(
      nombre: nuevoNombre,
      updatedAt: DateTime.now(),
    );
    
    print('✏️ Alebrije renombrado a: $nuevoNombre');
    await _guardarEstado();
    notifyListeners();
  }

  /// Curar al alebrije (se activa con vacunas)
  Future<void> curar(int cantidad) async {
    if (_alebrije == null) return;

    _alebrije = _alebrije!.copyWith(
      estado: _alebrije!.estado.curar(cantidad),
      updatedAt: DateTime.now(),
    );

    // Ganar experiencia por interacción (aumentado para progresión más rápida)
    await agregarExperiencia(30, 'Curar');
    
    await _guardarEstado();
    notifyListeners();
  }

  /// Descansar (recuperar energía)
  Future<void> descansar() async {
    if (_alebrije == null) return;

    _alebrije = _alebrije!.copyWith(
      estado: _alebrije!.estado.descansar(),
      updatedAt: DateTime.now(),
    );

    // Ganar experiencia por interacción (aumentado para progresión más rápida)
    await agregarExperiencia(20, 'Descansar');
    
    await _guardarEstado();
    notifyListeners();
  }

  /// Agregar experiencia y verificar evolución
  Future<void> agregarExperiencia(int puntos, String motivo) async {
    if (_alebrije == null) return;

    // Aplicar multiplicador de cápsulas activas
    final puntosConBonus = (puntos * multiplicadorExperienciaTotal).round();
    
    print('✨ GANANDO XP: +${puntosConBonus} XP por "$motivo"');
    if (puntosConBonus > puntos) {
      print('⚡ Bonus de cápsulas: ${puntos} XP → ${puntosConBonus} XP (x${multiplicadorExperienciaTotal.toStringAsFixed(2)})');
    }

    final xpAnterior = _alebrije!.puntosExperiencia;
    final nuevosOPuntos = xpAnterior + puntosConBonus;
    print('📊 XP: $xpAnterior → $nuevosOPuntos');
    final puntosParaNivel = _calcularPuntosNecesarios(_alebrije!.nivelEvolucion);

    if (nuevosOPuntos >= puntosParaNivel) {
      // ¡Evolución!
      await _evolucionar(motivo);
    } else {
      _alebrije = _alebrije!.copyWith(
        puntosExperiencia: nuevosOPuntos,
        updatedAt: DateTime.now(),
      );
      
      await _guardarEstado();
      notifyListeners();
    }
  }

  int _calcularPuntosNecesarios(int nivel) {
    // Fórmula ultra-rápida para progresión visible inmediata
    // Nivel 2: 30 XP (~2 acciones), Nivel 3: 52 XP, Nivel 4: 75 XP
    return (30 * pow(nivel, 1.25)).round();
  }

  /// Evoluciona el alebrije con mutaciones genéticas
  Future<void> _evolucionar(String motivo) async {
    if (_alebrije == null) return;

    final nuevoNivel = _alebrije!.nivelEvolucion + 1;
    final intensidadMutacion = 0.2 + (nuevoNivel * 0.05); // Más intenso en niveles altos
    final random = Random(DateTime.now().millisecondsSinceEpoch);

    // Mutar DNA
    final nuevoDNA = _alebrije!.dna.mutar(random, intensidadMutacion.clamp(0.0, 0.8));

    // Agregar a historial
    final nuevaEvolucion = EvolucionHistorial(
      nivel: nuevoNivel,
      fecha: DateTime.now(),
      descripcion: motivo,
    );

    _alebrije = _alebrije!.copyWith(
      dna: nuevoDNA,
      nivelEvolucion: nuevoNivel,
      puntosExperiencia: 0,
      historialEvoluciones: [..._alebrije!.historialEvoluciones, nuevaEvolucion],
      updatedAt: DateTime.now(),
    );

    print('🎉 ¡Evolución! Nivel $nuevoNivel alcanzado: $motivo');
    
    await _guardarEstado();
    notifyListeners();

    // Mostrar notificación visual de evolución
    _mostrarNotificacionEvolucion(nuevoNivel);
  }

  void _mostrarNotificacionEvolucion(int nivel) {
    // TODO: Implementar animación de evolución visual
    print('✨ Animación de evolución - Nivel $nivel');
  }

  /// 🗑️ Limpiar localStorage completamente (forzar recarga desde Azure)
  Future<void> limpiarCacheLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('alebrije_data');
      await prefs.remove('alebrije_capsulas');
      print('🗑️ localStorage limpiado completamente');
    } catch (e) {
      print('❌ Error limpiando localStorage: $e');
    }
  }

  /// 🔄 Forzar sincronización desde Azure (para resolver conflictos entre dispositivos)
  Future<void> forzarSincronizacionDesdeAzure() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('❌ No hay token para sincronizar');
        return;
      }
      
      // 🗑️ LIMPIAR localStorage primero
      print('🗑️ Limpiando localStorage antes de sincronizar...');
      await prefs.remove('alebrije_data');
      await prefs.remove('alebrije_capsulas');
      
      print('🔄 Forzando sincronización desde Azure Cosmos DB...');
      final alebrijeBackend = await _cargarDesdeBackend(token);
      
      if (alebrijeBackend != null) {
        // Mostrar lo que viene de Azure
        if (_alebrije != null) {
          if (_alebrije!.nombre != alebrijeBackend.nombre ||
              _alebrije!.dna.especieBase != alebrijeBackend.dna.especieBase ||
              _alebrije!.nivelEvolucion != alebrijeBackend.nivelEvolucion) {
            print('🔄 REEMPLAZANDO versión local con Azure');
            print('   Local: ${_alebrije!.nombre} Lv.${_alebrije!.nivelEvolucion}');
            print('   Azure: ${alebrijeBackend.nombre} Lv.${alebrijeBackend.nivelEvolucion}');
          }
        }
        
        // Azure SIEMPRE gana - NO GUARDAR EN localStorage
        _alebrije = alebrijeBackend;
        print('✅ Sincronizado SOLO desde Azure: ${_alebrije!.nombre} Lv.${_alebrije!.nivelEvolucion}');
        print('🚫 localStorage NO actualizado (Azure es la única fuente)');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error en sincronización forzada: $e');
    }
  }

  /// Guarda el estado del alebrije - SOLO EN AZURE (sin localStorage)
  Future<void> _guardarEstado() async {
    if (_alebrije == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('❌ No hay token - sesión expirada');
        throw Exception('Sesión expirada - requiere login');
      }
      
      // 🔥 GUARDAR EN AZURE (prioridad) + localStorage (respaldo)
      print('🔄 Guardando estado en Azure Cosmos DB...');
      print('   - Nombre: ${_alebrije!.nombre}');
      print('   - Nivel: ${_alebrije!.nivelEvolucion}');
      print('   - XP: ${_alebrije!.puntosExperiencia}');
      
      await _sincronizarConBackend(token);
      print('✅ Estado guardado EXITOSAMENTE en Azure Cosmos DB');
      
      // 💾 GUARDAR TAMBIÉN EN localStorage como respaldo (previene pérdida de datos)
      await prefs.setString('alebrije_data', jsonEncode(_alebrije!.toJson()));
      print('💾 Respaldo guardado en localStorage');
      
      _ultimaActualizacion = DateTime.now();
    } catch (e) {
      print('❌ FALLO CRÍTICO: No se pudo guardar en Azure: $e');
      // NO guardar nada si Azure falla
      rethrow;
    }
  }

  /// Verifica necesidades y genera notificaciones
  void _verificarNecesidadesYNotificar() {
    if (_alebrije == null) return;

    final necesidades = <String>[];

    if (_alebrije!.estado.hambre < 30) {
      necesidades.add('Tu alebrije tiene hambre 🍽️');
    }
    if (_alebrije!.estado.felicidad < 30) {
      necesidades.add('Tu alebrije se siente solo 😢');
    }
    if (_alebrije!.estado.salud < 30) {
      necesidades.add('Tu alebrije necesita atención médica 🏥');
    }
    if (_alebrije!.estado.energia < 30) {
      necesidades.add('Tu alebrije necesita descansar 😴');
    }

    if (necesidades.isNotEmpty) {
      print('⚠️ Necesidades del alebrije: ${necesidades.join(', ')}');
      // TODO: Implementar notificaciones push
    }
  }

  /// Verifica y otorga bonus cada 4 horas por mantener todas las barras >50%
  Future<void> _verificarBonusDiario() async {
    if (_alebrije == null) return;

    final prefs = await SharedPreferences.getInstance();
    final ultimoBonusStr = prefs.getString('alebrije_ultimo_bonus_${_alebrije!.matricula}');
    final ahora = DateTime.now();
    
    // Verificar si ya se otorgó bonus en la última hora (progresión rápida)
    if (ultimoBonusStr != null) {
      final ultimoBonus = DateTime.parse(ultimoBonusStr);
      final diferenciaMinutos = ahora.difference(ultimoBonus).inMinutes;
      
      if (diferenciaMinutos < 60) {
        // Ya se otorgó bonus recientemente
        final minutosRestantes = 60 - diferenciaMinutos;
        print('⏰ Próximo bonus en $minutosRestantes minuto(s)');
        return;
      }
    }

    // Verificar si todas las barras están >50%
    final estado = _alebrije!.estado;
    final todasBarrasAltas = estado.hambre > 50 &&
                               estado.felicidad > 50 &&
                               estado.salud > 50 &&
                               estado.energia > 50;

    if (todasBarrasAltas) {
      print('🌟 ¡BONUS DE CUIDADO! Todas las barras >50%');
      await agregarExperiencia(50, 'Bonus por buen cuidado');
      
      // Guardar el timestamp del último bonus
      await prefs.setString('alebrije_ultimo_bonus_${_alebrije!.matricula}', ahora.toIso8601String());
    } else {
      print('💡 Mantén todas las barras >50% para recibir +50 XP cada hora');
    }
  }

  /// Actualiza el estado aplicando decaimiento natural
  Future<void> actualizarEstado() async {
    if (_alebrije == null) return;

    // 🔄 SIEMPRE sincronizar desde Azure primero
    print('🔄 Sincronizando desde Azure antes de actualizar estado...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final alebrijeAzure = await _cargarDesdeBackend(token);
        if (alebrijeAzure != null) {
          _alebrije = alebrijeAzure;
          print('✅ Estado sincronizado desde Azure');
        }
      }
    } catch (e) {
      print('⚠️ No se pudo sincronizar desde Azure: $e');
    }

    final ahora = DateTime.now();
    final horasTranscurridas = ahora.difference(_ultimaActualizacion).inHours;

    if (horasTranscurridas >= 1) {
      _alebrije = _alebrije!.copyWith(
        estado: _alebrije!.estado.aplicarDecaimiento(),
        updatedAt: ahora,
      );

      _ultimaActualizacion = ahora;
      await _guardarEstado();
      notifyListeners();

      _verificarNecesidadesYNotificar();
    }
  }

  /// Obtiene el título del nivel de evolución
  String getNombreNivel(int nivel) {
    if (nivel <= 1) return '🥚 Huevo Místico';
    if (nivel <= 3) return '🌱 Criatura Naciente';
    if (nivel <= 5) return '🌟 Espíritu en Crecimiento';
    if (nivel <= 7) return '✨ Guardián Joven';
    if (nivel <= 10) return '🔥 Protector Ancestral';
    if (nivel <= 15) return '👑 Alebrije Legendario';
    return '🌌 Leyenda Viviente';
  }

  /// Obtiene el progreso hacia el siguiente nivel (0.0 - 1.0)
  double getProgresoNivel() {
    if (_alebrije == null) return 0.0;
    final necesarios = _calcularPuntosNecesarios(_alebrije!.nivelEvolucion);
    return (_alebrije!.puntosExperiencia / necesarios).clamp(0.0, 1.0);
  }

  /// Exponer método de cálculo de puntos (para uso en UI)
  int calcularPuntosNecesarios(int nivel) {
    return _calcularPuntosNecesarios(nivel);
  }

  /// Cambiar de alebrije (solo si alcanzó nivel máximo o está en bajo nivel)
  Future<bool> puedeCambiarAlebrije() async {
    if (_alebrije == null) return true;
    // Permitir cambio si está en nivel 1-3 (recién empezado) o nivel 16+ (completado)
    return _alebrije!.nivelEvolucion <= 3 || _alebrije!.nivelEvolucion >= 16;
  }

  /// Guardar alebrije actual en colección y crear uno nuevo
  Future<void> cambiarAlebrije(String matricula, String nuevaEspecie) async {
    if (_alebrije != null) {
      // Guardar alebrije actual en colección
      final prefs = await SharedPreferences.getInstance();
      final coleccion = prefs.getStringList('coleccion_alebrijes') ?? [];
      coleccion.add(jsonEncode(_alebrije!.toJson()));
      await prefs.setStringList('coleccion_alebrijes', coleccion);
      print('📚 Alebrije guardado en colección: ${_alebrije!.nombre}');
    }

    // Crear nuevo alebrije
    _alebrije = null;
    await inicializarAlebrije(matricula, especieBase: nuevaEspecie);
  }

  /// Obtener colección de alebrijes anteriores
  Future<List<AlebrijeModel>> getColeccion() async {
    final prefs = await SharedPreferences.getInstance();
    final coleccion = prefs.getStringList('coleccion_alebrijes') ?? [];
    return coleccion.map((json) => AlebrijeModel.fromJson(jsonDecode(json))).toList();
  }

  /// Carga alebrije desde backend
  Future<AlebrijeModel?> _cargarDesdeBackend(String token) async {
    try {
      final data = await ApiService.getAlebrije(token);
      if (data != null) {
        return AlebrijeModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Error cargando desde backend: $e');
      return null;
    }
  }

  /// Sincroniza alebrije con backend (Cosmos DB)
  Future<void> _sincronizarConBackend(String token) async {
    if (_alebrije == null) return;
    
    try {
      print('🔄 Intentando sincronizar con Cosmos DB...');
      
      // Verificar si ya existe en backend
      final existeEnBackend = await ApiService.getAlebrije(token);
      
      if (existeEnBackend == null) {
        // Crear nuevo en Cosmos DB (contenedor: alebrijes_estudiantes)
        await ApiService.createAlebrije(token, _alebrije!.toJson());
        print('✅ Alebrije creado en Cosmos DB (alebrijes_estudiantes)');
        print('   - Nombre: ${_alebrije!.nombre}');
        print('   - Matrícula: ${_alebrije!.matricula}');
        print('   - Especie: ${_alebrije!.dna.especieBase}');
      } else {
        // Actualizar existente en Cosmos DB
        final jsonData = _alebrije!.toJson();
        print('📤 ENVIANDO a Cosmos DB:');
        print('   - Nombre: ${_alebrije!.nombre}');
        print('   - Nivel: ${_alebrije!.nivelEvolucion}');
        print('   - XP: ${_alebrije!.puntosExperiencia}');
        print('   - Hambre: ${_alebrije!.estado.hambre}');
        
        await ApiService.updateAlebrije(token, jsonData);
        print('✅ Alebrije actualizado EXITOSAMENTE en Cosmos DB');
      }
    } catch (e) {
      // No interrumpir si falla sincronización - localStorage es suficiente
      print('⚠️ Sincronización con Cosmos DB falló (continuando con localStorage)');
      print('   Error: $e');
      print('   💡 Verifica que el contenedor "alebrijes_estudiantes" exista en SASU');
    }
  }
}

/// Extensión para copiar AlebrijeModel con cambios
extension AlebrijeModelCopyWith on AlebrijeModel {
  AlebrijeModel copyWith({
    String? id,
    String? matricula,
    String? nombre,
    AlebrijeDNA? dna,
    AlebrijeEstado? estado,
    List<EvolucionHistorial>? historialEvoluciones,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? nivelEvolucion,
    int? puntosExperiencia,
  }) {
    return AlebrijeModel(
      id: id ?? this.id,
      matricula: matricula ?? this.matricula,
      nombre: nombre ?? this.nombre,
      dna: dna ?? this.dna,
      estado: estado ?? this.estado,
      historialEvoluciones: historialEvoluciones ?? this.historialEvoluciones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nivelEvolucion: nivelEvolucion ?? this.nivelEvolucion,
      puntosExperiencia: puntosExperiencia ?? this.puntosExperiencia,
    );
  }
}

/// Widget para integrar en SessionProvider y conectar con actividades de salud
class AlebrijeHealthIntegration {
  final AlebrijeProvider alebrijeProvider;

  AlebrijeHealthIntegration(this.alebrijeProvider);

  /// Se llama cuando el usuario tiene una consulta médica
  Future<void> onConsultaMedica() async {
    await alebrijeProvider.alimentar(30); // +30 hambre
    await alebrijeProvider.agregarExperiencia(50, 'Consulta médica realizada');
    
    // 💊 Dar cápsula como recompensa
    final capsula = CapsulaPowerGenerator.generarCapsula('Consulta Médica');
    await alebrijeProvider.agregarCapsula(capsula);
    
    print('🍽️ Alebrije alimentado por consulta médica');
    print('💊 Cápsula obtenida: ${capsula.nombre} [${CapsulaPowerGenerator.getNombreRareza(capsula.rareza)}]');
  }

  /// Se llama cuando el usuario recibe una vacuna
  Future<void> onVacuna() async {
    await alebrijeProvider.curar(40); // +40 salud
    await alebrijeProvider.agregarExperiencia(100, 'Vacuna administrada');
    
    // 💊 Dar cápsula como recompensa
    final capsula = CapsulaPowerGenerator.generarCapsula('Vacunación');
    await alebrijeProvider.agregarCapsula(capsula);
    
    print('💉 Alebrije curado por vacuna');
    print('💊 Cápsula obtenida: ${capsula.nombre} [${CapsulaPowerGenerator.getNombreRareza(capsula.rareza)}]');
  }

  /// Se llama cuando el usuario completa un curso (SaberesMX)
  Future<void> onCursoCompletado(String nombreCurso) async {
    await alebrijeProvider.jugar(); // +20 felicidad
    await alebrijeProvider.agregarExperiencia(150, 'Curso completado: $nombreCurso');
    print('📚 Alebrije recompensado por curso completado');
  }

  /// Se llama cuando el usuario se registra como donante de órganos
  Future<void> onDonacionOrganos() async {
    await alebrijeProvider.curar(50);
    await alebrijeProvider.agregarExperiencia(250, 'Registro como donante de órganos');
    print('❤️ Alebrije recompensado por compromiso solidario');
  }

  /// Se llama cuando el usuario abre la app diariamente (racha)
  Future<void> onAbrirAppDiario() async {
    await alebrijeProvider.actualizarEstado();
    
    final diasConsecutivos = alebrijeProvider.alebrije?.estado.diasConsecutivos ?? 0;
    if (diasConsecutivos > 1) {
      final bonus = (diasConsecutivos * 10).clamp(0, 100);
      await alebrijeProvider.agregarExperiencia(bonus, 'Racha de $diasConsecutivos días');
      print('🔥 Bonus por racha: $diasConsecutivos días consecutivos');
    }
  }
  
  /// Se llama cuando el usuario obtiene una cápsula (consulta/vacuna)
  Future<void> onCapsulaObtenida(String servicioSalud) async {
    final capsula = CapsulaPowerGenerator.generarCapsula(servicioSalud);
    await alebrijeProvider.agregarCapsula(capsula);
    print('💊 Cápsula ${capsula.nombre} obtenida (${CapsulaPowerGenerator.getNombreRareza(capsula.rareza)})');
  }
}

/// Extensión del AlebrijeProvider para sistema de cápsulas
extension AlebrijeProviderCapsulas on AlebrijeProvider {
  /// Agrega una nueva cápsula obtenida (va a pendientes)
  Future<void> agregarCapsula(CapsulaPoder capsula) async {
    _capsulasPendientes.add(capsula);
    print('💊 Cápsula obtenida: ${capsula.nombre} (${CapsulaPowerGenerator.getNombreRareza(capsula.rareza)})');
    
    // Sincronizar con backend (opcional, no bloquea)
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        await ApiService.registrarCapsula(token, capsula.toJson(), capsula.origenServicio);
      }
    } catch (e) {
      print('⚠️ Error al sincronizar cápsula con backend: $e');
    }
    
    await _guardarEstado();
    notifyListeners();
  }
  
  /// Aplica una cápsula pendiente al alebrije
  Future<void> aplicarCapsula(String capsulaId) async {
    final index = _capsulasPendientes.indexWhere((c) => c.id == capsulaId);
    if (index == -1) {
      print('❌ Cápsula no encontrada: $capsulaId');
      return;
    }
    
    final capsula = _capsulasPendientes.removeAt(index);
    
    // Activar la cápsula
    final capsulaActivada = capsula.copyWith(
      activa: true,
      activadaEn: DateTime.now(),
    );
    
    _capsulas.add(capsulaActivada);
    
    // Aplicar efectos inmediatos si los hay
    if (_alebrije != null) {
      final estadoActual = _alebrije!.estado;
      final nuevoEstado = AlebrijeEstado(
        hambre: (estadoActual.hambre + capsulaActivada.bonosHambre).clamp(0, 100),
        felicidad: (estadoActual.felicidad + capsulaActivada.bonosFelicidad).clamp(0, 100),
        salud: (estadoActual.salud + capsulaActivada.bonosSalud).clamp(0, 100),
        energia: (estadoActual.energia + capsulaActivada.bonosEnergia).clamp(0, 100),
        diasConsecutivos: estadoActual.diasConsecutivos,
        ultimaAlimentacion: estadoActual.ultimaAlimentacion,
        ultimaInteraccion: DateTime.now(),
        ultimoCuidado: estadoActual.ultimoCuidado,
      );
      
      _alebrije = _alebrije!.copyWith(
        estado: nuevoEstado,
        updatedAt: DateTime.now(),
      );
    }
    
    print('✨ Cápsula aplicada: ${capsulaActivada.nombre}');
    if (capsulaActivada.duracion != null) {
      print('⏱️ Duración: ${capsulaActivada.duracion!.inHours}h');
    } else {
      print('🎯 Efecto PERMANENTE');
    }
    
    await _guardarEstado();
    notifyListeners();
  }
  
  /// Elimina cápsulas expiradas
  Future<void> limpiarCapsulasExpiradas() async {
    final antes = _capsulas.length;
    _capsulas.removeWhere((c) => !c.estaActiva && c.duracion != null);
    
    if (_capsulas.length < antes) {
      print('🧹 ${antes - _capsulas.length} cápsulas expiradas eliminadas');
      await _guardarEstado();
      notifyListeners();
    }
  }
  
  /// Obtiene estadísticas totales con bonos de cápsulas
  Map<String, int> getEstadisticasConBonos() {
    if (_alebrije == null) return {};
    
    final estado = _alebrije!.estado;
    return {
      'hambre': (estado.hambre + bonosHambreTotal).clamp(0, 100),
      'felicidad': (estado.felicidad + bonosFelicidadTotal).clamp(0, 100),
      'salud': (estado.salud + bonosSaludTotal).clamp(0, 100),
      'energia': (estado.energia + bonosEnergiaTotal).clamp(0, 100),
    };
  }

  // ========================================
  // 🏥 SISTEMA DE CÓDIGOS DE SANACIÓN
  // ========================================

  /// Aplica un código de sanación proporcionado por personal médico
  Future<Map<String, dynamic>> aplicarCodigoSanacion(String codigoIngresado) async {
    if (_alebrije == null) {
      return {
        'exito': false,
        'mensaje': 'No hay alebrije para curar',
      };
    }

    // Validar formato del código (6 caracteres alfanuméricos)
    if (codigoIngresado.length != 6) {
      return {
        'exito': false,
        'mensaje': '❌ Código inválido. Debe tener 6 caracteres.',
      };
    }

    // Verificar si el código ya fue usado
    if (_codigosUsados.any((c) => c.codigo == codigoIngresado.toUpperCase())) {
      return {
        'exito': false,
        'mensaje': '🚫 Este código ya fue utilizado anteriormente.',
      };
    }

    // 🔑 VALIDAR CÓDIGO CONTRA BACKEND
    // Por ahora, simularemos validación local
    // TODO: Implementar validación en backend contra base de datos de códigos
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        return {
          'exito': false,
          'mensaje': '❌ Sesión expirada',
        };
      }

      // TODO: Llamar a backend para validar código
      // final codigoValido = await ApiService.validarCodigoSanacion(token, codigoIngresado);
      
      // SIMULACIÓN: Crear código de ejemplo para pruebas
      final codigo = _simularValidacionCodigo(codigoIngresado);
      
      if (codigo == null) {
        return {
          'exito': false,
          'mensaje': '❌ Código no válido o expirado. Consulta con el personal médico.',
        };
      }

      // Aplicar efectos curativos
      print('🏥 Aplicando código de sanación: ${codigo.nombreTipo}');
      print('   Especialista: ${codigo.especialista}');
      print('   Restauración: Salud +${codigo.restauracionSalud}, Felicidad +${codigo.restauracionFelicidad}');

      final estadoActual = _alebrije!.estado;
      final estadoCurado = AlebrijeEstado(
        hambre: (estadoActual.hambre + codigo.restauracionHambre).clamp(0, 100),
        felicidad: (estadoActual.felicidad + codigo.restauracionFelicidad).clamp(0, 100),
        salud: (estadoActual.salud + codigo.restauracionSalud).clamp(0, 100),
        energia: (estadoActual.energia + codigo.restauracionEnergia).clamp(0, 100),
        ultimaAlimentacion: estadoActual.ultimaAlimentacion,
        ultimaInteraccion: DateTime.now(),
        ultimoCuidado: DateTime.now(), // ✅ Marca como curado
        diasConsecutivos: estadoActual.diasConsecutivos,
        // 🩺 RESETEAR CONTADORES si es emergencia (cura enfermedad por exceso)
        alimentacionesHoy: codigo.tipo == TipoCodigoSanacion.emergencia ? 0 : estadoActual.alimentacionesHoy,
        juegosHoy: codigo.tipo == TipoCodigoSanacion.emergencia ? 0 : estadoActual.juegosHoy,
        curacionesHoy: estadoActual.curacionesHoy,
        ultimaAccionFecha: estadoActual.ultimaAccionFecha,
      );

      _alebrije = _alebrije!.copyWith(
        estado: estadoCurado,
        updatedAt: DateTime.now(),
      );

      // Marcar código como usado y guardar en historial
      final codigoUsado = codigo.copyWith(usado: true);
      _codigosUsados.add(codigoUsado);
      
      // Guardar historial de códigos
      await prefs.setString('codigos_sanacion_usados', 
        jsonEncode(_codigosUsados.map((c) => c.toJson()).toList())
      );

      await _guardarEstado();
      notifyListeners();

      return {
        'exito': true,
        'mensaje': '✅ ${codigo.emoji} ${codigo.nombreTipo}\n'
                  '🩺 Atendido por: ${codigo.especialista}\n'
                  '💚 Salud restaurada: +${codigo.restauracionSalud}\n'
                  '😊 Felicidad: +${codigo.restauracionFelicidad}\n'
                  '${codigo.tipo == TipoCodigoSanacion.emergencia ? "⚡ ¡Contadores reseteados!" : ""}',
        'codigo': codigo,
      };
    } catch (e) {
      print('❌ Error aplicando código: $e');
      return {
        'exito': false,
        'mensaje': '❌ Error al aplicar el código. Inténtalo nuevamente.',
      };
    }
  }

  /// SIMULACIÓN: Valida código localmente (será reemplazado por backend)
  CodigoSanacion? _simularValidacionCodigo(String codigo) {
    final codigoUpper = codigo.toUpperCase();
    
    // 🔑 CÓDIGOS DE PRUEBA (en producción vendrían del backend)
    final codigosPrueba = {
      'MED123': CodigoSanacion.generar(
        tipo: TipoCodigoSanacion.consulta,
        especialista: 'Dra. María García',
        validezHoras: const Duration(hours: 24),
      ),
      'PSI456': CodigoSanacion.generar(
        tipo: TipoCodigoSanacion.psicologia,
        especialista: 'Psic. Juan Pérez',
        validezHoras: const Duration(hours: 48),
      ),
      'NUT789': CodigoSanacion.generar(
        tipo: TipoCodigoSanacion.nutricion,
        especialista: 'Lic. Ana López',
        validezHoras: const Duration(hours: 24),
      ),
      'ENF321': CodigoSanacion.generar(
        tipo: TipoCodigoSanacion.enfermeria,
        especialista: 'Enf. Carlos Ruiz',
        validezHoras: const Duration(hours: 12),
      ),
      'EMG911': CodigoSanacion.generar(
        tipo: TipoCodigoSanacion.emergencia,
        especialista: 'Dr. Emergency',
        validezHoras: const Duration(hours: 6),
      ),
    };

    // Sobrescribir código generado con el ingresado
    if (codigosPrueba.containsKey(codigoUpper)) {
      final codigoBase = codigosPrueba[codigoUpper]!;
      return CodigoSanacion(
        codigo: codigoUpper,
        tipo: codigoBase.tipo,
        especialista: codigoBase.especialista,
        generadoEn: codigoBase.generadoEn,
        expiraEn: codigoBase.expiraEn,
        usado: false,
        restauracionSalud: codigoBase.restauracionSalud,
        restauracionFelicidad: codigoBase.restauracionFelicidad,
        restauracionHambre: codigoBase.restauracionHambre,
        restauracionEnergia: codigoBase.restauracionEnergia,
        curaEnfermedad: codigoBase.curaEnfermedad,
      );
    }

    return null; // Código no válido
  }

  /// Obtiene el historial de códigos usados
  List<CodigoSanacion> get codigosUsados => _codigosUsados;

  /// Carga historial de códigos al inicializar
  Future<void> _cargarHistorialCodigos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final codigosJson = prefs.getString('codigos_sanacion_usados');
      
      if (codigosJson != null) {
        final List<dynamic> lista = jsonDecode(codigosJson);
        _codigosUsados = lista.map((json) => CodigoSanacion.fromJson(json)).toList();
        print('📋 ${_codigosUsados.length} códigos de sanación en historial');
      }
    } catch (e) {
      print('⚠️ Error cargando historial de códigos: $e');
    }
  }
}
