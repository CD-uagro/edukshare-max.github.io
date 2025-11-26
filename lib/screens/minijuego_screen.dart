import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alebrije_provider.dart';
import '../models/alebrije_model.dart';
import 'dart:async';
import 'dart:math';

class MinijuegoScreen extends StatefulWidget {
  const MinijuegoScreen({super.key});

  @override
  State<MinijuegoScreen> createState() => _MinijuegoScreenState();
}

class _MinijuegoScreenState extends State<MinijuegoScreen> with TickerProviderStateMixin {
  // 🎮 Estado del juego
  bool _juegoIniciado = false;
  bool _juegoTerminado = false;
  int _puntuacion = 0;
  double _posicionAlebrije = 0.0; // Posición Y del alebrije (0 = suelo, positivo = saltando)
  bool _estaSaltando = false;

  // 🏃 Obstáculos
  final List<Map<String, dynamic>> _obstaculos = [];
  double _velocidadJuego = 3.0;
  Timer? _timerJuego;

  // 🎭 Animaciones
  late AnimationController _saltoController;
  late Animation<double> _animacionSalto;

  // 📊 Estadísticas del juego
  int _obstaculosEvitados = 0;
  Duration _tiempoSupervivencia = Duration.zero;
  DateTime? _inicioJuego;

