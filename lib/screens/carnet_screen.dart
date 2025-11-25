// 📱 CARNET SCREEN - VISTA PRINCIPAL (DISEÑO UAGRO WALLET)
// Muestra el carnet digital completo con diseño profesional moderno

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/models/carnet_model.dart';
import 'package:carnet_digital_uagro/models/promocion_salud_model.dart';
import 'package:carnet_digital_uagro/theme/uagro_theme.dart';
import 'package:carnet_digital_uagro/screens/citas_screen.dart';
import 'package:carnet_digital_uagro/screens/consultas_screen.dart';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:html' as html;

class CarnetScreen extends StatefulWidget {
  const CarnetScreen({super.key});

  @override
  State<CarnetScreen> createState() => _CarnetScreenState();
}

class _CarnetScreenState extends State<CarnetScreen> {
  bool _isExpanded = true;
  
  // 🎯 ESTADO HOVER PARA PROMOCIONES
  Set<String> _hoveredCards = <String>{};
  
  // 📸 FOTO DE PERFIL
  Uint8List? _fotoPerfil;
  
  // 🌙 TEMA OSCURO
  bool _modoOscuro = false;
  
  // 🔗 CACHE DE PREVIEWS DE LINKS
  Map<String, Map<String, String>> _linkPreviews = {};
  
  // 🎗️ CONMEMORACIONES Y MOÑITO
  Map<String, dynamic> _conmemoracionActual = {
    'fecha': '19 de Octubre',
    'titulo': 'Día Mundial de Lucha contra el Cáncer de Mama',
    'descripcion': 'Día dedicado a la concientización sobre la importancia de la detección temprana del cáncer de mama.',
    'color': const Color(0xFFE91E63),
    'icono': '♥',
    'activa': false, // ← DESACTIVADA - Ya terminó octubre
  };

