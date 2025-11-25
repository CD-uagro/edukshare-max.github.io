import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../providers/alebrije_provider.dart';
import '../providers/session_provider.dart';
import '../services/alebrije_generator.dart';
import '../models/capsula_poder_model.dart';

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
  
  bool _mostrarHistorial = false;
  String _estadoEmocional = 'neutral'; // neutral, feliz, triste, hambriento, jugueton, cansado
  bool _estaSiendoTocado = false;
  int _toquesConsecutivos = 0;
  DateTime? _ultimoToque;
  
  final List<Offset> _particulas = [];
  final List<String> _mensajesAlebrije = [];

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

    // Intentar cargar alebrije existente primero
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final alebrijeProvider = context.read<AlebrijeProvider>();
      final sessionProvider = context.read<SessionProvider>();
      final matricula = sessionProvider.carnet?.matricula ?? '15662';
      
      // Solo inicializar si no hay alebrije cargado
      if (alebrijeProvider.alebrije == null) {
        await alebrijeProvider.inicializarAlebrije(matricula);
      } else {
        await alebrijeProvider.actualizarEstado();
      }
      
      _evaluarEstadoEmocional();
      _iniciarAnimacionesAutomaticas();
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
    
    // Dar experiencia por interacción
    context.read<AlebrijeProvider>().jugar();
  }

  @override
  Widget build(BuildContext context) {
    final alebrijeProvider = context.watch<AlebrijeProvider>();
    
    // Actualizar estado emocional cuando cambie el estado del alebrije
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluarEstadoEmocional();
    });

    if (alebrijeProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
    if (alebrije == null) {
      return _buildSeleccionEspecie(context);
    }

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
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: provider.getProgresoNivel(),
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${alebrije.puntosExperiencia} / ${provider.calcularPuntosNecesarios(alebrije.nivelEvolucion)} XP',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
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
          onLongPress: () {
            _mostrarMensajeAlebrije('¡Me haces sentir especial! 💖');
            _crearParticulasCorazon(const Offset(150, 150));
            _sparkleController.forward(from: 0);
            context.read<AlebrijeProvider>().jugar();
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _breathingController,
              _bounceController,
              _shakeController,
            ]),
            builder: (context, child) {
              // Respiración suave
              final breatheScale = 1.0 + (_breathingController.value * 0.05);
              final breatheY = _breathingController.value * 8;
              
              // Rebote cuando está feliz
              final bounceY = -(_bounceController.value * 30);
              
              // Sacudida de atención
              final shakeX = (_shakeController.value - 0.5) * 20;
              
              // Escala aumentada cuando es tocado
              final touchScale = _estaSiendoTocado ? 1.1 : 1.0;
              
              return Transform.translate(
                offset: Offset(shakeX, breatheY + bounceY),
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
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
                  color: Colors.orange,
                  onTap: () => provider.alimentar(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotonAccion(
                  icon: Icons.sports_esports,
                  label: 'Jugar',
                  color: Colors.purple,
                  onTap: () => provider.jugar(),
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
                  color: Colors.red,
                  onTap: () => provider.curar(30),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotonAccion(
                  icon: Icons.bedtime,
                  label: 'Descansar',
                  color: Colors.blue,
                  onTap: () => provider.descansar(),
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
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
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
          '¡Mmm, delicioso! 😋',
          '¡Qué rico! 🤤',
          '¡Estaba hambriento! 🍽️',
          '¡Gracias por la comida! 💕',
          '¡Ahora tengo energía! ⚡',
        ];
        return mensajes[random];
        
      case 'Jugar':
        final mensajes = [
          '¡Esto es divertido! 🎉',
          '¡Me encanta jugar! 🎮',
          '¡Otra vez, otra vez! 🤗',
          '¡Eres el mejor! ⭐',
          '¡Jajaja! 😆',
        ];
        return mensajes[random];
        
      case 'Curar':
        final mensajes = [
          'Me siento mejor 💊',
          '¡Gracias, doctor! 🏥',
          'Ya no me duele 😌',
          '¡Qué alivio! 💚',
          'Ahora estoy sano 🩺',
        ];
        return mensajes[random];
        
      case 'Descansar':
        final mensajes = [
          'Zzz... 😴',
          '¡Qué sueño! 🛌',
          'Necesitaba esto 💤',
          '¡Dulces sueños! 🌙',
          'Recargan do energías... ⚡',
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
}
