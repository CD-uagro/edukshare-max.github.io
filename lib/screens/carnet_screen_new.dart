import 'dart:math' as math;

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

  late final AnimationController _introController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  int _mobileTab = 0;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _introController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic));
    _introController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadPromociones();
    });
  }

  @override
  void dispose() {
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
            body: Center(
              child: CircularProgressIndicator(color: _uagroRed),
            ),
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
              bottomNavigationBar: isDesktop ? null : _buildBottomNav(context, carnet),
              body: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: isDesktop
                      ? _buildDesktopShell(context, session, carnet)
                      : _buildMobileTabletShell(context, session, carnet, isTablet),
                ),
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildMobileTopBar(BuildContext context, CarnetModel carnet) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: _ink,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _showMobileMenu(context, carnet),
        tooltip: 'Menu',
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
        _NotificationButton(onPressed: () => _showQRModal(carnet)),
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
                              child: _buildPhonePreview(context, session, carnet),
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
      _NavItem(Icons.home_rounded, 'Inicio', () {}),
      _NavItem(Icons.badge_rounded, 'Mi Carnet', () {}),
      _NavItem(Icons.school_rounded, 'Informacion Academica', () {}),
      _NavItem(Icons.health_and_safety_rounded, 'Informacion Medica', () {}),
      _NavItem(Icons.vaccines_rounded, 'Vacunas', () => Navigator.pushNamed(context, '/vacunas')),
      _NavItem(Icons.event_available_rounded, 'Citas y Consultas', () => _goToCitas(context)),
      _NavItem(Icons.auto_awesome_rounded, 'Promociones', () {}),
      _NavItem(Icons.settings_rounded, 'Ajustes', () {}),
      _NavItem(Icons.help_outline_rounded, 'Ayuda', () {}),
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
                      Image.asset('assets/uagro_logo.png', width: 52, height: 52),
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
                              'Universidad Autonoma\nde Guerrero',
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
                    final selected = entry.key == 0;
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
                    item: _NavItem(
                      Icons.logout_rounded,
                      'Cerrar sesion',
                      () {
                        context.read<SessionProvider>().logout();
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                    ),
                    selected: false,
                    danger: false,
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    '"Universidad de Calidad\ncon Inclusion Social"',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'SASU - Sistema de Atencion\nen Salud Universitaria',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Version 2.0.0',
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
        border: Border(bottom: BorderSide(color: _line.withValues(alpha: 0.85))),
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
            'Ultima actualizacion:\n09/06/2026 04:18 p. m.',
            textAlign: TextAlign.right,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.35),
          ),
          const SizedBox(width: 18),
          _NotificationButton(onPressed: () => _showQRModal(carnet)),
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
        _DigitalCredentialCard(
          carnet: carnet,
          compact: compact,
          onQrTap: () => _showQRModal(carnet),
          onShareTap: () => _shareCarnet(carnet),
        ),
        const SizedBox(height: 14),
        _buildCriticalMedicalSection(carnet, compact),
        const SizedBox(height: 14),
        _InfoPanel(
          icon: Icons.school_rounded,
          iconColor: const Color(0xFF0B67C7),
          title: 'Informacion Academica',
          actionText: 'Ver mas',
          initiallyExpanded: !compact,
          children: [
            _KeyValueGrid(
              compact: compact,
              items: [
                _InfoPair('Programa', _fallback(carnet.programa)),
                _InfoPair('Semestre', '2 Semestre'),
                _InfoPair('Categoria', _fallback(carnet.categoria)),
                _InfoPair('No. Afiliacion', _fallback(carnet.numeroAfiliacion, empty: '0000')),
                _InfoPair('Seguro Universitario', _fallback(carnet.usoSeguroUniversitario, empty: 'No')),
                _InfoPair('Donante', _fallback(carnet.donante, empty: 'No')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoPanel(
          icon: Icons.medical_services_rounded,
          iconColor: _danger,
          title: 'Informacion Medica',
          actionText: 'Ver mas',
          initiallyExpanded: !compact,
          children: [
            _MedicalStatusGrid(carnet: carnet, compact: compact),
          ],
        ),
        const SizedBox(height: 14),
        _InfoPanel(
          icon: Icons.phone_in_talk_rounded,
          iconColor: const Color(0xFF0B67C7),
          title: 'Contacto de Emergencia',
          actionText: 'Ver mas',
          initiallyExpanded: true,
          children: [
            _EmergencyContactCard(
              name: _fallback(carnet.emergenciaContacto, empty: 'No registrado'),
              phone: _fallback(carnet.emergenciaTelefono, empty: 'Sin telefono'),
              onCall: () => _callEmergency(carnet.emergenciaTelefono),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoPanel(
          icon: Icons.vaccines_rounded,
          iconColor: const Color(0xFF16A34A),
          title: 'Vacunas',
          actionText: 'Abrir',
          initiallyExpanded: compact,
          onAction: () => Navigator.pushNamed(context, '/vacunas'),
          children: const [
            _SimpleNotice(
              icon: Icons.verified_user_rounded,
              title: 'Expediente de vacunacion',
              body: 'Consulta y actualiza tus registros desde el modulo de vacunas.',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoPanel(
          icon: Icons.event_available_rounded,
          iconColor: const Color(0xFF0B67C7),
          title: 'Citas y Consultas',
          actionText: 'Abrir',
          initiallyExpanded: compact,
          onAction: () => _goToCitas(context),
          children: const [
            _SimpleNotice(
              icon: Icons.calendar_month_rounded,
              title: 'Atencion universitaria',
              body: 'Revisa tus citas medicas y el seguimiento de consultas SASU.',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildPromotionsPanel(session.promociones),
        const SizedBox(height: 20),
        if (!compact) _buildTrustFooter(),
      ],
    );
  }

  Widget _buildCriticalMedicalSection(CarnetModel carnet, bool compact) {
    final cards = [
      _CriticalInfo(
        Icons.bloodtype_rounded,
        _danger,
        'Tipo de Sangre',
        _fallback(carnet.tipoSangre, empty: 'No registrado'),
        'Ver detalles',
      ),
      _CriticalInfo(
        Icons.warning_amber_rounded,
        _warning,
        'Alergias',
        carnet.tieneAlergias ? '1 registrada' : 'Sin registro',
        'Ver detalles',
      ),
      _CriticalInfo(
        Icons.favorite_rounded,
        const Color(0xFF52B788),
        'Donante',
        _fallback(carnet.donante, empty: 'No'),
        'Ver detalles',
      ),
      _CriticalInfo(
        Icons.phone_rounded,
        const Color(0xFF0B67C7),
        'Contacto de Emergencia',
        _fallback(carnet.emergenciaContacto, empty: 'No registrado'),
        'Ver detalles',
      ),
    ];

    return _SurfacePanel(
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionIcon(Icons.health_and_safety_rounded, Color(0xFF0B67C7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Informacion medica critica',
                  style: TextStyle(
                    color: _ink,
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.info_outline_rounded, color: _muted.withValues(alpha: 0.8), size: 18),
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
              itemBuilder: (context, index) => _CriticalCard(info: cards[index]),
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

  Widget _buildPhonePreview(
    BuildContext context,
    SessionProvider session,
    CarnetModel carnet,
  ) {
    return Column(
      children: [
        const Text(
          'Vista movil',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              color: _background,
              child: Column(
                children: [
                  Container(
                    height: 52,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_rounded, size: 20),
                        const SizedBox(width: 14),
                        Image.asset('assets/uagro_logo.png', width: 28, height: 28),
                        const SizedBox(width: 6),
                        const Text('UAGro', style: TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        const Icon(Icons.notifications_none_rounded, size: 20),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        _DigitalCredentialCard(
                          carnet: carnet,
                          compact: true,
                          preview: true,
                          onQrTap: () => _showQRModal(carnet),
                          onShareTap: () => _shareCarnet(carnet),
                        ),
                        const SizedBox(height: 12),
                        _buildCriticalMedicalSection(carnet, true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustFooter() {
    final items = [
      _TrustItem(Icons.shield_rounded, 'Seguro y confiable', 'Datos protegidos por controles institucionales.'),
      _TrustItem(Icons.sync_rounded, 'Siempre actualizado', 'La informacion se sincroniza con sistemas SASU.'),
      _TrustItem(Icons.qr_code_2_rounded, 'Codigo QR', 'Comparte tu carnet cuando lo necesites.'),
      _TrustItem(Icons.help_outline_rounded, 'Necesitas ayuda?', 'Contactanos para soporte universitario.'),
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
        if (index == 2) _showQRModal(carnet);
        if (index == 3) _goToCitas(context);
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
        NavigationDestination(icon: Icon(Icons.badge_outlined), selectedIcon: Icon(Icons.badge_rounded), label: 'Carnet'),
        NavigationDestination(icon: Icon(Icons.qr_code_rounded), selectedIcon: Icon(Icons.qr_code_2_rounded), label: 'QR'),
        NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event_available_rounded), label: 'Citas'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Ajustes'),
      ],
    );
  }

  void _showMobileMenu(BuildContext context, CarnetModel carnet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
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
                leading: const Icon(Icons.qr_code_2_rounded, color: _uagroRed),
                title: const Text('Ver codigo QR'),
                onTap: () {
                  Navigator.pop(context);
                  _showQRModal(carnet);
                },
              ),
              ListTile(
                leading: const Icon(Icons.vaccines_rounded, color: _uagroRed),
                title: const Text('Vacunas'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/vacunas');
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_available_rounded, color: _uagroRed),
                title: const Text('Citas y consultas'),
                onTap: () {
                  Navigator.pop(context);
                  _goToCitas(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: _danger),
                title: const Text('Cerrar sesion', style: TextStyle(color: _danger)),
                onTap: () {
                  context.read<SessionProvider>().logout();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQRModal(CarnetModel carnet) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Codigo QR del Carnet',
                  style: TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w800),
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
                    size: 190,
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
                  carnet.matricula,
                  style: const TextStyle(color: _uagroBlue, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _uagroRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  ),
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

  void _shareCarnet(CarnetModel carnet) {
    Clipboard.setData(
      ClipboardData(
        text: 'Carnet Digital UAGro - ${carnet.nombreCompleto}\nMatricula: ${carnet.matricula}',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Informacion del carnet copiada al portapapeles'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _callEmergency(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _goToCitas(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CitasScreen()));
  }

  Future<void> _openPromotion(PromocionSaludModel promo) async {
    context.read<SessionProvider>().marcarPromocionVista(promo.id);
    final link = promo.link;
    if (link == null || link.isEmpty) return;
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
    required this.onQrTap,
    required this.onShareTap,
    this.preview = false,
  });

  final CarnetModel carnet;
  final bool compact;
  final bool preview;
  final VoidCallback onQrTap;
  final VoidCallback onShareTap;

  static const Color _uagroRed = _CarnetScreenNewState._uagroRed;
  static const Color _uagroBlue = _CarnetScreenNewState._uagroBlue;

  @override
  Widget build(BuildContext context) {
    final nameSize = preview ? 16.0 : (compact ? 18.0 : 27.0);
    final cardMinHeight = preview ? 310.0 : (compact ? 360.0 : 350.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
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
                child: Image.asset('assets/uagro_logo.png', width: compact ? 160 : 210),
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
              padding: EdgeInsets.all(preview ? 16 : (compact ? 20 : 34)),
              child: compact
                  ? _buildCompactCredential(context, nameSize)
                  : _buildWideCredential(context, nameSize),
            ),
          ],
        ),
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
            _StudentPhoto(name: carnet.nombreCompleto, size: 128),
            const SizedBox(width: 26),
            Expanded(child: _buildIdentityBlock(nameSize, alignCenter: false)),
            const SizedBox(width: 16),
            Column(
              children: [
                Image.asset('assets/uagro_logo.png', width: 78, height: 78),
                const Text(
                  'UAGro',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _BarcodeBlock(code: '${carnet.matricula}-UAGRO-2026')),
            const SizedBox(width: 18),
            InkWell(
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
          child: Image.asset('assets/uagro_logo.png', width: preview ? 46 : 56, height: preview ? 46 : 56),
        ),
        _StudentPhoto(name: carnet.nombreCompleto, size: preview ? 88 : 108),
        const SizedBox(height: 14),
        _buildIdentityBlock(nameSize, alignCenter: true),
        const SizedBox(height: 16),
        _BarcodeBlock(code: '${carnet.matricula}-UAGRO-2026', compact: true),
        if (!preview) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CredentialAction(icon: Icons.qr_code_2_rounded, label: 'QR', onTap: onQrTap),
              const SizedBox(width: 10),
              _CredentialAction(icon: Icons.ios_share_rounded, label: 'Compartir', onTap: onShareTap),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildIdentityBlock(double nameSize, {required bool alignCenter}) {
    return Column(
      crossAxisAlignment: alignCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
            _InlineMeta(label: 'Matricula', value: carnet.matricula),
            const _StatusPill(label: 'ACTIVO'),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          carnet.programa.isEmpty ? 'Programa academico' : carnet.programa,
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
  const _StudentPhoto({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
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
      child: CircleAvatar(
        backgroundColor: const Color(0xFFEFF6FF),
        child: Text(
          initials.isEmpty ? 'U' : initials,
          style: TextStyle(
            color: _CarnetScreenNewState._uagroBlue,
            fontSize: size * 0.28,
            fontWeight: FontWeight.w900,
          ),
        ),
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
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
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28, vertical: compact ? 8 : 12),
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
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) => oldDelegate.seed != seed;
}

class _CredentialAction extends StatelessWidget {
  const _CredentialAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _CriticalInfo {
  const _CriticalInfo(this.icon, this.color, this.label, this.value, this.action);

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String action;
}

class _CriticalCard extends StatelessWidget {
  const _CriticalCard({required this.info});

  final _CriticalInfo info;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {},
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
              style: const TextStyle(color: _CarnetScreenNewState._muted, fontSize: 12),
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
    );
  }
}

class _CriticalRow extends StatelessWidget {
  const _CriticalRow({required this.info});

  final _CriticalInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  style: const TextStyle(color: _CarnetScreenNewState._muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _CarnetScreenNewState._muted),
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
              : TextButton(
                  onPressed: onAction,
                  child: Text(actionText!),
                ),
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
            Text(item.label, style: const TextStyle(color: _CarnetScreenNewState._muted, fontSize: 12)),
            const SizedBox(height: 3),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _CarnetScreenNewState._ink, fontWeight: FontWeight.w800),
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
        'Enfermedades Cronicas',
        carnet.tieneEnfermedadCronica ? carnet.enfermedadCronica : 'No registradas',
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
                color: item.alert ? const Color(0xFFFFF1F2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: item.alert ? Border.all(color: const Color(0xFFFECACA)) : null,
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
                          style: const TextStyle(color: _CarnetScreenNewState._muted, fontSize: 12),
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
  const _MedicalStatus(this.icon, this.color, this.label, this.value, this.alert);

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
        Expanded(child: _EmergencyField(icon: Icons.person_rounded, label: 'Contacto', value: name)),
        const SizedBox(width: 16),
        Expanded(child: _EmergencyField(icon: Icons.phone_rounded, label: 'Telefono', value: phone)),
        const SizedBox(width: 12),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF0B67C7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  const _EmergencyField({required this.icon, required this.label, required this.value});

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
              Text(label, style: const TextStyle(color: _CarnetScreenNewState._muted, fontSize: 12)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _CarnetScreenNewState._ink, fontWeight: FontWeight.w800),
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
        border: Border.all(color: tinted ? const Color(0xFF93C5FD) : _CarnetScreenNewState._line),
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
                Text(body, style: const TextStyle(color: _CarnetScreenNewState._muted)),
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
          color: promocion.urgente ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: promocion.urgente ? const Color(0xFFFECACA) : _CarnetScreenNewState._line,
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
              child: const Icon(Icons.campaign_rounded, color: Color(0xFF0B67C7)),
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
                    style: const TextStyle(color: _CarnetScreenNewState._muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _CarnetScreenNewState._muted),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.shield_outlined),
          tooltip: 'Verificacion',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        Positioned(
          top: 3,
          right: 3,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
            child: const Center(
              child: Text(
                '2',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ],
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
  const _SidebarButton({required this.item, required this.selected, this.danger = false});

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