  @override
  void initState() {
    super.initState();
    // ⏱️ Cargar promociones CON DELAY para evitar 429 rate limiting
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Esperar 5 segundos después de cargar la pantalla para evitar rate limiting
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        context.read<SessionProvider>().loadPromociones();
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  // 🎯 FUNCIÓN PARA MANEJAR HOVER EN CARDS
  void _onCardHover(String promocionId, bool isHovering) {
    setState(() {
      if (isHovering) {
        _hoveredCards.add(promocionId);
      } else {
        _hoveredCards.remove(promocionId);
      }
    });
  }

  // 📱 DETECCIÓN DE DISPOSITIVO MÓVIL
  bool _isMobileDevice(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width < 600 || 
           mediaQuery.orientation == Orientation.portrait;
  }
  
  // ⚡ OPTIMIZACIÓN DE PERFORMANCE PARA MÓVIL
  bool _shouldReduceAnimations(BuildContext context) {
    return _isMobileDevice(context) || 
           MediaQuery.of(context).disableAnimations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _modoOscuro ? const Color(0xFF121212) : Colors.white,
      drawer: _buildModernDrawer(context), // 🎯 NUEVO MENÚ LATERAL
      appBar: AppBar(
        title: Text(
          'Carnet Digital Universitario CRES Llano Largo - SASU',
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF8B1538),
                Color(0xFFC41E3A),
                Color(0xFF8B1538),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: Color(0xFF8B1538).withOpacity(0.3),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, 
                      color: Colors.white, 
                      size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Abrir menú',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConsultasScreen(),
                ),
              );
            },
            tooltip: 'Mis Consultas de Atención',
          ),
          IconButton(
            icon: const Icon(Icons.medical_services_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CitasScreen(),
                ),
              );
            },
            tooltip: 'Mis Citas',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Más opciones',
            onSelected: (value) {
              if (value == 'cambiar_diseno') {
                _mostrarSelectorDiseno(context);
              } else if (value == 'mi_alebrije') {
                Navigator.of(context).pushNamed('/alebrije');
              } else if (value == 'logout') {
                context.read<SessionProvider>().logout();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'cambiar_diseno',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Cambiar diseño'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mi_alebrije',
                child: Row(
                  children: [
                    Icon(Icons.pets, size: 20, color: Color(0xFF8B1538)),
                    SizedBox(width: 12),
                    Text('Mi Alebrije Guardián 🎨', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 🎗️ MOÑITO CONMEMORATIVO
          if (_conmemoracionActual['activa'] == true)
            _buildMonitoConmemorativo(),
          
          // CONTENIDO PRINCIPAL
          Expanded(
            child: Consumer<SessionProvider>(
              builder: (context, session, child) {
                if (session.isLoading && session.carnet == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (session.carnet == null) {
                  return const Center(
                    child: Text('No se pudo cargar la información del carnet.'),
                  );
                }
                
                return _buildCarnetContent(context, session.carnet!);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🎗️ CONSTRUIR MOÑITO CONMEMORATIVO
  Widget _buildMonitoConmemorativo() {
    final conmemoracion = _conmemoracionActual;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
          // Sombra rosa suave que rodea el rectángulo
          BoxShadow(
            color: (conmemoracion['color'] as Color).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 0),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Información principal
          Expanded(
            child: GestureDetector(
              onTap: () => _mostrarDetalleConmemoracion(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conmemoracion['fecha'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: conmemoracion['color'],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conmemoracion['titulo'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _modoOscuro ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          // Botón de cierre
          IconButton(
            onPressed: () {
              setState(() {
                _conmemoracionActual['activa'] = false;
              });
            },
            icon: Icon(
              Icons.close,
              size: 18,
              color: (_modoOscuro ? Colors.white : Colors.black87).withOpacity(0.6),
            ),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // 🎗️ MOSTRAR DETALLE DE CONMEMORACIÓN
  void _mostrarDetalleConmemoracion() {
    final conmemoracion = _conmemoracionActual;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conmemoracion['fecha'],
              style: TextStyle(
                fontSize: 12,
                color: conmemoracion['color'],
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              conmemoracion['titulo'],
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conmemoracion['descripcion'],
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (conmemoracion['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: conmemoracion['color'],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'UAGro se une a esta importante conmemoración promoviendo la salud estudiantil.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí podrías agregar navegación a recursos relacionados
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Consulta más información en el área de salud'),
                  backgroundColor: conmemoracion['color'],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: conmemoracion['color'],
              foregroundColor: Colors.white,
            ),
            child: const Text('Más Info'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCarnetContent(BuildContext context, CarnetModel carnet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Logo UAGro con diseño moderno
          // Badge "Prueba Piloto" discreto a la derecha
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: const Text(
                'Proyecto Piloto',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // --- NUEVO CONTENEDOR COLAPSABLE ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Card principal que ahora funciona como cabecera del desplegable
                InkWell(
                  onTap: _toggleExpanded,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: _buildWalletCard(carnet, isHeader: true),
                ),
                // Contenido desplegable
                AnimatedCrossFade(
                  firstChild: _buildCollapsibleContent(carnet),
                  secondChild: Container(),
                  crossFadeState: _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
          // --- FIN DE CONTENEDOR COLAPSABLE ---

          const SizedBox(height: 20),
          
          // 🏥 ÁREA DE PROMOCIONES DE SALUD
          _buildPromocionesArea(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCollapsibleContent(CarnetModel carnet) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
          const SizedBox(height: 20),
          // Información Académica
          _buildSectionCard(
            title: 'INFORMACIÓN ACADÉMICA',
            icon: Icons.school_rounded,
            children: [
              _buildDetailRow(Icons.menu_book_rounded, 'Programa', carnet.programa),
              _buildDetailRow(Icons.style_rounded, 'Categoría', carnet.categoria),
            ],
          ),
          const SizedBox(height: 20),
          
          // Información Médica
          _buildSectionCard(
            title: 'INFORMACIÓN MÉDICA',
            icon: Icons.medical_services_rounded,
            children: [
              _buildDetailRow(Icons.bloodtype_rounded, 'Tipo de Sangre', carnet.tipoSangre),
              _buildDetailRow(Icons.local_hospital_rounded, 'Unidad Médica', carnet.unidadMedica),
              if (carnet.numeroAfiliacion.isNotEmpty)
                _buildDetailRow(Icons.badge_rounded, 'No. Afiliación', carnet.numeroAfiliacion),
              _buildDetailRow(Icons.health_and_safety_rounded, 'Seguro Universitario', carnet.usoSeguroUniversitario),
              _buildDetailRow(Icons.volunteer_activism_rounded, 'Donante', carnet.donante),
              
              const SizedBox(height: 12),
              
              // Enfermedades Crónicas
              _buildHealthStatusRow(
                'Enfermedades Crónicas',
                carnet.enfermedadCronica.isNotEmpty ? carnet.enfermedadCronica : 'Ninguna',
                carnet.tieneEnfermedadCronica,
              ),
              
              const SizedBox(height: 8),
              
              // Alergias
              _buildHealthStatusRow(
                'Alergias',
                carnet.alergias.isNotEmpty ? carnet.alergias : 'Ninguna',
                carnet.tieneAlergias,
              ),
              
              const SizedBox(height: 8),
              
              // Discapacidad
              if (carnet.tieneDiscapacidad) ...[
                _buildHealthStatusRow(
                  'Discapacidad',
                  '${carnet.discapacidad}${carnet.tipoDiscapacidad.isNotEmpty ? " - ${carnet.tipoDiscapacidad}" : ""}',
                  true,
                ),
              ] else ...[
                _buildHealthStatusRow('Discapacidad', 'No', false),
              ],
            ],
          ),
          const SizedBox(height: 20),
          
          // Contacto de Emergencia
          _buildSectionCard(
            title: 'CONTACTO DE EMERGENCIA',
            icon: Icons.emergency_rounded,
            children: [
              _buildDetailRow(Icons.person_rounded, 'Contacto', carnet.emergenciaContacto),
              _buildDetailRow(Icons.phone_rounded, 'Teléfono', carnet.emergenciaTelefono),
            ],
          ),
          
          // Notas del Expediente (si existen)
          if (carnet.expedienteNotas.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionCard(
              title: 'NOTAS DEL EXPEDIENTE',
              icon: Icons.note_rounded,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    carnet.expedienteNotas,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  // NUEVOS MÉTODOS HELPER PARA DISEÑO WALLET
  
  Widget _buildWalletCard(CarnetModel carnet, {bool isHeader = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFFEFEFE)],
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(isHeader ? 8 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isHeader ? 8 : 8),
        child: Stack(
          children: [
            // Patrón de seguridad decorativo
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 120,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF8B1538).withOpacity(0.02),
                    ],
                  ),
                ),
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Franja roja superior
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                    ),
                  ),
                ),
                
                // Contenido principal
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección institucional
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Logo container con cruz médica y UAGro
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFDC2626).withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.medical_services,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Detalles institución
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Universidad Autónoma de Guerrero',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'CRES Llano Largo - SASU',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Tipo de carnet
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CARNET DIGITAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Línea divisoria
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        height: 1,
                        color: const Color(0xFFF1F5F9),
                      ),
                      
                      // Sección del estudiante
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Detalles del estudiante
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  carnet.nombreCompleto,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Meta información
                                _buildMetaItem('Matrícula:', carnet.matricula),
                                const SizedBox(height: 6),
                                _buildMetaItem('Correo:', carnet.correo),
                                const SizedBox(height: 6),
                                _buildMetaItem('Edad:', '${carnet.edad} años • ${carnet.sexo}'),
                              ],
                            ),
                          ),
                          
                          // Indicador de estado
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'ACTIVO',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Icono desplegable si es header
                      if (isHeader) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF64748B),
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper para items de metadata
  Widget _buildMetaItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: UAGroColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: UAGroColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937), // Gris oscuro
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusRow(String title, String detail, bool hasCondition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasCondition ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCondition ? Colors.red[100]! : Colors.green[100]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasCondition ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
            color: hasCondition ? Colors.red[700] : Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: detail,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(CarnetModel carnet) {
    // El QR ahora solo contiene la matrícula, el identificador único del alumno.
    final qrDataString = carnet.matricula;

    return _buildSectionCard(
      title: 'CÓDIGO QR DE IDENTIFICACIÓN',
      icon: Icons.qr_code_2_rounded,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!, width: 2),
                ),
                child: QrImageView(
                  data: qrDataString,
                  version: QrVersions.auto,
                  size: 180.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: UAGroColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: UAGroColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Usa este código para identificarte en eventos, servicios y obtener beneficios. Es tu llave de acceso única.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // � ÁREA DE PROMOCIONES ESTILO NETFLIX
  Widget _buildPromocionesArea() {
    return Consumer<SessionProvider>(
      builder: (context, session, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sección RESPONSIVO
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 20,
                    0,
                    isMobile ? 16 : 20,
                    isMobile ? 12 : 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                          ),
                          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0).withOpacity(0.3),
                              blurRadius: isMobile ? 6 : 8,
                              offset: Offset(0, isMobile ? 3 : 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.health_and_safety_rounded,
                          color: Colors.white,
                          size: isMobile ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMobile ? 'PROMOCIONES' : 'PROMOCIONES DE SALUD',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1F2937),
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (!isMobile || constraints.maxWidth > 350) ...[
                              Text(
                                isMobile 
                                    ? 'Campañas para tu bienestar'
                                    : 'Campañas especiales para tu bienestar',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Badge de contador en móvil
                      if (isMobile && session.promociones.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1565C0).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${session.promociones.length}',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            
            // Estado vacío RESPONSIVO
            if (session.promociones.isEmpty) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 20 : 24),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                        border: Border.all(
                          color: Colors.blue[100]!,
                          width: isMobile ? 1.5 : 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.health_and_safety_outlined,
                            size: isMobile ? 48 : 56,
                            color: Colors.blue[400],
                          ),
                          SizedBox(height: isMobile ? 12 : 16),
                          Text(
                            'No hay promociones disponibles',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          Text(
                            isMobile 
                                ? 'Pronto tendremos nuevas promociones para ti'
                                : 'Pronto tendremos nuevas promociones de salud para ti',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ] else ...[
              // 🎬 CARRUSEL DE PROMOCIONES RESPONSIVO PARA MÓVIL
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calcular dimensiones según el ancho de pantalla
                  final screenWidth = constraints.maxWidth;
                  final isMobile = screenWidth < 600;
                  final isTablet = screenWidth >= 600 && screenWidth < 1024;
                  
                  // Configuraciones responsivas
                  double cardWidth;
                  double cardHeight;
                  double horizontalPadding;
                  double cardMargin;
                  
                  if (isMobile) {
                    // Móvil: Tarjetas más anchas, menos margen
                    cardWidth = screenWidth * 0.85; // 85% del ancho de pantalla
                    cardHeight = 280; // Más compacto
                    horizontalPadding = 16;
                    cardMargin = 12;
                  } else if (isTablet) {
                    // Tablet: Tamaño intermedio
                    cardWidth = screenWidth * 0.6;
                    cardHeight = 300;
                    horizontalPadding = 20;
                    cardMargin = 16;
                  } else {
                    // Desktop: Tamaño original
                    cardWidth = 320;
                    cardHeight = 320;
                    horizontalPadding = 20;
                    cardMargin = 16;
                  }
                  
                  return SizedBox(
                    height: cardHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      physics: const BouncingScrollPhysics(), // Mejor para móvil
                      itemCount: session.promociones.length,
                      itemBuilder: (context, index) {
                        final promocion = session.promociones[index];
                        return Container(
                          width: cardWidth,
                          margin: EdgeInsets.only(right: cardMargin),
                          child: _buildMobileOptimizedCard(promocion, isMobile),
                        );
                      },
                    ),
                  );
                },
              ),
              
              // 📱 INDICADORES DE NAVEGACIÓN OPTIMIZADOS PARA MÓVIL
              if (session.promociones.length > 1) ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 12 : 16,
                      ),
                      child: Column(
                        children: [
                          // Indicador de progreso/dots para móvil
                          if (isMobile) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                session.promociones.length.clamp(0, 5), // Máximo 5 dots
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: index == 0 
                                        ? const Color(0xFF1976D2) 
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          
                          // Instrucciones de navegación
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMobile 
                                  ? const Color(0xFF1976D2).withOpacity(0.1)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
                              border: Border.all(
                                color: isMobile 
                                    ? const Color(0xFF1976D2).withOpacity(0.2)
                                    : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isMobile 
                                      ? Icons.swipe_left_rounded 
                                      : Icons.swipe_left_rounded,
                                  size: isMobile ? 20 : 18,
                                  color: isMobile 
                                      ? const Color(0xFF1976D2) 
                                      : Colors.grey[500],
                                ),
                                SizedBox(width: isMobile ? 8 : 8),
                                Text(
                                  isMobile 
                                      ? 'Desliza para más' 
                                      : 'Desliza para ver más promociones',
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 12,
                                    color: isMobile 
                                        ? const Color(0xFF1976D2) 
                                        : Colors.grey[600],
                                    fontWeight: isMobile ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                                if (isMobile && session.promociones.length > 1) ...[
                                  SizedBox(width: isMobile ? 8 : 0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+${session.promociones.length - 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  // 🎯 TARJETA COLORIDA Y ATRACTIVA - CORREGIDA
  Widget _buildNetflixCard(PromocionSaludModel promocion) {
    // Verificar que promocion no sea null
    if (promocion == null) return Container();
    
    final cardData = _getCardDesign(promocion.categoria ?? 'promoción');
    final fechaCreacion = _parsearFecha(promocion.createdAt.toIso8601String());
    final fechaExpiracion = _calcularExpiracion(promocion.createdAt.toIso8601String());
    final diasRestantes = _calcularDiasRestantes(promocion.createdAt.toIso8601String());
    
    // 🎯 Verificar si esta tarjeta está en hover
    final promocionId = promocion.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final isHovered = _hoveredCards.contains(promocionId);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onCardHover(promocionId, true),
      onExit: (_) => _onCardHover(promocionId, false),
      child: GestureDetector(
        onTap: () => _abrirEnlaceDirecto(promocion),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          transform: isHovered ? (Matrix4.identity()..scale(1.015)) : Matrix4.identity(),
          child: Stack(
            children: [
              // 🎨 TARJETA PRINCIPAL
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cardData['primaryColor'].withOpacity(isHovered ? 0.15 : 0.08),
                    blurRadius: isHovered ? 12 : 8,
                    offset: Offset(0, isHovered ? 6 : 4),
                  ),
                ],
              ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                  Colors.white,
                  cardData['primaryColor'].withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cardData['primaryColor'].withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER COMPACTO
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    gradient: cardData['gradient'],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge + Urgencia
                        Row(
                          children: [
                            // Badge principal
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    cardData['icon'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    (promocion.categoria ?? 'Promoción').toUpperCase(),
                                    style: TextStyle(
                                      color: cardData['primaryColor'],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Badge de urgencia
                            if (diasRestantes <= 3) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.red[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '¡${diasRestantes}d!',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Título compacto
                        Text(
                          promocion.programa ?? promocion.departamento ?? 'Promoción de Salud',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // CONTENIDO COMPACTO
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DEPARTAMENTO DESTACADO
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cardData['primaryColor'],
                                cardData['primaryColor'].withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: cardData['primaryColor'].withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cardData['icon'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  promocion.departamento ?? 'Departamento de Salud',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // DESCRIPCIÓN (si existe)
                        if (promocion.descripcion != null && promocion.descripcion.isNotEmpty) ...[
                          Expanded(
                            child: Text(
                              promocion.descripcion,
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        // FECHAS COMPACTAS
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cardData['primaryColor'].withOpacity(0.06),
                                cardData['primaryColor'].withOpacity(0.12),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cardData['primaryColor'].withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Fecha de publicación
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 12,
                                    color: cardData['primaryColor'],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    fechaCreacion,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: cardData['primaryColor'],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              // Días restantes
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: diasRestantes <= 3 
                                    ? Colors.red[100] 
                                    : cardData['primaryColor'].withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$diasRestantes días',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: diasRestantes <= 3 ? Colors.red[700] : cardData['primaryColor'],
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // BOTÓN COMPACTO
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () => _abrirEnlaceDirecto(promocion),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cardData['primaryColor'],
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: cardData['primaryColor'].withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Ver Detalles',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
            ), // Cerrar Container principal
            
            // 🎯 OVERLAY DE PREVIEW (Solo aparece en hover)
            if (isHovered)
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isHovered ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.60),
                          Colors.black.withOpacity(0.75),
                        ],
                      ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 🖼️ IMAGEN DE LA PROMOCIÓN (Si existe)
                              if (promocion.imagenUrl != null && promocion.imagenUrl!.isNotEmpty)
                                Container(
                                  width: 80,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: NetworkImage(promocion.imagenUrl!),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                // 🎯 ICONO DE PREVIEW SI NO HAY IMAGEN
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: cardData['primaryColor'],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: cardData['primaryColor'].withOpacity(0.6),
                                        blurRadius: 20,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.preview_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              
                              const SizedBox(height: 12),
                              
                              // 🎯 TÍTULO PRINCIPAL
                              Text(
                                promocion.titulo ?? promocion.programa ?? 'Promoción de Salud',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // 🎯 RESUMEN/DESCRIPCIÓN
                              Text(
                                promocion.resumen ?? promocion.descripcionCompleta ?? 'Haz clic para ver más detalles',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              const SizedBox(height: 10),
                              
                              // 🔗 PREVIEW DEL LINK
                              if (promocion.link != null && promocion.link!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: cardData['primaryColor'].withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.link_rounded,
                                        color: cardData['primaryColor'],
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _obtenerDominioDeLink(promocion.link!),
                                          style: TextStyle(
                                            color: cardData['primaryColor'],
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              const SizedBox(height: 12),
                              
                              // 🎯 STATS COMPACTAS
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildCompactStat(
                                    Icons.schedule_rounded,
                                    '${diasRestantes}d',
                                    cardData['primaryColor'],
                                  ),
                                  _buildCompactStat(
                                    Icons.category_rounded,
                                    promocion.categoria.substring(0, 3).toUpperCase(),
                                    cardData['primaryColor'],
                                  ),
                                  if (promocion.urgente)
                                    _buildCompactStat(
                                      Icons.priority_high_rounded,
                                      'URGENTE',
                                      Colors.red,
                                    )
                                  else
                                    _buildCompactStat(
                                      Icons.local_hospital_rounded,
                                      'SASU',
                                      cardData['primaryColor'],
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // 🎯 CALL TO ACTION MEJORADO
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cardData['primaryColor'],
                                      cardData['primaryColor'].withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cardData['primaryColor'].withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.open_in_new_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Abrir Promoción',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
          ],
        ), // Cerrar Stack
      ), // Cerrar AnimatedContainer
    ), // Cerrar GestureDetector
    ); // Cerrar MouseRegion
  }

  // 📱 TARJETA OPTIMIZADA PARA MÓVIL
  Widget _buildMobileOptimizedCard(PromocionSaludModel promocion, bool isMobile) {
    // Verificar que promocion no sea null
    if (promocion == null) return Container();
    
    final cardData = _getCardDesign(promocion.categoria ?? 'promoción');
    final fechaCreacion = _parsearFecha(promocion.createdAt.toIso8601String());
    final fechaExpiracion = _calcularExpiracion(promocion.createdAt.toIso8601String());
    final diasRestantes = _calcularDiasRestantes(promocion.createdAt.toIso8601String());
    
    // 🎯 Verificar si esta tarjeta está en hover/touch
    final promocionId = promocion.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final isHovered = _hoveredCards.contains(promocionId);
    
    return GestureDetector(
      onTap: () => _abrirEnlaceDirecto(promocion),
      onTapDown: isMobile ? (_) => _onCardHover(promocionId, true) : null,
      onTapUp: isMobile ? (_) => _onCardHover(promocionId, false) : null,
      onTapCancel: isMobile ? () => _onCardHover(promocionId, false) : null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: !isMobile ? (_) => _onCardHover(promocionId, true) : null,
        onExit: !isMobile ? (_) => _onCardHover(promocionId, false) : null,
        child: AnimatedContainer(
          duration: Duration(milliseconds: isMobile ? 200 : 400),
          curve: Curves.easeOutCubic,
          transform: isHovered ? (Matrix4.identity()..scale(isMobile ? 1.02 : 1.015)) : Matrix4.identity(),
          child: Stack(
            children: [
              // 🎨 TARJETA PRINCIPAL MÓVIL
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: cardData['primaryColor'].withOpacity(isHovered ? 0.2 : 0.1),
                      blurRadius: isHovered ? 8 : 4,
                      offset: Offset(0, isHovered ? 4 : 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          cardData['primaryColor'].withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                      border: Border.all(
                        color: cardData['primaryColor'].withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER COMPACTO PARA MÓVIL
                        Container(
                          height: isMobile ? 80 : 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isMobile ? 14 : 18),
                              topRight: Radius.circular(isMobile ? 14 : 18),
                            ),
                            gradient: cardData['gradient'],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge + Urgencia (más compacto en móvil)
                                Row(
                                  children: [
                                    // Badge principal
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 8 : 12,
                                        vertical: isMobile ? 4 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            cardData['icon'],
                                            style: TextStyle(fontSize: isMobile ? 12 : 14),
                                          ),
                                          SizedBox(width: isMobile ? 4 : 6),
                                          Text(
                                            (promocion.categoria ?? 'Promoción').toUpperCase(),
                                            style: TextStyle(
                                              color: cardData['primaryColor'],
                                              fontSize: isMobile ? 8 : 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const Spacer(),
                                    
                                    // Badge de urgencia (más visible en móvil)
                                    if (diasRestantes <= 3) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 6 : 8,
                                          vertical: isMobile ? 3 : 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withOpacity(0.3),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: isMobile ? 10 : 12,
                                              color: Colors.red[700],
                                            ),
                                            SizedBox(width: isMobile ? 2 : 4),
                                            Text(
                                              '¡${diasRestantes}d!',
                                              style: TextStyle(
                                                color: Colors.red[700],
                                                fontSize: isMobile ? 8 : 10,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                
                                const Spacer(),
                                
                                // Título compacto para móvil
                                Text(
                                  promocion.programa ?? promocion.departamento ?? 'Promoción de Salud',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    letterSpacing: 0.3,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  maxLines: isMobile ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // CONTENIDO COMPACTO PARA MÓVIL
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // DEPARTAMENTO DESTACADO (más compacto)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 8 : 12,
                                    vertical: isMobile ? 6 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        cardData['primaryColor'],
                                        cardData['primaryColor'].withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cardData['primaryColor'].withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(isMobile ? 4 : 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                                        ),
                                        child: Text(
                                          cardData['icon'],
                                          style: TextStyle(fontSize: isMobile ? 12 : 16),
                                        ),
                                      ),
                                      SizedBox(width: isMobile ? 8 : 10),
                                      Expanded(
                                        child: Text(
                                          promocion.departamento ?? 'Departamento de Salud',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isMobile ? 11 : 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(height: isMobile ? 8 : 12),
                                
                                // DESCRIPCIÓN (más corta en móvil)
                                if (promocion.descripcion != null && promocion.descripcion.isNotEmpty) ...[
                                  Expanded(
                                    child: Text(
                                      promocion.descripcion,
                                      style: TextStyle(
                                        color: const Color(0xFF2C3E50),
                                        fontSize: isMobile ? 11 : 12,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: isMobile ? 1 : 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 8 : 12),
                                ],
                                
                                // FECHAS COMPACTAS PARA MÓVIL
                                Container(
                                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        cardData['primaryColor'].withOpacity(0.06),
                                        cardData['primaryColor'].withOpacity(0.12),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                                    border: Border.all(
                                      color: cardData['primaryColor'].withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Fecha de publicación
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: isMobile ? 10 : 12,
                                              color: cardData['primaryColor'],
                                            ),
                                            SizedBox(width: isMobile ? 3 : 4),
                                            Expanded(
                                              child: Text(
                                                fechaCreacion,
                                                style: TextStyle(
                                                  fontSize: isMobile ? 9 : 10,
                                                  color: cardData['primaryColor'],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      SizedBox(width: isMobile ? 8 : 16),
                                      
                                      // Días restantes (más prominente en móvil)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 6 : 8,
                                          vertical: isMobile ? 2 : 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: diasRestantes <= 3 
                                              ? Colors.red[100] 
                                              : cardData['primaryColor'].withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                                        ),
                                        child: Text(
                                          '${diasRestantes}d',
                                          style: TextStyle(
                                            fontSize: isMobile ? 9 : 10,
                                            color: diasRestantes <= 3 
                                                ? Colors.red[700] 
                                                : cardData['primaryColor'],
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Botón de acción más grande para móvil
                                if (isMobile) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: cardData['gradient'],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'VER PROMOCIÓN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 🎯 OVERLAY DE PREVIEW SIMPLIFICADO PARA MÓVIL
              if (isHovered && !isMobile)
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: isHovered ? 1.0 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.50),
                            Colors.black.withOpacity(0.70),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 🖼️ IMAGEN DE LA PROMOCIÓN (Si existe)
                            if (promocion.imagenUrl != null && promocion.imagenUrl!.isNotEmpty)
                              Container(
                                width: 60,
                                height: 45,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(promocion.imagenUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 8),
                            
                            // 📋 TÍTULO DEL PREVIEW
                            Text(
                              promocion.titulo ?? 'Vista previa no disponible',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 6),
                            
                            // 🔗 ENLACE SIMPLIFICADO
                            if (promocion.link != null && promocion.link!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _obtenerDominioDeLink(promocion.link!),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 8),
                            
                            // 🎯 BOTÓN DE ACCIÓN
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: cardData['primaryColor'],
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: cardData['primaryColor'].withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'ABRIR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 HELPER PARA STATS RÁPIDAS EN PREVIEW
  Widget _buildQuickStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // 🎯 HELPER PARA STATS COMPACTAS
  Widget _buildCompactStat(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // Función helper para extraer dominio del link
  String _obtenerDominioDeLink(String link) {
    try {
      final uri = Uri.parse(link);
      String dominio = uri.host;
      
      // Remover 'www.' si existe
      if (dominio.startsWith('www.')) {
        dominio = dominio.substring(4);
      }
      
      return dominio;
    } catch (e) {
      return link.length > 30 ? '${link.substring(0, 30)}...' : link;
    }
  }
  
  // Función para parsear fecha de creación (CORREGIDA)
  String _parsearFecha(String? fechaISO) {
    if (fechaISO == null || fechaISO.isEmpty) {
      return 'Reciente';
    }
    
    try {
      final fecha = DateTime.parse(fechaISO);
      final meses = [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      
      return '${fecha.day} ${meses[fecha.month]} ${fecha.year}';
    } catch (e) {
      return 'Reciente';
    }
  }
  
  // Función para calcular fecha de expiración (CORREGIDA)
  String _calcularExpiracion(String? fechaISO) {
    if (fechaISO == null || fechaISO.isEmpty) {
      return '7 días';
    }
    
    try {
      final fecha = DateTime.parse(fechaISO);
      final expiracion = fecha.add(const Duration(days: 7));
      final meses = [
        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      
      return '${expiracion.day} ${meses[expiracion.month]} ${expiracion.year}';
    } catch (e) {
      return '7 días';
    }
  }
  
  // Función para calcular días restantes (CORREGIDA)
  int _calcularDiasRestantes(String? fechaISO) {
    if (fechaISO == null || fechaISO.isEmpty) {
      return 7; // Por defecto 7 días
    }
    
    try {
      final fecha = DateTime.parse(fechaISO);
      final expiracion = fecha.add(const Duration(days: 7));
      final ahora = DateTime.now();
      final diferencia = expiracion.difference(ahora);
      
      return diferencia.inDays.clamp(0, 7); // Mínimo 0, máximo 7
    } catch (e) {
      return 7;
    }
  }
  
  // Función anterior del botón - ahora reemplazada arriba
  Widget _buildNetflixCardOLD(promocion) {
    final cardData = _getCardDesign(promocion.categoria);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _abrirEnlaceDirecto(promocion),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: cardData['gradient'],
            ),
            child: Stack(
              children: [
                // Patrón de fondo sutil
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      backgroundBlendMode: BlendMode.overlay,
                    ),
                    child: CustomPaint(
                      painter: _PatternPainter(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                ),
                
                // Contenido principal
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              cardData['icon'],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  promocion.departamento,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  promocion.programa,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Título principal
                      Text(
                        promocion.titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Descripción
                      Text(
                        promocion.descripcion,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      // Botón de acción principal
                      Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () => _abrirEnlaceDirecto(promocion),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: cardData['primaryColor'],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Ver ahora',
                                  style: TextStyle(
                                    color: cardData['primaryColor'],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge "NUEVO"
                if (_esPromocionReciente(promocion.createdAt))
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'NUEVO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔗 OBTENER PREVIEW DE LINK
  Future<Map<String, String>> _obtenerPreviewLink(String url) async {
    // Si ya tenemos el preview cached, lo devolvemos
    if (_linkPreviews.containsKey(url)) {
      return _linkPreviews[url]!;
    }

    try {
      // Para webs comunes, podemos hacer inferencias inteligentes
      Map<String, String> preview = {
        'titulo': '',
        'descripcion': '',
        'imagen': '',
        'sitio': '',
      };

      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();

      // Detectar tipos de sitio y generar previews inteligentes
      if (domain.contains('facebook.com')) {
        preview = {
          'titulo': 'Promoción de Salud UAGro',
          'descripcion': 'Información importante sobre salud y bienestar estudiantil.',
          'imagen': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Facebook_f_logo_%282019%29.svg/1024px-Facebook_f_logo_%282019%29.svg.png',
          'sitio': 'Facebook',
        };
      } else if (domain.contains('gob.mx')) {
        preview = {
          'titulo': 'Información Oficial de Salud',
          'descripcion': 'Recursos y guías oficiales del Gobierno de México sobre salud.',
          'imagen': 'https://framework-gb.cdn.gob.mx/landing/img/logoheader.svg',
          'sitio': 'Gobierno de México',
        };
      } else if (domain.contains('youtube.com') || domain.contains('youtu.be')) {
        preview = {
          'titulo': 'Video Educativo de Salud',
          'descripcion': 'Contenido audiovisual sobre promoción de la salud.',
          'imagen': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/YouTube_full-color_icon_%282017%29.svg/1024px-YouTube_full-color_icon_%282017%29.svg.png',
          'sitio': 'YouTube',
        };
      } else {
        // Preview genérico para otros sitios
        preview = {
          'titulo': 'Recurso de Salud',
          'descripcion': 'Información valiosa sobre promoción de la salud y bienestar.',
          'imagen': 'https://cdn-icons-png.flaticon.com/512/3004/3004543.png',
          'sitio': domain,
        };
      }

      // Cachear el resultado
      _linkPreviews[url] = preview;
      return preview;
    } catch (e) {
      // Preview de fallback
      final fallback = {
        'titulo': 'Recurso Educativo',
        'descripcion': 'Contenido relacionado con promoción de la salud.',
        'imagen': 'https://cdn-icons-png.flaticon.com/512/3004/3004543.png',
        'sitio': 'Enlace externo',
      };
      _linkPreviews[url] = fallback;
      return fallback;
    }
  }

  // 🏥 CARD INDIVIDUAL DE PROMOCIÓN CON PREVIEW
  Widget _buildPromocionCard(promocion) {
    // Convertir color hex a Color
    Color cardColor;
    try {
      cardColor = Color(int.parse(promocion.colorTema.replaceFirst('#', '0xFF')));
    } catch (e) {
      cardColor = UAGroColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: _modoOscuro ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_modoOscuro ? Colors.white : Colors.black).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _mostrarDetallePromocion(promocion),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview del Link (si existe)
                if (promocion.link != null && promocion.link.isNotEmpty)
                  FutureBuilder<Map<String, String>>(
                    future: _obtenerPreviewLink(promocion.link),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final preview = snapshot.data!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardColor.withOpacity(0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Imagen del preview
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    color: cardColor.withOpacity(0.2),
                                    child: preview['imagen']!.isNotEmpty
                                        ? Image.network(
                                            preview['imagen']!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(Icons.link, color: cardColor, size: 24),
                                          )
                                        : Icon(Icons.link, color: cardColor, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Info del preview
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preview['sitio']!,
                                        style: TextStyle(
                                          color: cardColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        preview['titulo']!,
                                        style: TextStyle(
                                          color: _modoOscuro ? Colors.white : Colors.black87,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.open_in_new, color: cardColor, size: 16),
                              ],
                            ),
                          ),
                        );
                      }
                      return Container(
                        height: 50,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: cardColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.link, color: cardColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Cargando preview...',
                                style: TextStyle(
                                  color: (_modoOscuro ? Colors.white : Colors.black87).withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                // Header con icono y categoría
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        promocion.iconoTipo,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promocion.categoria.toUpperCase(),
                            style: TextStyle(
                              color: cardColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            promocion.departamento,
                            style: TextStyle(
                              color: (_modoOscuro ? Colors.white : Colors.black87).withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${promocion.diasRestantes}d',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Título
                Text(
                  promocion.titulo,
                  style: TextStyle(
                    color: _modoOscuro ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Descripción
                Expanded(
                  child: Text(
                    promocion.descripcion,
                    style: TextStyle(
                      color: (_modoOscuro ? Colors.white : Colors.black87).withOpacity(0.7),
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Botón de acción mejorado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cardColor, cardColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.open_in_new, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Ver Información',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🏥 MOSTRAR DETALLE DE PROMOCIÓN
  void _mostrarDetallePromocion(promocion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(promocion.iconoTipo, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                promocion.titulo,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              promocion.descripcion,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.local_hospital, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Departamento: ${promocion.departamento}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Publicado: ${promocion.createdAt.day}/${promocion.createdAt.month}/${promocion.createdAt.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Marcar como vista y cerrar
              context.read<SessionProvider>().marcarPromocionVista(promocion.id);
              Navigator.of(context).pop();
            },
            child: const Text('Entendido'),
          ),
          if (promocion.link != null && promocion.link!.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                // TODO: Abrir enlace externo
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Abrir: ${promocion.link}')),
                );
              },
              child: const Text('Ver más'),
            ),
        ],
      ),
    );
  }

  // 🎨 OBTENER DISEÑO SEGÚN CATEGORÍA
  Map<String, dynamic> _getCardDesign(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'prevención':
        return {
          'gradient': const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
            stops: [0.0, 1.0],
          ),
          'primaryColor': const Color(0xFF1565C0),
          'icon': '🛡️',
        };
      case 'consulta médica':
      case 'consulta':
        return {
          'gradient': const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B1538), Color(0xFFC41E3A)],
            stops: [0.0, 1.0],
          ),
          'primaryColor': const Color(0xFF8B1538),
          'icon': '🏥',
        };
      case 'emergencia':
      case 'urgente':
        return {
          'gradient': const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B1538), Color(0xFFC41E3A)],
            stops: [0.0, 1.0],
          ),
          'primaryColor': const Color(0xFFC41E3A),
          'icon': '🚨',
        };
      case 'promoción':
      case 'promociones':
        return {
          'gradient': const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
            stops: [0.0, 1.0],
          ),
          'primaryColor': const Color(0xFF1565C0),
          'icon': '📢',
        };
      case 'información del sistema':
      default:
        return {
          'gradient': const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF78909C), Color(0xFF546E7A)],
            stops: [0.0, 1.0],
          ),
          'primaryColor': const Color(0xFF78909C),
          'icon': '📱',
        };
    }
  }

  // 🕒 VERIFICAR SI ES PROMOCIÓN RECIENTE
  bool _esPromocionReciente(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays <= 7;
  }

  // 🎬 ABRIR ENLACE DIRECTAMENTE
  void _abrirEnlaceDirecto(promocion) async {
    // Efecto visual de clic
    HapticFeedback.lightImpact();
    
    try {
      // Marcar como vista
      context.read<SessionProvider>().marcarPromocionVista(promocion.id);
      
      // Si hay enlace, abrirlo directamente
      if (promocion.link.isNotEmpty) {
        final Uri url = Uri.parse(promocion.link);
        
        // Intentar abrir el enlace
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication, // Abrir en navegador externo
          );
          
          // Mostrar mensaje de confirmación
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Abriendo: ${_obtenerDominioDeLink(promocion.link)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Si no se puede abrir, mostrar error
          throw 'No se pudo abrir el enlace';
        }
      } else {
        // Si no hay enlace, mostrar detalle
        _mostrarDetallePromocion(promocion);
      }
    } catch (e) {
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No se pudo abrir el enlace. Verifica tu conexión.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 🔗 ABRIR ENLACE SIMPLE
  void _abrirEnlaceDirectoSimple(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text('Enlace abierto exitosamente'),
              ],
            ),
            backgroundColor: UAGroColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      _mostrarErrorEnlace();
    }
  }

  // 📋 MOSTRAR TÉRMINOS Y CONDICIONES
  void _mostrarTerminosCondiciones() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.description, color: UAGroColors.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Términos y Condiciones SASU')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sistema de Atención en Salud Universitaria (SASU)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Al participar en el sistema SASU, usted acepta:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Proporcionar información veraz sobre su estado de salud.\n\n'
                '2. Mantener actualizados sus datos de contacto de emergencia.\n\n'
                '3. Seguir las recomendaciones médicas proporcionadas.\n\n'
                '4. Respetar los horarios de citas médicas programadas.\n\n'
                '5. Sus datos serán protegidos conforme a la Ley de Protección de Datos Personales.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PROYECTO PILOTO: Este sistema está en fase de prueba para mejorar la atención de salud estudiantil en CRES Llano Largo.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // 🚨 MOSTRAR NÚMEROS DE EMERGENCIA
  void _mostrarNumerosEmergencia() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(child: Text('Emergencias Acapulco, Gro.')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEmergencyItem('🚨', 'Emergencias General', '911'),
              _buildEmergencyItem('🚑', 'Cruz Roja Sector Diamante', '744 442 4883'),
              _buildEmergencyItem('🚒', 'Bomberos Acapulco', '744 106 0885'),
              _buildEmergencyItem('⚕️', 'IMSS Clínica 29', '744 435 1800'),
              _buildEmergencyItem('🌊', 'Protección Civil Acapulco', '744 440 7031'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠️ En caso de emergencia médica grave, marque 911 inmediatamente.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // 📞 HELPER PARA ITEMS DE EMERGENCIA
  Widget _buildEmergencyItem(String emoji, String nombre, String numero) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(numero, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ LOADING ELEGANTE ESTILO STREAMING
  void _mostrarLoadingElegante() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(UAGroColors.primary),
                      strokeWidth: 3,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                '🎬 Cargando promoción...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preparando el mejor contenido para ti',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔗 MOSTRAR ENLACE FINAL ELEGANTE
  void _mostrarEnlaceFinal(promocion) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header colorido
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: _getCardDesign(promocion.categoria)['gradient'],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _getCardDesign(promocion.categoria)['icon'],
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      promocion.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Contenido
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      promocion.descripcion,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Info adicional
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.business, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                promocion.departamento,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.link, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  promocion.link,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cerrar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Aquí se abriría el enlace real
                              _mostrarMensajeEnlace();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getCardDesign(promocion.categoria)['primaryColor'],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.open_in_new, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Abrir enlace',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // � CAMBIAR FOTO DE PERFIL
  void _cambiarFotoPerfil() {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files?.isNotEmpty == true) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(files![0]);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _fotoPerfil = reader.result as Uint8List;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.photo_camera, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Text('Foto de perfil actualizada'),
                ],
              ),
              backgroundColor: UAGroColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        });
      }
    });
  }

  // �📱 MENSAJE DE ENLACE SIMULADO
  void _mostrarMensajeEnlace() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.open_in_new, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text('Enlace abierto exitosamente'),
          ],
        ),
        backgroundColor: UAGroColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ❌ ERROR AL ABRIR ENLACE
  void _mostrarErrorEnlace() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Error al procesar la promoción'),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 📱 MENÚ LATERAL MODERNO PARA UNIVERSITARIOS (VERSIÓN SIMPLIFICADA)
  Widget _buildModernDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header simple
          Consumer<SessionProvider>(
            builder: (context, session, child) {
              final carnet = session.carnet;
              return UserAccountsDrawerHeader(
                accountName: Text(carnet?.nombreCompleto ?? 'Estudiante UAGro'),
                accountEmail: Text(carnet?.programa ?? 'Programa Académico'),
                currentAccountPicture: GestureDetector(
                  onTap: () => _cambiarFotoPerfil(),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: _fotoPerfil != null ? MemoryImage(_fotoPerfil!) : null,
                    child: _fotoPerfil == null 
                      ? Stack(
                          children: [
                            Icon(Icons.person, color: UAGroColors.primary, size: 40),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: UAGroColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.camera_alt, color: Colors.white, size: 12),
                              ),
                            ),
                          ],
                        )
                      : null,
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [UAGroColors.primary, UAGroColors.primary.withOpacity(0.8)],
                  ),
                ),
              );
            },
          ),
          
          // Mi QR
          ListTile(
            leading: Icon(Icons.qr_code, color: UAGroColors.primary),
            title: const Text('Mi Código QR'),
            onTap: () {
              Navigator.pop(context);
              _showQRDialog(context);
            },
          ),
          
          const Divider(),
          
          // Salud
          ListTile(
            leading: const Icon(Icons.health_and_safety, color: Colors.red),
            title: const Text('Salud'),
            subtitle: const Text('Citas médicas y promociones'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CitasScreen()),
              );
            },
          ),

          // 📋 CONSULTAS DE ATENCIÓN
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.assignment, color: Colors.blue.shade600, size: 20),
            ),
            title: const Text('Mis Consultas de Atención'),
            subtitle: const Text('Historial de atención en servicios'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConsultasScreen()),
              );
            },
          ),
          
          // 💉 VACUNACIÓN
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.vaccines_rounded, color: Colors.green, size: 20),
            ),
            title: const Text('Tarjeta de Vacunación'),
            subtitle: Consumer<SessionProvider>(
              builder: (context, session, child) {
                final count = session.vacunas.length;
                return Text(
                  count > 0 ? '$count vacunas registradas' : 'Sin registros',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                );
              },
            ),
            onTap: () {
              Navigator.pop(context); // Cerrar drawer
              Navigator.pushNamed(context, '/vacunas');
            },
          ),
          
          // Revista IMSS Familia
          ListTile(
            leading: const Icon(Icons.menu_book, color: Colors.blue),
            title: const Text('Revista IMSS Familia'),
            subtitle: const Text('Recursos de salud familiar'),
            onTap: () {
              Navigator.pop(context);
              _abrirEnlaceDirectoSimple('https://www.imss.gob.mx/revista-familia-imss');
            },
          ),
          
          const Divider(),
          
          // Sincronizar
          ListTile(
            leading: Icon(Icons.sync, color: UAGroColors.primary),
            title: const Text('Sincronizar Datos'),
            onTap: () {
              Navigator.pop(context);
              context.read<SessionProvider>().loadPromociones();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos sincronizados')),
              );
            },
          ),
          
          // Modo Oscuro
          ListTile(
            leading: const Icon(Icons.dark_mode, color: Colors.purple),
            title: const Text('Modo Oscuro'),
            subtitle: Text(_modoOscuro ? 'Activado' : 'Desactivado'),
            trailing: Switch(
              value: _modoOscuro,
              onChanged: (value) {
                setState(() {
                  _modoOscuro = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(_modoOscuro ? Icons.dark_mode : Icons.light_mode, 
                             color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Text(_modoOscuro ? 'Modo oscuro activado' : 'Modo claro activado'),
                      ],
                    ),
                    backgroundColor: UAGroColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
            ),
          ),
          
          const Divider(),
          
          // Términos y Condiciones
          ListTile(
            leading: const Icon(Icons.description, color: Colors.orange),
            title: const Text('Términos y Condiciones'),
            subtitle: const Text('Política de privacidad SASU'),
            onTap: () {
              Navigator.pop(context);
              _mostrarTerminosCondiciones();
            },
          ),
          
          // Números de Emergencia
          ListTile(
            leading: const Icon(Icons.emergency, color: Colors.red),
            title: const Text('Emergencias Acapulco'),
            subtitle: const Text('Números importantes'),
            onTap: () {
              Navigator.pop(context);
              _mostrarNumerosEmergencia();
            },
          ),
        ],
      ),
    );
  }

  // Diálogo simple para mostrar QR
  void _showQRDialog(BuildContext context) {
    final carnet = context.read<SessionProvider>().carnet;
    if (carnet == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mi Código QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: carnet.matricula ?? 'UAGro-Student',
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 16),
            Text(carnet.matricula ?? 'UAGro-000000'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // 🎓 HEADER DEL DRAWER CON PERFIL COMPACTO
  Widget _buildDrawerHeader(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, child) {
        final carnet = session.carnet;
        final isMobile = _isMobileDevice(context);
        
        return Container(
          height: isMobile ? 160 : 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                UAGroColors.primary,
                UAGroColors.primary.withOpacity(0.8),
                const Color(0xFF1565C0),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 📸 FOTO DE PERFIL CIRCULAR
                      Container(
                        width: isMobile ? 50 : 60,
                        height: isMobile ? 50 : 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: isMobile ? 23 : 28,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: isMobile ? 24 : 28, color: UAGroColors.primary),
                        ),
                      ),
                      
                      SizedBox(width: isMobile ? 12 : 16),
                      
                      // 📝 INFO BÁSICA
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              carnet?.nombreCompleto ?? 'Estudiante UAGro',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              carnet?.programa ?? 'Programa Académico',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // 🎯 BADGES DE STATUS
                  Row(
                    children: [
                      // Badge de matrícula
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 10,
                          vertical: isMobile ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Text(
                          carnet?.matricula ?? 'UAGro-000000',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Badge de categoría
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 8,
                          vertical: isMobile ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          carnet?.categoria ?? 'Estudiante',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 9 : 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🆔 SECCIÓN IDENTIDAD CON QR EXPANDIBLE
  Widget _buildIdentitySection(BuildContext context) {
    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [UAGroColors.primary, UAGroColors.primary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 20),
      ),
      title: const Text(
        'Mi Código QR',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      ),
      subtitle: const Text(
        'Mostrar identificación digital',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
        ),
      ),
      children: [
        Consumer<SessionProvider>(
          builder: (context, session, child) {
            final carnet = session.carnet;
            if (carnet == null) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Carnet no disponible'),
              );
            }
            
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: carnet.matricula ?? 'UAGro-Student',
                          version: QrVersions.auto,
                          size: 120,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          carnet.matricula ?? 'UAGro-000000',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Botón de compartir
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implementar compartir QR
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Función de compartir próximamente')),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Compartir QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UAGroColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 🏥 SERVICIOS ESTUDIANTILES
  Widget _buildStudentServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Servicios Estudiantiles',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // 🏥 SALUD
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: Colors.red, size: 20),
          ),
          title: const Text(
            'Salud',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Citas médicas y promociones',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          onTap: () {
            Navigator.pop(context); // Cerrar drawer
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CitasScreen()),
            );
          },
        ),
        
        // 💉 VACUNACIÓN
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.vaccines_rounded, color: Colors.green, size: 20),
          ),
          title: const Text(
            'Tarjeta de Vacunación',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Consumer<SessionProvider>(
            builder: (context, session, child) {
              final count = session.vacunas.length;
              return Text(
                count > 0 ? '$count vacunas registradas' : 'Sin registros',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              );
            },
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          onTap: () {
            Navigator.pop(context); // Cerrar drawer
            Navigator.pushNamed(context, '/vacunas');
          },
        ),
      ],
    );
  }

  // ⚡ QUICK ACTIONS
  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // 🔄 SYNC DATA
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: UAGroColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.sync_rounded, color: UAGroColors.primary, size: 20),
          ),
          title: const Text(
            'Sincronizar Datos',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Actualizar información',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          onTap: () {
            Navigator.pop(context); // Cerrar drawer
            context.read<SessionProvider>().loadPromociones();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Datos sincronizados'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        
        // 🌙 MODO OSCURO (placeholder)
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.dark_mode_rounded, color: Colors.purple, size: 20),
          ),
          title: const Text(
            'Modo Oscuro',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Próximamente disponible',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          trailing: Switch(
            value: false,
            onChanged: null, // Deshabilitado por ahora
            activeColor: UAGroColors.primary,
          ),
        ),
        
        // ⚙️ CONFIGURACIÓN (placeholder)
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.settings_rounded, color: Colors.grey, size: 20),
          ),
          title: const Text(
            'Configuración',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Notificaciones y privacidad',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          onTap: () {
            Navigator.pop(context); // Cerrar drawer
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuración próximamente')),
            );
          },
        ),
      ],
    );
  }

  // 🔄 FOOTER DEL DRAWER
  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.school_rounded,
            size: 16,
            color: UAGroColors.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Universidad Autónoma de Guerrero',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'v2.0',
            style: TextStyle(
              fontSize: 10,
              color: UAGroColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 MOSTRAR SELECTOR DE DISEÑO
  void _mostrarSelectorDiseno(BuildContext context) {
    final session = context.read<SessionProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.palette_outlined, color: Color(0xFF8B1538)),
            SizedBox(width: 12),
            Text('Elegir diseño del carnet'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecciona tu diseño favorito del carnet digital:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            
            // Opción: Diseño Wallet
            _buildDisenoOption(
              context: context,
              titulo: 'Wallet Clásico',
              descripcion: 'Diseño tipo billetera con promociones',
              icono: Icons.account_balance_wallet_outlined,
              valor: 'wallet',
              seleccionado: session.carnetDesign == 'wallet',
              onTap: () async {
                await session.cambiarDiseno('wallet');
                Navigator.pop(context);
              },
            ),
            
            const SizedBox(height: 12),
            
            // Opción: Diseño Moderno
            _buildDisenoOption(
              context: context,
              titulo: 'Moderno Gradient',
              descripcion: 'Diseño con gradientes y tarjeta central',
              icono: Icons.credit_card_outlined,
              valor: 'modern',
              seleccionado: session.carnetDesign == 'modern',
              onTap: () async {
                await session.cambiarDiseno('modern');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // Widget helper para opciones de diseño
  Widget _buildDisenoOption({
    required BuildContext context,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required String valor,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: seleccionado ? const Color(0xFF8B1538) : Colors.grey.shade300,
            width: seleccionado ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: seleccionado ? const Color(0xFF8B1538).withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icono,
              color: seleccionado ? const Color(0xFF8B1538) : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: seleccionado ? const Color(0xFF8B1538) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (seleccionado)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF8B1538),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

// 🎨 PAINTER PARA PATRÓN DE FONDO
class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;
    
    // Dibujar patrón de líneas diagonales
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}