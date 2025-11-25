import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../providers/alebrije_provider.dart';
import '../services/alebrije_generator.dart';

/// Pantalla principal de interacción con el Alebrije Tamagotchi
class AlebrijeScreen extends StatefulWidget {
  const AlebrijeScreen({Key? key}) : super(key: key);

  @override
  State<AlebrijeScreen> createState() => _AlebrijeScreenState();
}

class _AlebrijeScreenState extends State<AlebrijeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _mostrarHistorial = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Actualizar estado al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlebrijeProvider>().actualizarEstado();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alebrijeProvider = context.watch<AlebrijeProvider>();

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
        title: Text(
          alebrije.nombre,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
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
      {'nombre': 'Jaguar', 'especie': 'jaguar', 'emoji': '🐆', 'descripcion': 'Fuerza y valentía'},
      {'nombre': 'Águila', 'especie': 'aguila', 'emoji': '🦅', 'descripcion': 'Visión y libertad'},
      {'nombre': 'Serpiente', 'especie': 'serpiente', 'emoji': '🐍', 'descripcion': 'Sabiduría y renovación'},
      {'nombre': 'Venado', 'especie': 'venado', 'emoji': '🦌', 'descripcion': 'Gracia y conexión'},
      {'nombre': 'Colibrí', 'especie': 'colibri', 'emoji': '🐦', 'descripcion': 'Alegría y energía'},
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
      onTap: () async {
        final alebrijeProvider = context.read<AlebrijeProvider>();
        final matricula = '15662'; // TODO: Obtener de SessionProvider
        
        await alebrijeProvider.inicializarAlebrije(
          matricula,
          especieBase: especie['especie']!,
        );
      },
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
              Icons.arrow_forward_ios,
              color: Color(0xFF8B1538),
            ),
          ],
        ),
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

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final scale = 1.0 + (_animationController.value * 0.05);
        final translateY = _animationController.value * 10;

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 300,
              height: 300,
              margin: const EdgeInsets.all(20),
              child: SvgPicture.string(svgString),
            ),
          ),
        );
      },
    );
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
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
}