  @override
  void initState() {
    super.initState();

    // Animación de salto
    _saltoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animacionSalto = Tween<double>(
      begin: 0.0,
      end: 120.0, // Altura máxima del salto
    ).animate(CurvedAnimation(
      parent: _saltoController,
      curve: Curves.easeOut,
    ));

    _animacionSalto.addListener(() {
      setState(() {
        _posicionAlebrije = _animacionSalto.value;
      });
    });

    _animacionSalto.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Iniciar caída
        _saltoController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        // Llegó al suelo
        setState(() {
          _estaSaltando = false;
          _posicionAlebrije = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _saltoController.dispose();
    _timerJuego?.cancel();
    super.dispose();
  }

  void _iniciarJuego() {
    setState(() {
      _juegoIniciado = true;
      _juegoTerminado = false;
      _puntuacion = 0;
      _obstaculosEvitados = 0;
      _tiempoSupervivencia = Duration.zero;
      _inicioJuego = DateTime.now();
      _obstaculos.clear();
    });

    // Iniciar loop del juego
    _timerJuego = Timer.periodic(const Duration(milliseconds: 50), _actualizarJuego);
  }

  void _actualizarJuego(Timer timer) {
    if (!mounted || _juegoTerminado) return;

    setState(() {
      // Actualizar tiempo
      if (_inicioJuego != null) {
        _tiempoSupervivencia = DateTime.now().difference(_inicioJuego!);
      }

      // Mover obstáculos existentes
      for (var obstaculo in _obstaculos) {
        obstaculo['x'] -= _velocidadJuego;
      }

      // Remover obstáculos que salieron de pantalla
      _obstaculos.removeWhere((obs) => obs['x'] < -50);

      // Generar nuevos obstáculos
      if (_obstaculos.isEmpty || _obstaculos.last['x'] < MediaQuery.of(context).size.width - 300) {
        if (Random().nextDouble() < 0.02) { // 2% de probabilidad por frame
          _generarObstaculo();
        }
      }

      // Aumentar dificultad con el tiempo
      _velocidadJuego = 3.0 + (_tiempoSupervivencia.inSeconds / 10.0);

      // Verificar colisiones
      _verificarColisiones();

      // Actualizar puntuación
      _puntuacion = (_tiempoSupervivencia.inSeconds * 10) + (_obstaculosEvitados * 50);
    });
  }

  void _generarObstaculo() {
    final tiposObstaculo = ['cactus', 'roca', 'arbusto'];
    final tipo = tiposObstaculo[Random().nextInt(tiposObstaculo.length)];

    _obstaculos.add({
      'x': MediaQuery.of(context).size.width,
      'y': 0.0,
      'tipo': tipo,
      'ancho': 40.0,
      'alto': tipo == 'cactus' ? 80.0 : tipo == 'roca' ? 60.0 : 40.0,
    });
  }

  void _verificarColisiones() {
    const anchoAlebrije = 60.0;
    const altoAlebrije = 80.0;
    const posicionXAlebrije = 100.0; // Posición fija en X

    for (var obstaculo in _obstaculos) {
      // Colisión simple: bounding boxes
      final colisionX = posicionXAlebrije < obstaculo['x'] + obstaculo['ancho'] &&
                       posicionXAlebrije + anchoAlebrije > obstaculo['x'];

      final colisionY = _posicionAlebrije < obstaculo['alto'];

      if (colisionX && colisionY) {
        _terminarJuego();
        return;
      }

      // Contar obstáculo evitado
      if (!obstaculo.containsKey('contado') && obstaculo['x'] + obstaculo['ancho'] < posicionXAlebrije) {
        obstaculo['contado'] = true;
        _obstaculosEvitados++;
      }
    }
  }

  void _saltar() {
    if (!_estaSaltando && !_juegoTerminado) {
      setState(() {
        _estaSaltando = true;
      });
      _saltoController.forward(from: 0);
    }
  }

  void _terminarJuego() {
    _timerJuego?.cancel();
    setState(() {
      _juegoTerminado = true;
    });

    // Calcular experiencia ganada
    final experienciaGanada = (_puntuacion ~/ 100) + 10; // Mínimo 10 XP

    // Mostrar diálogo de resultado
    _mostrarDialogoResultado(experienciaGanada);
  }

  void _mostrarDialogoResultado(int experienciaGanada) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎮 ¡Juego Terminado!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆 Puntuación: $_puntuacion'),
            Text('⏱️ Tiempo: ${_tiempoSupervivencia.inSeconds}s'),
            Text('🏃 Obstáculos evitados: $_obstaculosEvitados'),
            const SizedBox(height: 16),
            Text(
              '✨ +$experienciaGanada XP',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Volver a pantalla principal

              // Otorgar experiencia
              final provider = context.read<AlebrijeProvider>();
              provider.agregarExperiencia(experienciaGanada, 'Minijuego de salto');
            },
            child: const Text('¡Genial!'),
          ),
        ],
      ),
    );
  }

  Widget _buildObstaculo(Map<String, dynamic> obstaculo) {
    Widget icono;
    switch (obstaculo['tipo']) {
      case 'cactus':
        icono = const Text('🌵', style: TextStyle(fontSize: 40));
        break;
      case 'roca':
        icono = const Text('🪨', style: TextStyle(fontSize: 35));
        break;
      case 'arbusto':
        icono = const Text('🌿', style: TextStyle(fontSize: 30));
        break;
      default:
        icono = const Text('❓', style: TextStyle(fontSize: 30));
    }

    return Positioned(
      left: obstaculo['x'],
      bottom: obstaculo['y'],
      child: Container(
        width: obstaculo['ancho'],
        height: obstaculo['alto'],
        alignment: Alignment.bottomCenter,
        child: icono,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🦅 Minijuego: ¡Salta con Machaco!'),
        backgroundColor: const Color(0xFF8B1538),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightBlue, Colors.green],
          ),
        ),
        child: _juegoIniciado ? _buildJuego() : _buildMenuInicio(),
      ),
    );
  }

  Widget _buildMenuInicio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🦅 ¡Salta con Machaco!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Column(
              children: [
                Text(
                  '📋 Instrucciones:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('• Toca la pantalla para saltar'),
                Text('• Evita los obstáculos'),
                Text('• Sobrevive el mayor tiempo posible'),
                Text('• ¡Gana experiencia al finalizar!'),
              ],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _iniciarJuego,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1538),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              '🎮 ¡JUGAR!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJuego() {
    return GestureDetector(
      onTap: _saltar,
      child: Stack(
        children: [
          // 🌄 Fondo
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.lightBlue, Colors.lightGreen],
                ),
              ),
            ),
          ),

          // ☁️ Nubes decorativas
          ...List.generate(3, (index) {
            return Positioned(
              top: 50 + (index * 40),
              left: 50 + (index * 150),
              child: const Text('☁️', style: TextStyle(fontSize: 30)),
            );
          }),

          // 🦅 Alebrije saltando
          Positioned(
            left: 100,
            bottom: 100 + _posicionAlebrije,
            child: Transform.scale(
              scale: _estaSaltando ? 1.1 : 1.0,
              child: const Text(
                '🦅',
                style: TextStyle(fontSize: 60),
              ),
            ),
          ),

          // 🏃 Obstáculos
          ..._obstaculos.map(_buildObstaculo),

          // 📊 HUD (Heads Up Display)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🏆 $_puntuacion',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '⏱️ ${_tiempoSupervivencia.inSeconds}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '🏃 $_obstaculosEvitados',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 💀 Game Over overlay
          if (_juegoTerminado)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Text(
                    '💥 ¡CRASH!',
                    style: TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // 👆 Indicador de toque
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '👆',
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}