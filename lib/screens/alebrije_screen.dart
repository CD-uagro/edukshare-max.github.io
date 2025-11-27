import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:math';
import '../providers/alebrije_provider.dart';
import '../providers/session_provider.dart';
import '../services/alebrije_generator.dart';
import 'minijuego_screen.dart';
import '../models/capsula_poder_model.dart';
import '../models/alebrije_model.dart';

/// Pantalla principal de interacción con el Alebrije Tamagotchi
class AlebrijeScreen extends StatefulWidget {
  const AlebrijeScreen({Key? key}) : super(key: key);

  @override
  State<AlebrijeScreen> createState() => _AlebrijeScreenState();
}

class _AlebrijeScreenState extends State<AlebrijeScreen> with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _bounceController;
  late AnimationController _shakeController;
  late AnimationController _sparkleController;
  
  // 🎭 Nuevas animaciones autónomas
  late AnimationController _walkController;
  late AnimationController _jumpController;
  late AnimationController _blinkController;
  late AnimationController _tailController;
  late AnimationController _mouthController;
  
  bool _mostrarHistorial = false;
  String _estadoEmocional = 'neutral'; // neutral, feliz, triste, hambriento, jugueton, cansado
  bool _estaSiendoTocado = false;
  int _toquesConsecutivos = 0;
  DateTime? _ultimoToque;
  
  // 🚶 Estado de movimiento autónomo
  double _posicionX = 0.0; // -1.0 a 1.0 (izquierda a derecha)
  double _posicionY = 0.0; // Para saltos
  int _direccion = 1; // 1 = derecha, -1 = izquierda
  bool _estaCaminando = false;
  bool _estaSaltando = false;
  bool _verificacionAzureCompleta = false; // Control para mostrar selector después de verificar Azure
  
  final List<Offset> _particulas = [];
  final List<String> _mensajesAlebrije = [];
  final List<Map<String, dynamic>> _xpFlotantes = []; // Lista de XP ganados flotando
  final List<Map<String, dynamic>> _croquetas = []; // Lista de croquetas cayendo

  @override
  void initState() {
    super.initState();
    
    // Animación de respiración (siempre activa)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    // Animación de rebote (para cuando está feliz)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Animación de sacudida (para llamar atención)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    
    // Animación de brillos/partículas
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // 🚶 Animación de caminar (movimiento lateral)
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // 🦘 Animación de salto
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // 👁️ Animación de parpadeo
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    // 🦎 Animación de cola/alas
    _tailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // 🍖 Animación de comer (boca abriéndose)
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    // 🍗 Croquetas cayendo
    final List<Map<String, dynamic>> _croquetas = []; // Lista de croquetas cayendo

    // ⏱️ Cargar alebrije CON DELAY para evitar 429 rate limiting
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final alebrijeProvider = context.read<AlebrijeProvider>();
      final sessionProvider = context.read<SessionProvider>();
      final matricula = sessionProvider.carnet?.matricula ?? '15662';
      
      // Timeout de respaldo: si todo tarda demasiado (45s), mostrar interfaz
      Future.delayed(const Duration(seconds: 45), () {
        if (mounted && !_verificacionAzureCompleta) {
          print('⏱️ Timeout de respaldo: mostrando interfaz después de 45 segundos');
          setState(() => _verificacionAzureCompleta = true);
        }
      });
      
      // Esperar 2 segundos para evitar conflictos con otras llamadas
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Intentar cargar desde Azure
      if (alebrijeProvider.alebrije == null && !alebrijeProvider.isLoading) {
        print('🔍 Iniciando carga de alebrije desde Azure...');
        await alebrijeProvider.inicializarAlebrije(matricula);
        
        // Después de inicializar, verificar resultado
        if (mounted) {
          setState(() => _verificacionAzureCompleta = true);

          print('🔍 DEBUG: Verificación Azure completada');
          print('   - alebrijeProvider.alebrije: ${alebrijeProvider.alebrije != null ? "ENCONTRADO" : "NULL"}');
          print('   - alebrijeProvider.isLoading: ${alebrijeProvider.isLoading}');
          print('   - alebrijeProvider.error: ${alebrijeProvider.error}');

          if (alebrijeProvider.alebrije != null) {
            print('✅ Alebrije encontrado y cargado desde Azure');
            _evaluarEstadoEmocional();
            _iniciarAnimacionesAutomaticas();
            _iniciarMovimientosAutonomos();
            _iniciarParpadeoAleatorio();
            _iniciarSincronizacionPeriodica();
          } else {
            print('ℹ️ No se encontró alebrije en Azure - mostrando selector de especie');
            // El widget mostrará automáticamente la pantalla de selección
          }
        }
      } else if (alebrijeProvider.alebrije != null) {
        // 🔄 FORZAR sincronización desde Azure al abrir la pantalla
        await alebrijeProvider.forzarSincronizacionDesdeAzure();
        await alebrijeProvider.actualizarEstado();
        
        if (mounted) {
          setState(() => _verificacionAzureCompleta = true);
          _evaluarEstadoEmocional();
          _iniciarAnimacionesAutomaticas();
          _iniciarMovimientosAutonomos();
          _iniciarParpadeoAleatorio();
          _iniciarSincronizacionPeriodica();
        }
      }
    });
  }
  
  void _iniciarAnimacionesAutomaticas() {
    // Cada 10 segundos, el alebrije hace algo aleatorio
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _animacionAleatoria();
        _iniciarAnimacionesAutomaticas();
      }
    });
  }
  
  // 🚶 Movimiento autónomo del alebrije
  void _iniciarMovimientosAutonomos() {
    _cicloMovimiento();
  }
  
  void _cicloMovimiento() {
    if (!mounted) return;
    
    // Verificar que el alebrije existe antes de animar
    final provider = context.read<AlebrijeProvider>();
    if (provider.alebrije == null) {
      // Reintentar en 2 segundos si aún no carga
      Future.delayed(const Duration(seconds: 2), () {
        _cicloMovimiento();
      });
      return;
    }
    
    final random = Random();
    final accion = random.nextInt(100);
    
    if (accion < 40) {
      // 40% - Caminar
      _caminarHaciaDestino();
    } else if (accion < 55) {
      // 15% - Saltar
      _ejecutarSalto();
    } else {
      // 45% - Quedarse quieto
      Future.delayed(Duration(seconds: random.nextInt(3) + 2), () {
        _cicloMovimiento();
      });
    }
  }
  
  void _caminarHaciaDestino() {
    if (!mounted || _estaCaminando) return;
    
    _estaCaminando = true;
    final random = Random();
    
    // Elegir destino aleatorio (-0.8 a 0.8 para no salirse de pantalla)
    final destinoX = (random.nextDouble() * 1.6) - 0.8;
    _direccion = destinoX > _posicionX ? 1 : -1;
    
    _walkController.duration = Duration(
      milliseconds: ((destinoX - _posicionX).abs() * 3000).toInt(),
    );
    
    _walkController.forward(from: 0).then((_) {
      setState(() {
        _posicionX = destinoX;
        _estaCaminando = false;
      });
      
      // Esperar un poco antes del siguiente movimiento
      Future.delayed(Duration(seconds: random.nextInt(3) + 1), () {
        _cicloMovimiento();
      });
    });
    
    // Animar la posición
    final Tween<double> movimiento = Tween(begin: _posicionX, end: destinoX);
    _walkController.addListener(() {
      if (mounted) {
        setState(() {
          _posicionX = movimiento.evaluate(_walkController);
        });
      }
    });
  }
  
  void _ejecutarSalto() {
    if (_estaSaltando) return;
    
    _estaSaltando = true;
    _jumpController.forward(from: 0).then((_) {
      _estaSaltando = false;
      // Continuar ciclo después del salto
      Future.delayed(const Duration(seconds: 1), () {
        _cicloMovimiento();
      });
    });
  }
  
  // 👁️ Parpadeo aleatorio del alebrije
  void _iniciarParpadeoAleatorio() {
    if (!mounted) return;
    
    // Verificar que existe el alebrije
    final provider = context.read<AlebrijeProvider>();
    if (provider.alebrije == null) {
      Future.delayed(const Duration(seconds: 2), () {
        _iniciarParpadeoAleatorio();
      });
      return;
    }
    
    final random = Random();
    final tiempoHastaParpadeo = random.nextInt(5) + 2; // 2-7 segundos
    
    Future.delayed(Duration(seconds: tiempoHastaParpadeo), () {
      if (mounted) {
        _blinkController.forward(from: 0).then((_) {
          _blinkController.reverse();
        });
        _iniciarParpadeoAleatorio();
      }
    });
  }

  void _iniciarSincronizacionPeriodica() {
    // 🔄 Sincronizar desde Azure cada 2 minutos para mantener consistencia entre dispositivos
    Future.delayed(const Duration(minutes: 2), () async {
      if (mounted) {
        print('⏰ Sincronización automática desde Azure...');
        final alebrijeProvider = context.read<AlebrijeProvider>();
        await alebrijeProvider.forzarSincronizacionDesdeAzure();
        _iniciarSincronizacionPeriodica();
      }
    });
  }
  
  void _animacionAleatoria() {
    final random = DateTime.now().millisecond % 3;
    if (random == 0) {
      _mostrarMensajeAlebrije(_obtenerMensajeSegunEstado());
    } else if (random == 1) {
      _ejecutarRebote();
    } else {
      _ejecutarSacudida();
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _bounceController.dispose();
    _shakeController.dispose();
    _sparkleController.dispose();
    _walkController.dispose();
    _jumpController.dispose();
    _blinkController.dispose();
    _tailController.dispose();
    super.dispose();
  }

  void _evaluarEstadoEmocional() {
    final alebrije = context.read<AlebrijeProvider>().alebrije;
    if (alebrije == null) return;
    
    setState(() {
      if (alebrije.estado.hambre < 30) {
        _estadoEmocional = 'hambriento';
      } else if (alebrije.estado.felicidad > 80) {
        _estadoEmocional = 'feliz';
      } else if (alebrije.estado.energia < 30) {
        _estadoEmocional = 'cansado';
      } else if (alebrije.estado.felicidad < 30) {
        _estadoEmocional = 'triste';
      } else if (alebrije.estado.felicidad > 60 && alebrije.estado.energia > 60) {
        _estadoEmocional = 'jugueton';
      } else {
        _estadoEmocional = 'neutral';
      }
    });
  }
  
  String _obtenerMensajeSegunEstado() {
    switch (_estadoEmocional) {
      case 'hambriento':
        return '¡Tengo hambre! 🍽️';
      case 'feliz':
        return '¡Me siento genial! 😄';
      case 'cansado':
        return 'Necesito descansar... 😴';
      case 'triste':
        return 'Me siento solo... 😢';
      case 'jugueton':
        return '¡Juguemos! 🎮';
      default:
        return 'Hola, ¿cómo estás? 👋';
    }
  }
  
  void _mostrarMensajeAlebrije(String mensaje) {
    setState(() {
      _mensajesAlebrije.add(mensaje);
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _mensajesAlebrije.remove(mensaje);
        });
      }
    });
  }

  void _mostrarXPGanado(int xp, {String? bonus}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _xpFlotantes.add({
        'id': id,
        'xp': xp,
        'bonus': bonus,
        'time': DateTime.now(),
      });
    });
    
    // Remover después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _xpFlotantes.removeWhere((item) => item['id'] == id);
        });
      }
    });
  }
  
  void _ejecutarRebote() {
    _bounceController.forward(from: 0).then((_) {
      _bounceController.reverse();
    });
  }
  
  void _ejecutarSacudida() {
    _shakeController.forward(from: 0).then((_) {
      _shakeController.forward(from: 0).then((_) {
        _shakeController.forward(from: 0);
      });
    });
  }
  
  void _crearParticulasCorazon(Offset posicion) {
    setState(() {
      for (int i = 0; i < 5; i++) {
        _particulas.add(posicion);
      }
    });
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _particulas.clear();
        });
      }
    });
  }
  
  void _iniciarAnimacionComer() {
    // Animar la boca abriéndose
    _mouthController.forward(from: 0);
    
    // Crear croquetas cayendo
    setState(() {
      for (int i = 0; i < 3; i++) {
        _croquetas.add({
          'x': -0.3 + (i * 0.3), // Posiciones horizontales distribuidas
          'y': -0.8, // Empezar desde arriba
          'velocidad': 0.02 + (i * 0.01), // Velocidades ligeramente diferentes
          'rotacion': 0.0,
        });
      }
    });
    
    // Animar las croquetas cayendo
    _animarCroquetas();
    
    // Limpiar croquetas después de la animación
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _croquetas.clear();
        });
      }
    });
  }
  
  void _animarCroquetas() {
    if (_croquetas.isEmpty) return;
    
    setState(() {
      for (var croqueta in _croquetas) {
        croqueta['y'] += croqueta['velocidad'];
        croqueta['rotacion'] += 0.1;
      }
      // Remover croquetas que llegaron al suelo
      _croquetas.removeWhere((croqueta) => croqueta['y'] > 0.5);
    });
    
    // Continuar animación si quedan croquetas
    if (_croquetas.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 50), _animarCroquetas);
    }
  }
  
  String _getMensajeLimite(AlebrijeEstado estado, String tipoAccion, int maxDiario, int contadorActual) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(estado.ultimaAccionFecha);
    
    // Si ha pasado una hora, el límite debería ser solo el diario
    if (estado.esNuevaHora) {
      if (contadorActual >= maxDiario) {
        return '$tipoAccion: Límite diario alcanzado ($maxDiario veces). Vuelve mañana.';
      } else {
        return '¡Ya puedes $tipoAccion de nuevo!';
      }
    } else {
      // No ha pasado una hora, mostrar tiempo restante
      final minutosFaltantes = 60 - diferencia.inMinutes;
      if (minutosFaltantes > 0) {
        return '⏰ Espera ${minutosFaltantes} minutos para $tipoAccion otra vez';
      } else {
        // Por si acaso, si los minutos son negativos
        return '¡Ya puedes $tipoAccion de nuevo!';
      }
    }
  }
  
  void _manejarToque() {
    final ahora = DateTime.now();
    if (_ultimoToque != null && ahora.difference(_ultimoToque!).inSeconds < 2) {
      _toquesConsecutivos++;
    } else {
      _toquesConsecutivos = 1;
    }
    _ultimoToque = ahora;
    
    setState(() {
      _estaSiendoTocado = true;
    });
    
    // Reacciones según toques
    if (_toquesConsecutivos >= 5) {
      _mostrarMensajeAlebrije('¡Jajaja, eso hace cosquillas! 😆');
      _ejecutarSacudida();
      _sparkleController.forward(from: 0);
      _toquesConsecutivos = 0;
    } else if (_toquesConsecutivos >= 3) {
      _mostrarMensajeAlebrije('¡Me encanta tu atención! ❤️');
      _ejecutarRebote();
    } else {
      final mensajes = ['¡Hola! 👋', '¿Qué tal? 😊', 'Me gusta esto 🥰', '¡Sigue así! ✨'];
      _mostrarMensajeAlebrije(mensajes[_toquesConsecutivos % mensajes.length]);
    }
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _estaSiendoTocado = false;
        });
      }
    });
    
    // Dar experiencia por interacción SOLO si tiene interacciones disponibles
    final provider = context.read<AlebrijeProvider>();
    final alebrije = provider.alebrije;
    if (alebrije != null && alebrije.estado.puedeJugar) {
      provider.jugar();
      // Mostrar feedback de XP ganado
      final xpBase = 25;
      final mult = provider.multiplicadorExperienciaTotal;
      final xpTotal = (xpBase * mult).round();
      _mostrarXPGanado(
        xpTotal, 
        bonus: mult > 1.0 ? 'x${mult.toStringAsFixed(1)}' : null
      );
    } else if (alebrije != null && !alebrije.estado.puedeJugar) {
      // Mostrar mensaje de límite alcanzado pero seguir respondiendo
      print('⚠️ Límite de interacciones diarias alcanzado (${alebrije.estado.juegosHoy}/${AlebrijeEstado.maxJuegosDia})');
      // El alebrije sigue respondiendo con mensajes pero no gana XP
    }
  }

  @override
  Widget build(BuildContext context) {
    final alebrijeProvider = context.watch<AlebrijeProvider>();

    // Actualizar estado emocional cuando cambie el estado del alebrije
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluarEstadoEmocional();
    });

    // DEBUG: Mostrar estado actual
    print('🔍 BUILD: _verificacionAzureCompleta=${_verificacionAzureCompleta}, alebrije=${alebrijeProvider.alebrije != null ? "EXISTS" : "NULL"}, isLoading=${alebrijeProvider.isLoading}, error=${alebrijeProvider.error}');

    if (alebrijeProvider.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${alebrijeProvider.error}'),
            ],
          ),
        ),
      );
    }

    final alebrije = alebrijeProvider.alebrije;

    // Si aún no se completó la verificación de Azure, mostrar pantalla de loading
    if (!_verificacionAzureCompleta) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Alebrije Guardián'),
          backgroundColor: const Color(0xFF8B1538),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B1538)),
              ),
              const SizedBox(height: 24),
              Text(
                '🔍 Buscando tu alebrije en Azure...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Verificando tu guardián en la nube',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Si no hay alebrije después de verificar Azure, mostrar selector de especie
    if (alebrije == null) {
      print('🎯 MOSTRANDO SELECTOR: No hay alebrije después de verificación');
      return _buildSeleccionEspecie(context);
    }

    print('🎯 MOSTRANDO ALEBRIJE: ${alebrije.nombre}');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B1538),
        title: GestureDetector(
          onTap: () => _mostrarDialogoRenombrar(context, alebrije),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                alebrije.nombre,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit, color: Colors.white70, size: 18),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync, color: Colors.white),
            tooltip: 'Sincronizar desde Azure',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔄 Sincronizando desde Azure...'), duration: Duration(seconds: 1)),
              );
              final alebrijeProvider = context.read<AlebrijeProvider>();
              await alebrijeProvider.forzarSincronizacionDesdeAzure();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Sincronizado con Azure'), duration: Duration(seconds: 2)),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Descargar imagen',
            onPressed: () {
              print('📥 Botón de descarga presionado');
              _descargarImagenAlebrije(context, alebrije);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Renombrar',
            onPressed: () => _mostrarDialogoRenombrar(context, alebrije),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Historial',
            onPressed: () => setState(() => _mostrarHistorial = !_mostrarHistorial),
          ),
        ],
      ),
      body: _mostrarHistorial
          ? _buildHistorialEvoluciones(alebrije)
          : _buildVistaPrincipal(context, alebrije, alebrijeProvider),
    );
  }

  Widget _buildSeleccionEspecie(BuildContext context) {
    final especies = [
      {
        'nombre': 'Jaguar',
        'especie': 'jaguar',
        'emoji': '🐆',
        'descripcion': 'Fuerza y valentía',
        'detalles': 'Símbolo de poder y protección. Tu alebrije tendrá forma felina, garras poderosas y presencia imponente. Ideal para quien busca fortaleza.',
        'caracteristicas': '• Cuerpo robusto\n• Garras poderosas\n• Evoluciones majestuosas'
      },
      {
        'nombre': 'Águila',
        'especie': 'aguila',
        'emoji': '🦅',
        'descripcion': 'Visión y libertad',
        'detalles': 'Guardián del cielo. Tu alebrije tendrá alas majestuosas, visión aguda y forma aviar elegante. Perfecto para espíritus libres.',
        'caracteristicas': '• Alas grandes\n• Forma aviar\n• Evoluciones aéreas'
      },
      {
        'nombre': 'Serpiente',
        'especie': 'serpiente',
        'emoji': '🐍',
        'descripcion': 'Sabiduría y renovación',
        'detalles': 'Símbolo de transformación continua. Tu alebrije será alargado, con escamas místicas y evoluciones únicas. Para mentes estratégicas.',
        'caracteristicas': '• Cuerpo alargado\n• Escamas brillantes\n• Transformaciones únicas'
      },
      {
        'nombre': 'Venado',
        'especie': 'venado',
        'emoji': '🦌',
        'descripcion': 'Gracia y conexión',
        'detalles': 'Guardián de la naturaleza. Tu alebrije tendrá cuernos ramificados, movimientos elegantes y conexión espiritual. Ideal para almas sensibles.',
        'caracteristicas': '• Cuernos ramificados\n• Forma elegante\n• Evoluciones naturales'
      },
      {
        'nombre': 'Colibrí',
        'especie': 'colibri',
        'emoji': '🐦',
        'descripcion': 'Alegría y energía',
        'detalles': 'Mensajero de la felicidad. Tu alebrije será pequeño, veloz, con colores vibrantes y energía infinita. Para espíritus alegres.',
        'caracteristicas': '• Tamaño compacto\n• Colores vibrantes\n• Evoluciones veloces'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF8B1538),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text(
                '✨ Tu Alebrije Guardián ✨',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Elige tu espíritu protector que te acompañará en tu camino universitario',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Column(
                  children: [
                    Text(
                      'ℹ️ Importante',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Cada especie evoluciona de forma única\n• Tu alebrije será generado algorítmicamente (único)\n• Puedes cambiarlo si llegas a nivel máximo (16+)\n• También puedes cambiarlo si estás en niveles 1-3',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: ListView.builder(
                  itemCount: especies.length,
                  itemBuilder: (context, index) {
                    final especie = especies[index];
                    return _buildTarjetaEspecie(context, especie);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaEspecie(BuildContext context, Map<String, String> especie) {
    return GestureDetector(
      onTap: () => _mostrarDetallesEspecie(context, especie),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              especie['emoji']!,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    especie['nombre']!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B1538),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    especie['descripcion']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.info_outline,
              color: Color(0xFF8B1538),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetallesEspecie(BuildContext context, Map<String, String> especie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(especie['emoji']!),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                especie['nombre']!,
                style: const TextStyle(color: Color(0xFF8B1538)),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                especie['detalles']!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Características:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B1538),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                especie['caracteristicas']!,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tu alebrije será único con colores y patrones mexicanos aleatorios',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final alebrijeProvider = context.read<AlebrijeProvider>();
              final sessionProvider = context.read<SessionProvider>();
              final matricula = sessionProvider.carnet?.matricula ?? '15662';
              
              await alebrijeProvider.inicializarAlebrije(
                matricula,
                especieBase: especie['especie']!,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1538),
            ),
            child: const Text('¡Elegir este guardián!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildVistaPrincipal(BuildContext context, alebrije, AlebrijeProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Nivel y progreso
          _buildHeaderNivel(alebrije, provider),
          
          // Alebrije visual
          _buildAlebrijeVisual(alebrije),
          
          // Barras de estado
          _buildBarrasEstado(alebrije),
          
          // Botones de interacción
          _buildBotonesInteraccion(provider),
          
          // 💊 PANEL DE CÁPSULAS
          _buildPanelCapsulas(provider),
          
          // Información de decaimiento
          _buildInfoDecaimiento(alebrije),
          
          // Estado emocional
          _buildEstadoEmocional(alebrije),
        ],
      ),
    );
  }

  Widget _buildHeaderNivel(alebrije, AlebrijeProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(int.parse(alebrije.dna.colores.colorPrimario.substring(1), radix: 16) + 0xFF000000),
            Color(int.parse(alebrije.dna.colores.colorSecundario.substring(1), radix: 16) + 0xFF000000),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            provider.getNombreNivel(alebrije.nivelEvolucion),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nivel ${alebrije.nivelEvolucion}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          // Barra de progreso XP más prominente
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '⭐ EXPERIENCIA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${alebrije.puntosExperiencia} / ${provider.calcularPuntosNecesarios(alebrije.nivelEvolucion)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellowAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0, end: provider.getProgresoNivel()),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white30,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          value > 0.7 ? Colors.greenAccent : Colors.white
                        ),
                        minHeight: 16,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(provider.getProgresoNivel() * 100).toStringAsFixed(1)}% al siguiente nivel',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlebrijeVisual(alebrije) {
    final generator = AlebrijeGenerator(alebrije);
    final svgString = generator.generarSVG(width: 300, height: 300);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Aura brillante según estado emocional
        AnimatedBuilder(
          animation: _sparkleController,
          builder: (context, child) {
            return Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getColorEstadoEmocional().withOpacity(0.3 * _sparkleController.value),
                    blurRadius: 40 + (20 * _sparkleController.value),
                    spreadRadius: 10 + (10 * _sparkleController.value),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Alebrije con múltiples animaciones combinadas
        GestureDetector(
          onTap: _manejarToque,
          onPanUpdate: (details) {
            // Permitir mover el alebrije con el mouse/touch
            setState(() {
              _posicionX += details.delta.dx / 100; // Suavizar el movimiento
              _posicionY += details.delta.dy / 100;
              // Limitar el movimiento dentro de la pantalla
              _posicionX = _posicionX.clamp(-0.8, 0.8);
              _posicionY = _posicionY.clamp(-0.5, 0.5);
            });
          },
          onLongPress: () {
            _mostrarMensajeAlebrije('¡Me haces sentir especial! 💖');
            _crearParticulasCorazon(const Offset(150, 150));
            _sparkleController.forward(from: 0);
            // Solo dar XP si tiene interacciones disponibles
            final provider = context.read<AlebrijeProvider>();
            if (provider.alebrije != null && provider.alebrije!.estado.puedeJugar) {
              provider.jugar();
              final xpBase = 25;
              final mult = provider.multiplicadorExperienciaTotal;
              final xpTotal = (xpBase * mult).round();
              _mostrarXPGanado(
                xpTotal, 
                bonus: mult > 1.0 ? 'x${mult.toStringAsFixed(1)}' : null
              );
            }
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _breathingController,
              _bounceController,
              _shakeController,
              _walkController,
              _jumpController,
              _blinkController,
              _tailController,
              _mouthController,
            ]),
            builder: (context, child) {
              // Respiración suave
              final breatheScale = 1.0 + (_breathingController.value * 0.05);
              final breatheY = _breathingController.value * 8;
              
              // Rebote cuando está feliz
              final bounceY = -(_bounceController.value * 30);
              
              // Sacudida de atención
              final shakeX = (_shakeController.value - 0.5) * 20;
              
              // 🚶 Movimiento lateral autónomo (caminar)
              final walkX = _posicionX * 100; // Convertir -1~1 a píxeles
              
              // 🦘 Salto parabólico
              final jumpProgress = _jumpController.value;
              final jumpY = -(sin(jumpProgress * pi) * 80); // Parábola de salto
              
              // 🔄 Inclinación según dirección de movimiento
              final tiltAngle = _estaCaminando ? (_direccion * 0.1) : 0.0;
              
              // 👁️ Parpadeo (escala vertical de los ojos)
              final blinkScale = 1.0 - (_blinkController.value * 0.8);
              
              // 🌊 Oscilación de cola/alas
              final tailWag = sin(_tailController.value * 2 * pi) * 0.15;
              
              // Escala aumentada cuando es tocado
              final touchScale = _estaSiendoTocado ? 1.1 : 1.0;
              
              return Transform.translate(
                offset: Offset(walkX + shakeX, breatheY + bounceY + jumpY),
                child: Transform.rotate(
                  angle: tiltAngle,
                  child: Transform.scale(
                    scale: breatheScale * touchScale,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: _estaSiendoTocado
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            )
                          : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SvgPicture.string(svgString),
                          
                          // Emoji de expresión flotante
                          Positioned(
                            top: 20,
                            child: _buildEmojiExpresion(),
                          ),
                          
                          // 🍖 Boca abriéndose durante la alimentación
                          if (_mouthController.value > 0)
                            Positioned(
                              bottom: 80 + (_mouthController.value * 20), // Boca se abre hacia abajo
                              child: Container(
                                width: 40,
                                height: 20 + (_mouthController.value * 15),
                                decoration: BoxDecoration(
                                  color: Colors.pink[100],
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  border: Border.all(color: Colors.pink[300]!, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // 🍗 Croquetas cayendo durante la alimentación
        ..._croquetas.map((croqueta) {
          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + (croqueta['x'] * 150),
            top: MediaQuery.of(context).size.height / 2 + (croqueta['y'] * 200),
            child: Transform.rotate(
              angle: croqueta['rotacion'],
              child: Container(
                width: 20,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.brown[400],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.brown[600]!, width: 1),
                ),
                child: const Center(
                  child: Text(
                    '🍖',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          );
        }),
        
        // Mensajes del alebrije (burbujas de diálogo)
        ..._mensajesAlebrije.asMap().entries.map((entry) {
          return Positioned(
            top: 50 - (entry.key * 60.0),
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 300),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
        
        // XP flotantes (números que suben y se desvanecen)
        ..._xpFlotantes.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final elapsed = DateTime.now().difference(data['time'] as DateTime).inMilliseconds;
          final progress = (elapsed / 2000).clamp(0.0, 1.0);
          
          return Positioned(
            top: 250 - (progress * 150) - (index * 30.0), // Sube hacia arriba
            right: 50 + (index * 20.0), // Separa múltiples XP
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 2000),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: 1.0 + (value * 0.5) - (value * value * 0.5), // Crece y luego decrece
                  child: Opacity(
                    opacity: (1.0 - value).clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '+${data['xp']} XP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          if (data['bonus'] != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              data['bonus'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
        
        // Indicador de toque "Toca aquí"
        if (_toquesConsecutivos == 0 && _ultimoToque == null)
          Positioned(
            bottom: 10,
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 1500),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: 0.5 + (value * 0.5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.touch_app, size: 20, color: Color(0xFF8B1538)),
                      SizedBox(width: 4),
                      Text(
                        '¡Tócame!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B1538),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildEmojiExpresion() {
    String emoji;
    switch (_estadoEmocional) {
      case 'hambriento':
        emoji = '🍽️';
        break;
      case 'feliz':
        emoji = '😄';
        break;
      case 'cansado':
        emoji = '😴';
        break;
      case 'triste':
        emoji = '😢';
        break;
      case 'jugueton':
        emoji = '🎮';
        break;
      default:
        emoji = '😊';
    }
    
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        );
      },
    );
  }
  
  Color _getColorEstadoEmocional() {
    switch (_estadoEmocional) {
      case 'hambriento':
        return Colors.orange;
      case 'feliz':
        return Colors.yellow;
      case 'cansado':
        return Colors.blue;
      case 'triste':
        return Colors.grey;
      case 'jugueton':
        return Colors.green;
      default:
        return const Color(0xFF8B1538);
    }
  }

  Widget _buildBarrasEstado(alebrije) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBarraEstado('🍽️ Hambre', alebrije.estado.hambre, Colors.orange),
          const SizedBox(height: 12),
          _buildBarraEstado('😊 Felicidad', alebrije.estado.felicidad, Colors.pink),
          const SizedBox(height: 12),
          _buildBarraEstado('❤️ Salud', alebrije.estado.salud, Colors.red),
          const SizedBox(height: 12),
          _buildBarraEstado('⚡ Energía', alebrije.estado.energia, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildBarraEstado(String label, int valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$valor%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: valor / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildBotonesInteraccion(AlebrijeProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildBotonAccion(
                  icon: Icons.restaurant,
                  label: 'Alimentar',
                  contador: '${provider.alebrije!.estado.alimentacionesHoy}/${AlebrijeEstado.maxAlimentacionesDia}',
                  color: Colors.orange,
                  deshabilitado: !provider.alebrije!.estado.puedeAlimentar,
                  onTap: () {
                    if (!provider.alebrije!.estado.puedeAlimentar) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getMensajeLimite(
                            provider.alebrije!.estado, 
                            'alimentar', 
                            AlebrijeEstado.maxAlimentacionesDia,
                            provider.alebrije!.estado.alimentacionesHoy
                          )),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    provider.alimentar(20);
                    _iniciarAnimacionComer(); // Animación de croquetas y boca abriéndose
                    final xpBase = 15;
                    final mult = provider.multiplicadorExperienciaTotal;
                    final xpTotal = (xpBase * mult).round();
                    _mostrarXPGanado(
                      xpTotal, 
                      bonus: mult > 1.0 ? 'x${mult.toStringAsFixed(1)}' : null
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotonAccion(
                  icon: Icons.sports_esports,
                  label: 'Jugar',
                  contador: '${provider.alebrije!.estado.juegosHoy}/${AlebrijeEstado.maxJuegosDia}',
                  color: Colors.purple,
                  deshabilitado: !provider.alebrije!.estado.puedeJugar,
                  onTap: () {
                    if (!provider.alebrije!.estado.puedeJugar) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getMensajeLimite(
                            provider.alebrije!.estado, 
                            'jugar', 
                            AlebrijeEstado.maxJuegosDia,
                            provider.alebrije!.estado.juegosHoy
                          )),
                          backgroundColor: Colors.purple,
                        ),
                      );
                      return;
                    }
                    provider.jugar();
                    final xpBase = 25;
                    final mult = provider.multiplicadorExperienciaTotal;
                    final xpTotal = (xpBase * mult).round();
                    _mostrarXPGanado(
                      xpTotal, 
                      bonus: mult > 1.0 ? 'x${mult.toStringAsFixed(1)}' : null
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBotonAccion(
                  icon: Icons.medical_services,
                  label: 'Curar',
                  contador: '${provider.alebrije!.estado.curacionesHoy}/${AlebrijeEstado.maxCuracionesDia}',
                  color: Colors.red,
                  deshabilitado: !provider.alebrije!.estado.puedeCurar,
                  onTap: () {
                    if (!provider.alebrije!.estado.puedeCurar) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getMensajeLimite(
                            provider.alebrije!.estado, 
                            'curar', 
                            AlebrijeEstado.maxCuracionesDia,
                            provider.alebrije!.estado.curacionesHoy
                          )),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    provider.curar(30);
                    final xpBase = 30;
                    final mult = provider.multiplicadorExperienciaTotal;
                    final xpTotal = (xpBase * mult).round();
                    _mostrarXPGanado(
                      xpTotal, 
                      bonus: mult > 1.0 ? 'x${mult.toStringAsFixed(1)}' : null
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotonAccion(
                  icon: Icons.bedtime,
                  label: 'Descansar',
                  contador: '${provider.alebrije!.estado.descansosHoy}/${AlebrijeEstado.maxDescansosDia}',
                  color: Colors.blue,
                  deshabilitado: !provider.alebrije!.estado.puedeDescansar,
                  onTap: () {
                    if (!provider.alebrije!.estado.puedeDescansar) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getMensajeLimite(
                            provider.alebrije!.estado, 
                            'descansar', 
                            AlebrijeEstado.maxDescansosDia,
                            provider.alebrije!.estado.descansosHoy
                          )),
                          backgroundColor: Colors.blue,
                        ),
                      );
                      return;
                    }
                    provider.descansar();
                    final xpBase = 20;
                    final mult = provider.multiplicadorExperienciaTotal;
                    final xpTotal = (xpBase * mult).round();
                    _mostrarXPGanado(
                      xpTotal, 
                      bonus: mult > 1.0 ? 'x${mult.toStringAsFixed(1)}' : null
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 🎮 Nueva fila con botón del minijuego
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MinijuegoScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.games),
                  label: const Text('🎮 Minijuego'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonAccion({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? contador,
    bool deshabilitado = false,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 300),
      tween: Tween<double>(begin: 1, end: 1),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Animación de pulsación
                setState(() {});
                
                // Feedback visual y sonoro
                _ejecutarRebote();
                _mostrarMensajeAlebrije(_obtenerMensajeAccion(label));
                
                // Efecto de partículas
                _sparkleController.forward(from: 0);
                
                // Ejecutar acción
                onTap();
                
                // Re-evaluar estado emocional
                Future.delayed(const Duration(milliseconds: 500), () {
                  _evaluarEstadoEmocional();
                });
              },
              onTapDown: (_) {
                setState(() {});
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: deshabilitado
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (contador != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          contador,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _obtenerMensajeAccion(String accion) {
    final random = DateTime.now().millisecond % 5;
    
    switch (accion) {
      case 'Alimentar':
        final mensajes = [
          '¡Mmm, delicioso! +5 XP 😋',
          '¡Qué rico! +5 XP 🤤',
          '¡Estaba hambriento! +5 XP 🍽️',
          '¡Gracias por la comida! +5 XP 💕',
          '¡Ahora tengo energía! +5 XP ⚡',
        ];
        return mensajes[random];
        
      case 'Jugar':
        final mensajes = [
          '¡Esto es divertido! +10 XP 🎉',
          '¡Me encanta jugar! +10 XP 🎮',
          '¡Otra vez, otra vez! +10 XP 🤗',
          '¡Eres el mejor! +10 XP ⭐',
          '¡Jajaja! +10 XP 😆',
        ];
        return mensajes[random];
        
      case 'Curar':
        final mensajes = [
          'Me siento mejor +15 XP 💊',
          '¡Gracias, doctor! +15 XP 🏥',
          'Ya no me duele +15 XP 😌',
          '¡Qué alivio! 💚',
          'Ahora estoy sano 🩺',
        ];
        return mensajes[random];
        
      case 'Descansar':
        final mensajes = [
          'Zzz... +8 XP 😴',
          '¡Qué sueño! +8 XP 🛌',
          'Necesitaba esto +8 XP 💤',
          '¡Dulces sueños! +8 XP 🌙',
          'Recargando energías... +8 XP ⚡',
        ];
        return mensajes[random];
        
      default:
        return '¡Gracias! ❤️';
    }
  }

  Widget _buildEstadoEmocional(alebrije) {
    String mensaje;
    IconData emoji;

    final salud = alebrije.saludGeneral;
    if (salud >= 80) {
      mensaje = '¡${alebrije.nombre} está muy feliz! 🌟';
      emoji = Icons.sentiment_very_satisfied;
    } else if (salud >= 50) {
      mensaje = '${alebrije.nombre} se siente bien';
      emoji = Icons.sentiment_satisfied;
    } else if (salud >= 30) {
      mensaje = '${alebrije.nombre} necesita un poco de cuidado';
      emoji = Icons.sentiment_neutral;
    } else {
      mensaje = '¡${alebrije.nombre} necesita atención urgente!';
      emoji = Icons.sentiment_very_dissatisfied;
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: salud < 30 ? Colors.red : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(emoji, size: 48, color: const Color(0xFF8B1538)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialEvoluciones(alebrije) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: alebrije.historialEvoluciones.length,
      itemBuilder: (context, index) {
        final evolucion = alebrije.historialEvoluciones[alebrije.historialEvoluciones.length - 1 - index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF8B1538),
              child: Text(
                '${evolucion.nivel}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(evolucion.descripcion),
            subtitle: Text(
              '${evolucion.fecha.day}/${evolucion.fecha.month}/${evolucion.fecha.year}',
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInfoDecaimiento(alebrije) {
    final now = DateTime.now();
    final horasSinAlimentar = now.difference(alebrije.estado.ultimaAlimentacion).inHours;
    final horasSinInteractuar = now.difference(alebrije.estado.ultimaInteraccion).inHours;
    final horasSinCuidar = now.difference(alebrije.estado.ultimoCuidado).inHours;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B1538).withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B1538).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFF8B1538)),
              SizedBox(width: 8),
              Text(
                '⏰ Sistema de Cuidado Automático',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B1538),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Info de decaimiento
          _buildInfoItem(
            icono: Icons.restaurant,
            titulo: 'Hambre',
            descripcion: 'Baja -5 cada 6 horas sin alimentar',
            tiempoTranscurrido: horasSinAlimentar,
            colorIcono: Colors.orange,
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoItem(
            icono: Icons.favorite,
            titulo: 'Felicidad',
            descripcion: 'Baja -5 cada 8 horas sin jugar',
            tiempoTranscurrido: horasSinInteractuar,
            colorIcono: Colors.pink,
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoItem(
            icono: Icons.medical_services,
            titulo: 'Salud',
            descripcion: 'Baja -3 cada 12 horas sin cuidar',
            tiempoTranscurrido: horasSinCuidar,
            colorIcono: Colors.red,
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoItem(
            icono: Icons.battery_charging_full,
            titulo: 'Energía',
            descripcion: 'Baja -5 cada 4 horas sin descansar',
            tiempoTranscurrido: horasSinInteractuar,
            colorIcono: Colors.blue,
          ),
          
          const SizedBox(height: 16),
          
          // Consejos
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💡 Consejos de Cuidado',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Visítalo diariamente para mantener su felicidad alta\n• Tócalo frecuentemente para interactuar\n• Las consultas médicas lo alimentan automáticamente\n• Las vacunas mejoran su salud\n• Mantén todos los valores arriba de 30',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required int tiempoTranscurrido,
    required Color colorIcono,
  }) {
    final urgente = tiempoTranscurrido >= 6;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: urgente ? colorIcono.withOpacity(0.2) : colorIcono.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: urgente ? colorIcono : colorIcono.withOpacity(0.3),
              width: urgente ? 2 : 1,
            ),
          ),
          child: Icon(icono, color: colorIcono, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: urgente ? colorIcono : Colors.grey[800],
                    ),
                  ),
                  if (urgente) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.warning, size: 16, color: Colors.orange),
                  ],
                ],
              ),
              Text(
                descripcion,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Hace ${tiempoTranscurrido}h',
                style: TextStyle(
                  fontSize: 10,
                  color: urgente ? colorIcono : Colors.grey[500],
                  fontWeight: urgente ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 💊 PANEL DE CÁPSULAS
  Widget _buildPanelCapsulas(AlebrijeProvider provider) {
    final capsulasPendientes = provider.capsulasPendientes;
    final capsulasActivas = provider.capsulasActivas;
    
    if (capsulasPendientes.isEmpty && capsulasActivas.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.pink.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '💊 Cápsulas de Poder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B1538),
                ),
              ),
              const Spacer(),
              if (capsulasActivas.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${capsulasActivas.length} activas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Cápsulas pendientes (para aplicar)
          if (capsulasPendientes.isNotEmpty) ...[
            const Text(
              '🎁 Nuevas cápsulas obtenidas:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B1538),
              ),
            ),
            const SizedBox(height: 8),
            ...capsulasPendientes.map((capsula) => _buildCapsulaPendiente(capsula, provider)),
          ],
          
          // Cápsulas activas
          if (capsulasActivas.isNotEmpty) ...[
            if (capsulasPendientes.isNotEmpty) const Divider(height: 24),
            const Text(
              '✨ Efectos activos:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B1538),
              ),
            ),
            const SizedBox(height: 8),
            ...capsulasActivas.map((capsula) => _buildCapsulaActiva(capsula)),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCapsulaPendiente(capsula, AlebrijeProvider provider) {
    final rarezaColor = CapsulaPowerGenerator.getColorRareza(capsula.rareza);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rarezaColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: rarezaColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji de la cápsula
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: capsula.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              capsula.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 12),
          
          // Info de la cápsula
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      capsula.nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rarezaColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        CapsulaPowerGenerator.getNombreRareza(capsula.rareza),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  capsula.descripcion,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'De: ${capsula.origenServicio}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Botón aplicar
          ElevatedButton(
            onPressed: () async {
              await provider.aplicarCapsula(capsula.id);
              _mostrarMensajeAlebrije('¡Siento el poder de la cápsula! ✨');
              _sparkleController.forward(from: 0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: capsula.color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              '¡Aplicar!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCapsulaActiva(capsula) {
    final rarezaColor = CapsulaPowerGenerator.getColorRareza(capsula.rareza);
    final porcentaje = capsula.porcentajeDuracion;
    final tiempoRestante = capsula.tiempoRestante;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rarezaColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          Text(
            capsula.emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capsula.nombre,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (tiempoRestante != null) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: porcentaje,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(capsula.color),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tiempoRestante.inHours > 0
                        ? '${tiempoRestante.inHours}h ${tiempoRestante.inMinutes % 60}m restantes'
                        : '${tiempoRestante.inMinutes}m restantes',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 12, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        'PERMANENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Efectos visuales
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (capsula.bonosSalud > 0)
                Text('❤️ +${capsula.bonosSalud}', style: const TextStyle(fontSize: 10)),
              if (capsula.bonosHambre > 0)
                Text('🍽️ +${capsula.bonosHambre}', style: const TextStyle(fontSize: 10)),
              if (capsula.bonosFelicidad > 0)
                Text('😊 +${capsula.bonosFelicidad}', style: const TextStyle(fontSize: 10)),
              if (capsula.bonosEnergia > 0)
                Text('⚡ +${capsula.bonosEnergia}', style: const TextStyle(fontSize: 10)),
              if (capsula.multiplicadorExperiencia > 1.0)
                Text('⭐ x${capsula.multiplicadorExperiencia.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
  
  // 📝 RENOMBRAR ALEBRIJE
  void _mostrarDialogoRenombrar(BuildContext context, alebrije) {
    final controlador = TextEditingController(text: alebrije.nombre);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text('✏️ Renombrar ${alebrije.dna.especieBase}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controlador,
              autofocus: true,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: 'Nuevo nombre',
                hintText: 'Ej: Xóchitl, Cuauhtémoc, Luna...',
                prefixIcon: const Icon(Icons.pets, color: Color(0xFF8B1538)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B1538), width: 2),
                ),
              ),
              onSubmitted: (valor) {
                if (valor.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _renombrarAlebrije(valor.trim());
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Dale un nombre único a tu alebrije guardián 🎨',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nuevoNombre = controlador.text.trim();
              if (nuevoNombre.isNotEmpty) {
                Navigator.pop(context);
                _renombrarAlebrije(nuevoNombre);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1538),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _renombrarAlebrije(String nuevoNombre) async {
    final provider = context.read<AlebrijeProvider>();
    await provider.renombrar(nuevoNombre);
    
    setState(() {
      _mostrarMensajeAlebrije('¡Me encanta mi nuevo nombre! 💕');
    });
    
    _sparkleController.forward(from: 0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Alebrije renombrado a "$nuevoNombre"'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Descargar imagen del alebrije con información del DNA único
  void _descargarImagenAlebrije(BuildContext context, alebrije) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Color(0xFF8B1538)),
            SizedBox(width: 8),
            Text('Descargar Alebrije'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎨 ${alebrije.nombre}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('📊 Nivel: ${alebrije.nivelEvolucion}'),
            Text('🧬 Especie: ${alebrije.dna.especieBase.toUpperCase()}'),
            Text('⭐ Experiencia: ${alebrije.puntosExperiencia} XP'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.fingerprint, color: Colors.purple, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'DNA Virtual Único',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tu alebrije tiene un código genético único e irrepetible, como una huella digital. Cada gen determina colores, patrones y características que lo hacen especial.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generación: ${alebrije.dna.generacion} | Mutaciones: ${alebrije.dna.mutaciones.length}',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sistema de Transformación',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A medida que ganas experiencia, tu alebrije evoluciona y muta, transformando su apariencia. Cada nivel desbloquea nuevos colores, patrones y características únicas.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '📸 Se descargará una imagen PNG con tu alebrije en su estado evolutivo actual.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _ejecutarDescarga(alebrije);
            },
            icon: const Icon(Icons.download),
            label: const Text('Descargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1538),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _ejecutarDescarga(alebrije) {
    try {
      // Generar SVG del alebrije usando la instancia del generador
      final generator = AlebrijeGenerator(alebrije);
      final svgString = generator.generarSVG(width: 800, height: 800);
      
      // Crear un blob con el SVG
      final bytes = utf8.encode(svgString);
      final blob = html.Blob([bytes], 'image/svg+xml');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Crear elemento de descarga con nombre descriptivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${alebrije.nombre.replaceAll(' ', '_')}_Nivel${alebrije.nivelEvolucion}_DNA${alebrije.dna.hashCode.abs()}_$timestamp.svg';
      
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      
      // Limpiar URL
      html.Url.revokeObjectUrl(url);
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('✨ ${alebrije.nombre} descargado exitosamente (DNA único: ${alebrije.dna.hashCode.abs()})'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      setState(() {
        _mostrarMensajeAlebrije('¡Ahora tengo mi foto! 📸');
      });
      
    } catch (e) {
      print('❌ Error al descargar imagen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al descargar la imagen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
