// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:math' as math;
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:carnet_digital_uagro/models/carnet_model.dart';
import 'package:carnet_digital_uagro/models/promocion_salud_model.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/screens/citas_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CarnetScreenNew extends StatefulWidget {
  const CarnetScreenNew({super.key});

  @override
  State<CarnetScreenNew> createState() => _CarnetScreenNewState();
}

class _CarnetScreenNewState extends State<CarnetScreenNew>
    with SingleTickerProviderStateMixin {
  static const Color _uagroRed = Color(0xFF7A0019);
  static const Color _uagroBlue = Color(0xFF0D2A5C);
  static const Color _success = Color(0xFF22C55E);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);
  static const int _maxPhotoBytes = 2 * 1024 * 1024;
  static const Set<String> _allowedPhotoMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  late final AnimationController _introController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final ScrollController _scrollController;

  final GlobalKey _topKey = GlobalKey();
  final GlobalKey _credentialKey = GlobalKey();
  final GlobalKey _academicKey = GlobalKey();
  final GlobalKey _medicalKey = GlobalKey();
  final GlobalKey _emergencyKey = GlobalKey();
  final GlobalKey _vaccinesKey = GlobalKey();
  final GlobalKey _appointmentsKey = GlobalKey();
  final GlobalKey _promotionsKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _helpKey = GlobalKey();

  int _mobileTab = 0;
  String _activeSection = 'Inicio';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _introController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _introController, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
        );
    _introController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        final carnet = session.carnet;

        if (carnet == null) {
          return const Scaffold(
            backgroundColor: _background,
            body: Center(child: CircularProgressIndicator(color: _uagroRed)),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1100;
            final isTablet = width >= 760 && width < 1100;

            return Scaffold(
              backgroundColor: _background,
              appBar: isDesktop ? null : _buildMobileTopBar(context, carnet),
              bottomNavigationBar: isDesktop
                  ? null
                  : _buildBottomNav(context, carnet),
              body: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: isDesktop
                      ? _buildDesktopShell(context, session, carnet)
                      : _buildMobileTabletShell(
                          context,
                          session,
                          carnet,
                          isTablet,
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildMobileTopBar(
    BuildContext context,
    CarnetModel carnet,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: _ink,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _showMobileMenu(context, carnet),
        tooltip: 'Menú',
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Image.asset('assets/uagro_logo.png', width: 30, height: 30),
          const SizedBox(width: 8),
          const Text(
            'UAGro',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      actions: [
        _NotificationButton(onPressed: _showNotificationsPanel),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDesktopShell(
    BuildContext context,
    SessionProvider session,
    CarnetModel carnet,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSidebar(context, carnet),
        Expanded(
          child: Column(
            children: [
              _buildDesktopHeader(carnet),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildMainContent(
                              context,
                              session,
                              carnet,
                              compact: false,
                            ),
                          ),
                          if (MediaQuery.of(context).size.width >= 1360) ...[
                            const SizedBox(width: 28),
                            SizedBox(
                              width: 290,
                              child: _buildQuickAccessPanel(
                                context,
                                carnet,
                                session.carnetPhotoBytes,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletShell(
    BuildContext context,
    SessionProvider session,
    CarnetModel carnet,
    bool isTablet,
  ) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        isTablet ? 28 : 14,
        isTablet ? 22 : 14,
        isTablet ? 28 : 14,
        92,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 820 : 520),
          child: _buildMainContent(
            context,
            session,
            carnet,
            compact: !isTablet,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, CarnetModel carnet) {
    final items = [
      _NavItem(
        Icons.home_rounded,
        'Inicio',
        () => _scrollToSection(_topKey, 'Inicio'),
      ),
      _NavItem(
        Icons.badge_rounded,
        'Mi Carnet',
        () => _scrollToSection(_credentialKey, 'Mi Carnet'),
      ),
      _NavItem(
        Icons.school_rounded,
        'Información Académica',
        () => _scrollToSection(_academicKey, 'Información Académica'),
      ),
      _NavItem(
        Icons.health_and_safety_rounded,
        'Información Médica',
        () => _scrollToSection(_medicalKey, 'Información Médica'),
      ),
      _NavItem(
        Icons.vaccines_rounded,
        'Vacunas',
        () => _scrollToSection(_vaccinesKey, 'Vacunas'),
      ),
      _NavItem(
        Icons.event_available_rounded,
        'Citas y Consultas',
        () => _scrollToSection(_appointmentsKey, 'Citas y Consultas'),
      ),
      _NavItem(
        Icons.support_agent_rounded,
        'Centro de Atención',
        () => Navigator.pushNamed(context, '/atencion'),
      ),
      _NavItem(
        Icons.auto_awesome_rounded,
        'Promociones',
        () => _scrollToSection(_promotionsKey, 'Promociones'),
      ),
      _NavItem(
        Icons.settings_rounded,
        'Ajustes',
        () => _scrollToSection(_settingsKey, 'Ajustes'),
      ),
      _NavItem(
        Icons.help_outline_rounded,
        'Ayuda',
        () => _scrollToSection(_helpKey, 'Ayuda'),
      ),
    ];

    return Container(
      width: 248,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_uagroBlue, Color(0xFF06172F)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 132,
            left: 36,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset('assets/uagro_logo.png', width: 150),
            ),
          ),
          Positioned(
            bottom: -32,
            left: -18,
            right: -18,
            child: Transform.rotate(
              angle: -0.12,
              child: Container(height: 18, color: _uagroRed),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/uagro_logo.png',
                        width: 52,
                        height: 52,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UAGro',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            Text(
                              'Universidad Autónoma\nde Guerrero',
                              style: TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ...items.asMap().entries.map((entry) {
                    final selected = entry.value.label == _activeSection;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SidebarButton(
                        item: entry.value,
                        selected: selected,
                      ),
                    );
                  }),
                  const Spacer(),
                  _SidebarButton(
                    item: _NavItem(Icons.logout_rounded, 'Cerrar sesión', () {
                      context.read<SessionProvider>().logout();
                      Navigator.of(context).pushReplacementNamed('/login');
                    }),
                    selected: false,
                    danger: false,
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    '"Universidad de Calidad\ncon Inclusión Social"',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'SASU - Sistema de Atención\nen Salud Universitaria',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Versión 2.0.0',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(CarnetModel carnet) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _line.withValues(alpha: 0.85)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${_firstName(carnet.nombreCompleto)}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Bienvenido a tu Carnet Digital Universitario',
                  style: TextStyle(color: _muted, fontSize: 14),
                ),
              ],
            ),
          ),
          const Text(
            'Última actualización:\n09/06/2026 04:18 p. m.',
            textAlign: TextAlign.right,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
          ),
          const SizedBox(width: 18),
          _NotificationButton(onPressed: _showNotificationsPanel),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    SessionProvider session,
    CarnetModel carnet, {
    required bool compact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(key: _topKey, height: 0),
        KeyedSubtree(
          key: _credentialKey,
          child: _DigitalCredentialCard(
            carnet: carnet,
            compact: compact,
            photoBytes: session.carnetPhotoBytes,
            onQrTap: () => _showQRModal(carnet),
            onShareTap: () => _shareCarnet(carnet),
            onPhotoTap: () => _showPhotoOptions(carnet),
          ),
        ),
        const SizedBox(height: 14),
        _buildCriticalMedicalSection(carnet, compact),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _academicKey,
          child: _InfoPanel(
            icon: Icons.school_rounded,
            iconColor: const Color(0xFF0B67C7),
            title: 'Información Académica',
            initiallyExpanded: !compact,
            children: [
              _KeyValueGrid(
                compact: compact,
                items: [
                  _InfoPair('Programa', _fallback(carnet.programa)),
                  _InfoPair('Semestre', '2° Semestre'),
                  _InfoPair('Categoría', _fallback(carnet.categoria)),
                  _InfoPair(
                    'No. Afiliación',
                    _fallback(carnet.numeroAfiliacion, empty: '0000'),
                  ),
                  _InfoPair(
                    'Seguro Universitario',
                    _fallback(carnet.usoSeguroUniversitario, empty: 'No'),
                  ),
                  _InfoPair('Donante', _fallback(carnet.donante, empty: 'No')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _medicalKey,
          child: _InfoPanel(
            icon: Icons.medical_services_rounded,
            iconColor: _danger,
            title: 'Información Médica',
            initiallyExpanded: !compact,
            children: [_MedicalStatusGrid(carnet: carnet, compact: compact)],
          ),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _emergencyKey,
          child: _InfoPanel(
            icon: Icons.phone_in_talk_rounded,
            iconColor: const Color(0xFF0B67C7),
            title: 'Contacto de Emergencia',
            initiallyExpanded: true,
            children: [
              _EmergencyContactCard(
                name: _fallback(
                  carnet.emergenciaContacto,
                  empty: 'No registrado',
                ),
                phone: _fallback(
                  carnet.emergenciaTelefono,
                  empty: 'Sin teléfono',
                ),
                onCall: () => _callEmergency(carnet.emergenciaTelefono),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _vaccinesKey,
          child: _InfoPanel(
            icon: Icons.vaccines_rounded,
            iconColor: const Color(0xFF16A34A),
            title: 'Vacunas',
            actionText: 'Abrir módulo',
            initiallyExpanded: compact,
            onAction: () => Navigator.pushNamed(context, '/vacunas'),
            children: const [
              _SimpleNotice(
                icon: Icons.verified_user_rounded,
                title: 'Expediente de vacunación',
                body:
                    'Consulta y actualiza tus registros desde el módulo de vacunas.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _appointmentsKey,
          child: _InfoPanel(
            icon: Icons.event_available_rounded,
            iconColor: const Color(0xFF0B67C7),
            title: 'Citas y Consultas',
            actionText: 'Abrir módulo',
            initiallyExpanded: compact,
            onAction: () => _goToCitas(context),
            children: const [
              _SimpleNotice(
                icon: Icons.calendar_month_rounded,
                title: 'Atención universitaria',
                body:
                    'Revisa tus citas médicas y el seguimiento de consultas SASU.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _InfoPanel(
          icon: Icons.support_agent_rounded,
          iconColor: _uagroRed,
          title: 'Centro de Atención Universitaria',
          actionText: 'Abrir módulo',
          initiallyExpanded: compact,
          onAction: () => Navigator.pushNamed(context, '/atencion'),
          children: const [
            _SimpleNotice(
              icon: Icons.forum_rounded,
              title: 'Seguimiento de solicitudes',
              body:
                  'Consulta tus tickets y crea nuevas solicitudes de atención universitaria.',
              tinted: true,
            ),
          ],
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _promotionsKey,
          child: _buildPromotionsPanel(session.promociones),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _settingsKey,
          child: const _InfoPanel(
            icon: Icons.settings_rounded,
            iconColor: _uagroBlue,
            title: 'Ajustes',
            initiallyExpanded: false,
            children: [
              _SimpleNotice(
                icon: Icons.tune_rounded,
                title: 'Próximamente disponible',
                body:
                    'La configuración personalizada del carnet estará disponible en una próxima actualización.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        KeyedSubtree(
          key: _helpKey,
          child: const _InfoPanel(
            icon: Icons.help_outline_rounded,
            iconColor: Color(0xFF0B67C7),
            title: 'Ayuda',
            initiallyExpanded: true,
            children: [
              _SimpleNotice(
                icon: Icons.support_agent_rounded,
                title: 'Soporte SASU',
                body:
                    'Contacta al área SASU de tu campus para recibir ayuda con tu carnet digital.',
                tinted: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!compact) _buildTrustFooter(),
      ],
    );
  }

  Widget _buildCriticalMedicalSection(CarnetModel carnet, bool compact) {
    final allergyCount = _splitMedicalList(carnet.alergias).length;
    final cards = [
      _CriticalInfo(
        Icons.bloodtype_rounded,
        _danger,
        'Tipo de Sangre',
        _fallback(carnet.tipoSangre, empty: 'No registrado'),
        'Ver detalles',
        () => _showBloodTypeDetails(carnet),
      ),
      _CriticalInfo(
        Icons.warning_amber_rounded,
        _warning,
        'Alergias',
        allergyCount == 1
            ? '1 registrada'
            : allergyCount > 1
            ? '$allergyCount registradas'
            : 'Sin registro',
        'Ver detalles',
        () => _showAllergyDetails(carnet),
      ),
      _CriticalInfo(
        Icons.favorite_rounded,
        const Color(0xFF52B788),
        'Donante',
        _fallback(carnet.donante, empty: 'No'),
        'Ver detalles',
        () => _showDonorDetails(carnet),
      ),
      _CriticalInfo(
        Icons.phone_rounded,
        const Color(0xFF0B67C7),
        'Contacto de Emergencia',
        _fallback(carnet.emergenciaContacto, empty: 'No registrado'),
        'Ver detalles',
        () => _showEmergencyDetails(carnet),
      ),
    ];

    return _SurfacePanel(
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionIcon(
                Icons.health_and_safety_rounded,
                Color(0xFF0B67C7),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Información médica crítica',
                  style: TextStyle(
                    color: _ink,
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.info_outline_rounded,
                color: _muted.withValues(alpha: 0.8),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (compact)
            Column(
              children: cards
                  .map(
                    (card) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CriticalRow(info: card),
                    ),
                  )
                  .toList(),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 126,
              ),
              itemBuilder: (context, index) =>
                  _CriticalCard(info: cards[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildPromotionsPanel(List<PromocionSaludModel> promociones) {
    return _InfoPanel(
      icon: Icons.auto_awesome_rounded,
      iconColor: _warning,
      title: 'Promociones de Salud',
      initiallyExpanded: true,
      children: [
        if (promociones.isEmpty)
          const _SimpleNotice(
            icon: Icons.card_giftcard_rounded,
            title: 'No hay promociones disponibles',
            body: 'Pronto tendremos nuevas promociones de salud para ti.',
            tinted: true,
          )
        else
          Column(
            children: promociones
                .take(3)
                .map(
                  (promo) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PromotionTile(
                      promocion: promo,
                      onTap: () => _openPromotion(promo),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildQuickAccessPanel(
    BuildContext context,
    CarnetModel carnet,
    Uint8List? photoBytes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Vista rápida del carnet',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _SurfacePanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _StudentPhoto(
                name: carnet.nombreCompleto,
                fotoUrl: carnet.fotoUrl,
                photoBytes: photoBytes,
                size: 84,
                onTap: () => _showPhotoOptions(carnet),
                labelColor: _muted,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => _showQRModal(carnet),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: QrImageView(
                    data: carnet.matricula,
                    size: 190,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                carnet.nombreCompleto,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Matrícula ${carnet.matricula}',
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const _StatusPill(label: 'ACTIVO'),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyCarnetLink(carnet),
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Copiar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: _uagroRed),
                      onPressed: () => _showQRModal(carnet),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                      label: const Text('Abrir QR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SurfacePanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  _SectionIcon(Icons.verified_user_rounded, _success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Estado del carnet',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Activo y listo para identificación institucional.',
                style: TextStyle(color: _muted, height: 1.35),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _scrollToSection(_helpKey, 'Ayuda'),
                icon: const Icon(Icons.help_outline_rounded),
                label: const Text('Necesito ayuda'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrustFooter() {
    final items = [
      _TrustItem(
        Icons.shield_rounded,
        'Seguro y confiable',
        'Datos protegidos por controles institucionales.',
      ),
      _TrustItem(
        Icons.sync_rounded,
        'Siempre actualizado',
        'La información se sincroniza con sistemas SASU.',
      ),
      _TrustItem(
        Icons.qr_code_2_rounded,
        'Código QR',
        'Comparte tu carnet cuando lo necesites.',
      ),
      _TrustItem(
        Icons.help_outline_rounded,
        '¿Necesitas ayuda?',
        'Contáctanos para soporte universitario.',
      ),
    ];

    return _SurfacePanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: const Color(0xFF0B67C7)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.body,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, CarnetModel carnet) {
    return NavigationBar(
      height: 70,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      selectedIndex: _mobileTab,
      onDestinationSelected: (index) {
        setState(() => _mobileTab = index);
        switch (index) {
          case 0:
            _scrollToSection(_topKey, 'Inicio');
            break;
          case 1:
            _scrollToSection(_credentialKey, 'Mi Carnet');
            break;
          case 2:
            _showQRModal(carnet);
            break;
          case 3:
            _scrollToSection(_appointmentsKey, 'Citas y Consultas');
            break;
          case 4:
            _scrollToSection(_settingsKey, 'Ajustes');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.badge_outlined),
          selectedIcon: Icon(Icons.badge_rounded),
          label: 'Carnet',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_rounded),
          selectedIcon: Icon(Icons.qr_code_2_rounded),
          label: 'QR',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event_available_rounded),
          label: 'Citas',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Ajustes',
        ),
      ],
    );
  }

  void _showMobileMenu(BuildContext context, CarnetModel carnet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: const Icon(Icons.home_rounded, color: _uagroRed),
                    title: const Text('Inicio'),
                    onTap: () {
                      Navigator.pop(context);
                      _scrollToSection(_topKey, 'Inicio');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge_rounded, color: _uagroRed),
                    title: const Text('Mi Carnet'),
                    onTap: () {
                      Navigator.pop(context);
                      _scrollToSection(_credentialKey, 'Mi Carnet');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.school_rounded, color: _uagroRed),
                    title: const Text('Información Académica'),
                    onTap: () {
                      Navigator.pop(context);
                      _scrollToSection(_academicKey, 'Información Académica');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.health_and_safety_rounded,
                      color: _uagroRed,
                    ),
                    title: const Text('Información Médica'),
                    onTap: () {
                      Navigator.pop(context);
                      _scrollToSection(_medicalKey, 'Información Médica');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.qr_code_2_rounded,
                      color: _uagroRed,
                    ),
                    title: const Text('Ver código QR'),
                    onTap: () {
                      Navigator.pop(context);
                      _showQRModal(carnet);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.vaccines_rounded,
                      color: _uagroRed,
                    ),
                    title: const Text('Vacunas'),
                    onTap: () {
                      Navigator.pop(context);
                      _scrollToSection(_vaccinesKey, 'Vacunas');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.event_available_rounded,
                      color: _uagroRed,
                    ),
                    title: const Text('Citas y consultas'),
                    onTap: () {
                      Navigator.pop(context);
                      _scrollToSection(_appointmentsKey, 'Citas y Consultas');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.support_agent_rounded,
                      color: _uagroRed,
                    ),
                    title: const Text('Centro de Atención'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/atencion');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.auto_awesome_rounded,
                      color: _uagroRed,
                    ),
                    title: const Text('Promociones'),
                    onTap: () {
                      Navigator.pop(context);
                      _scrollToSection(_promotionsKey, 'Promociones');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.help_outline_rounded,
                      color: _uagroRed,
                    ),
                    title: const Text('Ayuda'),
                    onTap: () {
                      Navigator.pop(context);
                      _scrollToSection(_helpKey, 'Ayuda');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: _danger),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: _danger),
                    ),
                    onTap: () {
                      context.read<SessionProvider>().logout();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPhotoOptions(CarnetModel carnet) {
    final hasPhoto = (carnet.fotoUrl ?? '').trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_rounded,
                    color: _uagroRed,
                  ),
                  title: const Text('Cambiar foto'),
                  subtitle: const Text('JPG, PNG o WebP. Máximo 2 MB.'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndPreviewPhoto();
                  },
                ),
                if (hasPhoto)
                  ListTile(
                    leading: const Icon(
                      Icons.visibility_rounded,
                      color: _uagroBlue,
                    ),
                    title: const Text('Ver foto'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showPhotoViewer(carnet);
                    },
                  ),
                if (hasPhoto)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: _danger,
                    ),
                    title: const Text(
                      'Quitar foto',
                      style: TextStyle(color: _danger),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmRemovePhoto();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndPreviewPhoto() async {
    final input = html.FileUploadInputElement()
      ..accept = '.jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp';
    input.click();

    await input.onChange.first;
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      _showPhotoMessage('Selección cancelada.');
      return;
    }

    final mimeType = file.type;
    if (!_allowedPhotoMimeTypes.contains(mimeType)) {
      _showPhotoMessage(
        'Formato no permitido. Usa JPG, PNG o WebP.',
        isError: true,
      );
      return;
    }

    if (file.size > _maxPhotoBytes) {
      _showPhotoMessage('La fotografía no puede exceder 2 MB.', isError: true);
      return;
    }

    try {
      final bytes = await _readPhotoFileBytes(file);
      if (!mounted) return;
      _showPhotoPreview(bytes, file.name, mimeType);
    } catch (_) {
      _showPhotoMessage('No se pudo leer la fotografía.', isError: true);
    }
  }

  Future<Uint8List> _readPhotoFileBytes(html.File file) {
    final completer = Completer<Uint8List>();
    final reader = html.FileReader();

    reader.onLoad.first.then((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(Uint8List.view(result));
      } else if (result is Uint8List) {
        completer.complete(result);
      } else {
        completer.completeError(StateError('Formato de lectura no soportado'));
      }
    });

    reader.onError.first.then((_) {
      completer.completeError(
        reader.error ?? StateError('Error leyendo archivo'),
      );
    });

    reader.readAsArrayBuffer(file);
    return completer.future;
  }

  void _showPhotoPreview(Uint8List bytes, String fileName, String mimeType) {
    var uploading = false;

    showDialog(
      context: context,
      barrierDismissible: !uploading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Confirmar fotografía',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipOval(
                        child: Image.memory(
                          bytes,
                          width: 190,
                          height: 190,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'La foto aparecerá en tu credencial digital.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, height: 1.35),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: uploading
                                ? null
                                : () => Navigator.pop(dialogContext),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _uagroRed,
                            ),
                            onPressed: uploading
                                ? null
                                : () async {
                                    setDialogState(() => uploading = true);
                                    final session = this.context
                                        .read<SessionProvider>();
                                    final result = await session
                                        .uploadCarnetPhoto(
                                          bytes,
                                          fileName: fileName,
                                          mimeType: mimeType,
                                        );
                                    if (!mounted) return;
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }

                                    final success = result['success'] == true;
                                    final storagePending =
                                        result['storagePending'] == true;
                                    final message = success
                                        ? 'Fotografía actualizada correctamente'
                                        : storagePending
                                        ? 'Carga de fotografía en preparación'
                                        : (result['message'] ??
                                              'No se pudo subir la fotografía');
                                    _showPhotoMessage(
                                      message,
                                      isError: !success,
                                    );
                                  },
                            icon: uploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload_rounded),
                            label: Text(
                              uploading ? 'Subiendo...' : 'Confirmar',
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
      },
    );
  }

  void _showPhotoViewer(CarnetModel carnet) {
    final url = carnet.fotoUrl?.trim();
    if (url == null || url.isEmpty) return;
    final photoBytes = context.read<SessionProvider>().carnetPhotoBytes;
    final hasPhotoBytes = photoBytes != null && photoBytes.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: hasPhotoBytes
                      ? Image.memory(
                          photoBytes,
                          width: 320,
                          height: 320,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, _) {
                            debugPrint(
                              'No se pudo renderizar foto ampliada: $error',
                            );
                            return Image.network(
                              url,
                              width: 320,
                              height: 320,
                              fit: BoxFit.cover,
                              errorBuilder: (_, networkError, _) {
                                debugPrint(
                                  'No se pudo cargar foto ampliada desde URL: $networkError',
                                );
                                return const _PhotoViewerError();
                              },
                            );
                          },
                        )
                      : Image.network(
                          url,
                          width: 320,
                          height: 320,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, _) {
                            debugPrint(
                              'No se pudo cargar foto ampliada desde URL: $error',
                            );
                            return const _PhotoViewerError();
                          },
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  carnet.nombreCompleto,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _uagroRed),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemovePhoto() async {
    final session = context.read<SessionProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quitar fotografía'),
          content: const Text(
            'Tu carnet volverá a mostrar iniciales como respaldo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quitar foto'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    final result = await session.removeCarnetPhoto();
    if (!mounted) return;

    final success = result['success'] == true;
    _showPhotoMessage(
      success
          ? 'Fotografía retirada correctamente'
          : (result['message'] ?? 'No se pudo quitar la fotografía'),
      isError: !success,
    );
  }

  void _showPhotoMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? _danger : _success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showQRModal(CarnetModel carnet) {
    final link = _carnetLink(carnet);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Código QR del Carnet',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _line),
                    ),
                    child: QrImageView(
                      data: carnet.matricula,
                      size: 210,
                      backgroundColor: Colors.white,
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: _ink,
                      ),
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    carnet.nombreCompleto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Matrícula ${carnet.matricula}',
                    style: const TextStyle(
                      color: _uagroBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _StatusPill(label: 'ACTIVO'),
                  const SizedBox(height: 16),
                  const Text(
                    'Este QR identifica el carnet digital universitario SASU-UAGro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Validación institucional en desarrollo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: link));
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Enlace del carnet copiado al portapapeles',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: _success,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('Copiar enlace del carnet'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _uagroRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
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

  void _showNotificationsPanel() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SectionIcon(
                    Icons.notifications_none_rounded,
                    _uagroBlue,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Notificaciones',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No tienes notificaciones pendientes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, height: 1.35),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _uagroRed),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _copyCarnetLink(CarnetModel carnet) {
    Clipboard.setData(ClipboardData(text: _carnetLink(carnet)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Enlace del carnet copiado al portapapeles'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showBloodTypeDetails(CarnetModel carnet) {
    _showDetailDialog(
      icon: Icons.bloodtype_rounded,
      iconColor: _danger,
      title: 'Tipo de sangre',
      children: [
        _DetailLine(
          'Registro',
          _fallback(carnet.tipoSangre, empty: 'No registrado'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Verifica este dato con el área SASU si requiere corrección o actualización.',
          style: TextStyle(color: _muted, height: 1.35),
        ),
      ],
      primaryActionText: 'Ir a información médica',
      onPrimaryAction: () =>
          _scrollToSection(_medicalKey, 'Información Médica'),
    );
  }

  void _showAllergyDetails(CarnetModel carnet) {
    final allergies = _splitMedicalList(carnet.alergias);
    _showDetailDialog(
      icon: Icons.warning_amber_rounded,
      iconColor: _warning,
      title: 'Alergias',
      children: [
        if (allergies.isEmpty)
          const _SimpleNotice(
            icon: Icons.check_circle_outline_rounded,
            title: 'Sin alergias registradas',
            body: 'No hay alergias capturadas en el expediente actual.',
          )
        else
          ...allergies.map(
            (allergy) => _DetailLine('Alergia registrada', allergy),
          ),
      ],
      primaryActionText: 'Ir a información médica',
      onPrimaryAction: () =>
          _scrollToSection(_medicalKey, 'Información Médica'),
    );
  }

  void _showDonorDetails(CarnetModel carnet) {
    _showDetailDialog(
      icon: Icons.favorite_rounded,
      iconColor: const Color(0xFF52B788),
      title: 'Donante',
      children: [
        _DetailLine(
          'Estado',
          _fallback(carnet.donante, empty: 'No registrado'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Este dato es informativo y debe ser confirmado por personal médico en una emergencia.',
          style: TextStyle(color: _muted, height: 1.35),
        ),
      ],
      primaryActionText: 'Ir a información médica',
      onPrimaryAction: () =>
          _scrollToSection(_medicalKey, 'Información Médica'),
    );
  }

  void _showEmergencyDetails(CarnetModel carnet) {
    _showDetailDialog(
      icon: Icons.phone_rounded,
      iconColor: const Color(0xFF0B67C7),
      title: 'Contacto de emergencia',
      children: [
        _DetailLine(
          'Nombre',
          _fallback(carnet.emergenciaContacto, empty: 'No registrado'),
        ),
        _DetailLine(
          'Teléfono',
          _fallback(carnet.emergenciaTelefono, empty: 'Sin teléfono'),
        ),
      ],
      primaryActionText: 'Llamar',
      onPrimaryAction: () => _callEmergency(carnet.emergenciaTelefono),
      secondaryActionText: 'Ver sección',
      onSecondaryAction: () =>
          _scrollToSection(_emergencyKey, 'Contacto de Emergencia'),
    );
  }

  void _showDetailDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
    required String primaryActionText,
    required VoidCallback onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SectionIcon(icon, iconColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...children,
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (secondaryActionText != null &&
                          onSecondaryAction != null)
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            onSecondaryAction();
                          },
                          child: Text(secondaryActionText),
                        ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _uagroRed,
                        ),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          onPrimaryAction();
                        },
                        child: Text(primaryActionText),
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

  void _scrollToSection(GlobalKey key, String label) {
    setState(() => _activeSection = label);
    final targetContext = key.currentContext;
    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  List<String> _splitMedicalList(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return const [];

    final lower = clean.toLowerCase();
    if (lower == 'negadas' || lower == 'ninguna' || lower == 'no') {
      return const [];
    }

    return clean
        .split(RegExp(r'[,;\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _carnetLink(CarnetModel carnet) {
    final encoded = Uri.encodeComponent(carnet.matricula.trim());
    return 'https://app.carnetdigital.space/#/validacion?matricula=$encoded';
  }

  void _shareCarnet(CarnetModel carnet) {
    Clipboard.setData(
      ClipboardData(
        text:
            'Carnet Digital UAGro - ${carnet.nombreCompleto}\nMatrícula: ${carnet.matricula}',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Información del carnet copiada al portapapeles'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _callEmergency(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Teléfono de emergencia no registrado'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _danger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _goToCitas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CitasScreen()),
    );
  }

  Future<void> _openPromotion(PromocionSaludModel promo) async {
    context.read<SessionProvider>().marcarPromocionVista(promo.id);
    final link = promo.link;
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Esta promoción no tiene enlace disponible por ahora',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _uagroBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static String _firstName(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'estudiante';
    return clean.split(RegExp(r'\s+')).first;
  }

  static String _fallback(String value, {String empty = 'No registrado'}) {
    final clean = value.trim();
    if (clean.isEmpty) return empty;
    return clean;
  }
}

class _DigitalCredentialCard extends StatelessWidget {
  const _DigitalCredentialCard({
    required this.carnet,
    required this.compact,
    required this.photoBytes,
    required this.onQrTap,
    required this.onShareTap,
    required this.onPhotoTap,
  });

  final CarnetModel carnet;
  final bool compact;
  final Uint8List? photoBytes;
  final VoidCallback onQrTap;
  final VoidCallback onShareTap;
  final VoidCallback onPhotoTap;

  static const Color _uagroRed = _CarnetScreenNewState._uagroRed;
  static const Color _uagroBlue = _CarnetScreenNewState._uagroBlue;

  @override
  Widget build(BuildContext context) {
    final nameSize = compact ? 18.0 : 27.0;
    final cardMinHeight = compact ? 360.0 : 350.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      constraints: BoxConstraints(minHeight: cardMinHeight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_uagroRed, Color(0xFF2B092B), _uagroBlue],
          stops: [0, 0.46, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: _uagroBlue.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -36,
            left: -30,
            child: Opacity(
              opacity: 0.07,
              child: Image.asset(
                'assets/uagro_logo.png',
                width: compact ? 160 : 210,
              ),
            ),
          ),
          Positioned(
            right: -30,
            bottom: -10,
            child: Transform.rotate(
              angle: -0.72,
              child: Container(
                width: compact ? 180 : 240,
                height: 16,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            right: -16,
            bottom: 26,
            child: Transform.rotate(
              angle: -0.72,
              child: Container(
                width: compact ? 180 : 240,
                height: 10,
                color: _uagroRed.withValues(alpha: 0.45),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 20 : 34),
            child: compact
                ? _buildCompactCredential(context, nameSize)
                : _buildWideCredential(context, nameSize),
          ),
        ],
      ),
    );
  }

  Widget _buildWideCredential(BuildContext context, double nameSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StudentPhoto(
              name: carnet.nombreCompleto,
              fotoUrl: carnet.fotoUrl,
              photoBytes: photoBytes,
              size: 128,
              onTap: onPhotoTap,
            ),
            const SizedBox(width: 26),
            Expanded(child: _buildIdentityBlock(nameSize, alignCenter: false)),
            const SizedBox(width: 16),
            Column(
              children: [
                Image.asset('assets/uagro_logo.png', width: 78, height: 78),
                const Text(
                  'UAGro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _BarcodeBlock(code: '${carnet.matricula}-UAGRO-2026'),
            ),
            const SizedBox(width: 18),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Tooltip(
                message: 'Abrir código QR',
                child: InkWell(
                  onTap: onQrTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(data: carnet.matricula, size: 82),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactCredential(BuildContext context, double nameSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Image.asset('assets/uagro_logo.png', width: 56, height: 56),
        ),
        _StudentPhoto(
          name: carnet.nombreCompleto,
          fotoUrl: carnet.fotoUrl,
          photoBytes: photoBytes,
          size: 108,
          onTap: onPhotoTap,
        ),
        const SizedBox(height: 14),
        _buildIdentityBlock(nameSize, alignCenter: true),
        const SizedBox(height: 16),
        _BarcodeBlock(code: '${carnet.matricula}-UAGRO-2026', compact: true),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CredentialAction(
              icon: Icons.qr_code_2_rounded,
              label: 'QR',
              onTap: onQrTap,
            ),
            const SizedBox(width: 10),
            _CredentialAction(
              icon: Icons.ios_share_rounded,
              label: 'Compartir',
              onTap: onShareTap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdentityBlock(double nameSize, {required bool alignCenter}) {
    return Column(
      crossAxisAlignment: alignCenter
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          carnet.nombreCompleto.toUpperCase(),
          textAlign: alignCenter ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white,
            fontSize: nameSize,
            fontWeight: FontWeight.w900,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: alignCenter ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _InlineMeta(label: 'Matrícula', value: carnet.matricula),
            const _StatusPill(label: 'ACTIVO'),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          carnet.programa.isEmpty ? 'Programa académico' : carnet.programa,
          textAlign: alignCenter ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: alignCenter ? 14 : 17,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${carnet.categoria.isEmpty ? "Estudiante" : carnet.categoria}  |  ${carnet.unidadMedica.isEmpty ? "Campus UAGro" : carnet.unidadMedica}',
          textAlign: alignCenter ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.86),
            fontSize: alignCenter ? 13 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StudentPhoto extends StatelessWidget {
  const _StudentPhoto({
    required this.name,
    required this.size,
    required this.onTap,
    this.fotoUrl,
    this.photoBytes,
    this.labelColor,
  });

  final String name;
  final double size;
  final String? fotoUrl;
  final Uint8List? photoBytes;
  final VoidCallback onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final cleanFotoUrl = fotoUrl?.trim() ?? '';
    final hasPhoto = cleanFotoUrl.isNotEmpty;
    final hasPhotoBytes = photoBytes != null && photoBytes!.isNotEmpty;

    return Tooltip(
      message: hasPhoto ? 'Cambiar foto' : 'Foto no registrada',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: size,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasPhotoBytes
                        ? Image.memory(
                            photoBytes!,
                            fit: BoxFit.cover,
                            width: size,
                            height: size,
                            errorBuilder: (_, error, _) {
                              debugPrint(
                                'No se pudo renderizar la foto del carnet: $error',
                              );
                              return hasPhoto
                                  ? _NetworkStudentPhoto(
                                      url: cleanFotoUrl,
                                      size: size,
                                    )
                                  : _PhotoLoadError(size: size);
                            },
                          )
                        : hasPhoto
                        ? _NetworkStudentPhoto(url: cleanFotoUrl, size: size)
                        : _InitialsAvatar(
                            initials: initials.isEmpty ? 'U' : initials,
                            size: size,
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasPhoto ? 'Cambiar foto' : 'Foto no registrada',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor ?? Colors.white.withValues(alpha: 0.82),
                    fontSize: size < 100 ? 9 : 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: const Color(0xFFEFF6FF),
      child: Text(
        initials,
        style: TextStyle(
          color: _CarnetScreenNewState._uagroBlue,
          fontSize: size * 0.28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NetworkStudentPhoto extends StatelessWidget {
  const _NetworkStudentPhoto({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (_, error, _) {
        debugPrint('No se pudo cargar la foto del carnet desde URL: $error');
        return _PhotoLoadError(size: size);
      },
    );
  }
}

class _PhotoLoadError extends StatelessWidget {
  const _PhotoLoadError({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final compact = size < 100;
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFFFF1F2),
      padding: EdgeInsets.all(compact ? 8 : 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: _CarnetScreenNewState._danger,
            size: compact ? 20 : 26,
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            compact ? 'Foto no cargó' : 'No se pudo cargar la foto',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _CarnetScreenNewState._danger,
              fontSize: compact ? 8 : 10,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoViewerError extends StatelessWidget {
  const _PhotoViewerError();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      color: const Color(0xFFFFF1F2),
      padding: const EdgeInsets.all(24),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: _CarnetScreenNewState._danger,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            'No se pudo cargar la foto',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _CarnetScreenNewState._danger,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _CarnetScreenNewState._success,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: _CarnetScreenNewState._success.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BarcodeBlock extends StatelessWidget {
  const _BarcodeBlock({required this.code, this.compact = false});

  final String code;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 66 : 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 28,
        vertical: compact ? 8 : 12,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: CustomPaint(
              painter: _BarcodePainter(code.hashCode),
              child: const SizedBox(width: double.infinity),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            code,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _CarnetScreenNewState._ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  _BarcodePainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final random = math.Random(seed);
    double x = 0;
    while (x < size.width) {
      final width = 1.0 + random.nextInt(4).toDouble();
      final gap = 1.0 + random.nextInt(3).toDouble();
      canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
      x += width + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) =>
      oldDelegate.seed != seed;
}

class _CredentialAction extends StatelessWidget {
  const _CredentialAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CriticalInfo {
  const _CriticalInfo(
    this.icon,
    this.color,
    this.label,
    this.value,
    this.action,
    this.onTap,
  );

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String action;
  final VoidCallback onTap;
}

class _CriticalCard extends StatelessWidget {
  const _CriticalCard({required this.info});

  final _CriticalInfo info;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: info.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _CarnetScreenNewState._line),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(info.icon, color: info.color, size: 34),
              const SizedBox(height: 8),
              Text(
                info.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _CarnetScreenNewState._muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                info.value,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _CarnetScreenNewState._ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                info.action,
                style: const TextStyle(
                  color: Color(0xFF0B67C7),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CriticalRow extends StatelessWidget {
  const _CriticalRow({required this.info});

  final _CriticalInfo info;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: info.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _CarnetScreenNewState._line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(info.icon, color: info.color, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _CarnetScreenNewState._ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      info.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _CarnetScreenNewState._muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _CarnetScreenNewState._muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              color: _CarnetScreenNewState._uagroRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _CarnetScreenNewState._muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: _CarnetScreenNewState._ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
    this.actionText,
    this.onAction,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final bool initiallyExpanded;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          leading: _SectionIcon(icon, iconColor),
          title: Text(
            title,
            style: const TextStyle(
              color: _CarnetScreenNewState._ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          trailing: actionText == null
              ? null
              : TextButton(onPressed: onAction, child: Text(actionText!)),
          children: children,
        ),
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _CarnetScreenNewState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon(this.icon, this.color);

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

class _KeyValueGrid extends StatelessWidget {
  const _KeyValueGrid({required this.items, required this.compact});

  final List<_InfoPair> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 1 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 28,
        mainAxisExtent: 50,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.label,
              style: const TextStyle(
                color: _CarnetScreenNewState._muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _CarnetScreenNewState._ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoPair {
  const _InfoPair(this.label, this.value);

  final String label;
  final String value;
}

class _MedicalStatusGrid extends StatelessWidget {
  const _MedicalStatusGrid({required this.carnet, required this.compact});

  final CarnetModel carnet;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final disability = carnet.tieneDiscapacidad
        ? '${carnet.discapacidad}${carnet.tipoDiscapacidad.isNotEmpty ? " - ${carnet.tipoDiscapacidad}" : ""}'
        : 'No';
    final items = [
      _MedicalStatus(
        Icons.check_circle_outline_rounded,
        const Color(0xFF22C55E),
        'Enfermedades Crónicas',
        carnet.tieneEnfermedadCronica
            ? carnet.enfermedadCronica
            : 'No registradas',
        false,
      ),
      _MedicalStatus(
        Icons.check_circle_outline_rounded,
        const Color(0xFF22C55E),
        'Discapacidad',
        disability,
        false,
      ),
      _MedicalStatus(
        Icons.warning_amber_rounded,
        const Color(0xFFEF4444),
        'Alergias',
        carnet.tieneAlergias ? carnet.alergias : 'No registradas',
        carnet.tieneAlergias,
      ),
      _MedicalStatus(
        Icons.bloodtype_rounded,
        const Color(0xFFEF4444),
        'Tipo de Sangre',
        carnet.tipoSangre.isEmpty ? 'No registrado' : carnet.tipoSangre,
        false,
      ),
    ];

    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: item.alert
                    ? const Color(0xFFFFF1F2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: item.alert
                    ? Border.all(color: const Color(0xFFFECACA))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Icon(item.icon, color: item.color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: _CarnetScreenNewState._muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          maxLines: compact ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _CarnetScreenNewState._ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MedicalStatus {
  const _MedicalStatus(
    this.icon,
    this.color,
    this.label,
    this.value,
    this.alert,
  );

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool alert;
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({
    required this.name,
    required this.phone,
    required this.onCall,
  });

  final String name;
  final String phone;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EmergencyField(
            icon: Icons.person_rounded,
            label: 'Contacto',
            value: name,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _EmergencyField(
            icon: Icons.phone_rounded,
            label: 'Teléfono',
            value: phone,
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF0B67C7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onCall,
          icon: const Icon(Icons.call_rounded),
          tooltip: 'Llamar',
        ),
      ],
    );
  }
}

class _EmergencyField extends StatelessWidget {
  const _EmergencyField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _CarnetScreenNewState._muted,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _CarnetScreenNewState._ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SimpleNotice extends StatelessWidget {
  const _SimpleNotice({
    required this.icon,
    required this.title,
    required this.body,
    this.tinted = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tinted ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tinted ? const Color(0xFF93C5FD) : _CarnetScreenNewState._line,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0B67C7), size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _CarnetScreenNewState._uagroBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(color: _CarnetScreenNewState._muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionTile extends StatelessWidget {
  const _PromotionTile({required this.promocion, required this.onTap});

  final PromocionSaludModel promocion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: promocion.urgente
              ? const Color(0xFFFFF1F2)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: promocion.urgente
                ? const Color(0xFFFECACA)
                : _CarnetScreenNewState._line,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: Color(0xFF0B67C7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promocion.tituloDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _CarnetScreenNewState._ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promocion.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _CarnetScreenNewState._muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _CarnetScreenNewState._muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.notifications_none_rounded),
      tooltip: 'Notificaciones',
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _SidebarButton extends StatefulWidget {
  const _SidebarButton({
    required this.item,
    required this.selected,
    this.danger = false,
  });

  final _NavItem item;
  final bool selected;
  final bool danger;

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.item.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.selected
                ? _CarnetScreenNewState._uagroRed
                : active
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.item.icon, color: Colors.white, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustItem {
  const _TrustItem(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}
