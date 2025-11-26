import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/alebrije_provider.dart';
import '../models/alebrije_model.dart';
import '../services/alebrije_generator.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:html' as html;

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
  double _velocidadJuego = 5.0; // Velocidad inicial más rápida
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
      end: 140.0, // Altura generosa para saltar sobre obstáculos de 90px
    ).animate(CurvedAnimation(
      parent: _saltoController,
      curve: Curves.easeOut, // Más natural para un salto
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
      if (_obstaculos.isEmpty || _obstaculos.last['x'] < MediaQuery.of(context).size.width - 250) {
        if (Random().nextDouble() < 0.04) { // 4% de probabilidad por frame (más fluido)
          _generarObstaculo();
        }
      }

      // Aumentar dificultad con el tiempo (aceleración progresiva)
      _velocidadJuego = 5.0 + (_tiempoSupervivencia.inSeconds / 5.0); // Se acelera más rápido

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
      'ancho': 60.0, // Obstáculos más grandes
      'alto': tipo == 'cactus' ? 90.0 : tipo == 'roca' ? 70.0 : 50.0, // Más grandes y visibles
    });
  }

  void _verificarColisiones() {
    const anchoHuevo = 50.0; // Hitbox más pequeña que el visual
    const posicionXHuevo = 90.0; // Centro del huevo

    for (var obstaculo in _obstaculos) {
      // Colisión en X: solo cuando el huevo está sobre el obstáculo
      final colisionX = posicionXHuevo < obstaculo['x'] + obstaculo['ancho'] &&
                       posicionXHuevo + anchoHuevo > obstaculo['x'];

      // Colisión en Y: el huevo debe estar CLARAMENTE por encima del obstáculo
      // Si _posicionAlebrije >= obstaculo['alto'] - 30, está saltando lo suficiente
      final alturaObstaculo = obstaculo['alto'] as double;
      final colisionY = _posicionAlebrije < alturaObstaculo - 30; // 30px de margen generoso

      if (colisionX && colisionY) {
        _terminarJuego();
        return;
      }

      // Contar obstáculo evitado
      if (!obstaculo.containsKey('contado') && obstaculo['x'] + obstaculo['ancho'] < posicionXHuevo) {
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

  void _descargarImagenAlebrije() {
    final provider = context.read<AlebrijeProvider>();
    if (provider.alebrije == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No se pudo acceder al alebrije')),
      );
      return;
    }

    try {
      final alebrije = provider.alebrije!;
      final generator = AlebrijeGenerator(alebrije);
      final svgString = generator.generarSVG(width: 800, height: 800);
      
      // Crear blob SVG
      final bytes = utf8.encode(svgString);
      final blob = html.Blob([bytes], 'image/svg+xml');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Nombre del archivo con timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '${alebrije.nombre.replaceAll(' ', '_')}_Minijuego_$timestamp.svg';
      
      // Crear y descargar
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      
      // Limpiar URL
      html.Url.revokeObjectUrl(url);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Imagen descargada: $filename')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al descargar: $e')),
      );
    }
  }
  
  void _mostrarDialogoResultado(int experienciaGanada) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🥚 ¡Juego Terminado!', textAlign: TextAlign.center),
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
              provider.agregarExperiencia(experienciaGanada, 'Minijuego del huevo saltarín');
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
        icono = const Text('🌵', style: TextStyle(fontSize: 60)); // Más grande
        break;
      case 'roca':
        icono = const Text('🪨', style: TextStyle(fontSize: 50)); // Más grande
        break;
      case 'arbusto':
        icono = const Text('🌿', style: TextStyle(fontSize: 40)); // Más grande
        break;
      default:
        icono = const Text('❓', style: TextStyle(fontSize: 40));
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
        title: const Text('🥚 Minijuego: ¡Salta con el Huevo!'),
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
            '🥚 ¡Salta con el Huevo!',
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
                Text('• Toca la pantalla para hacer saltar el huevo'),
                Text('• Evita los obstáculos del desierto'),
                Text('• Sobrevive el mayor tiempo posible'),
                Text('• ¡Gana experiencia para tu alebrije!'),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _descargarImagenAlebrije,
                icon: const Icon(Icons.download),
                label: const Text('📸 Descargar Imagen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 20),
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
                  '🥚 ¡JUGAR!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
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

          // 🥚 Huevo saltando (representando un huevo del alebrije)
          Positioned(
            left: 80,
            bottom: 120 + _posicionAlebrije,
            child: Transform.scale(
              scale: _estaSaltando ? 1.2 : 1.0,
              child: Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: _estaSaltando ? [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 5,
                    )
                  ] : null,
                ),
                child: const Center(
                  child: Text(
                    '🥚',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
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