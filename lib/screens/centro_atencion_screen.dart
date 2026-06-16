import 'package:carnet_digital_uagro/models/carnet_model.dart';
import 'package:carnet_digital_uagro/models/ticket_model.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const Color _uagroRed = Color(0xFF7A0019);
const Color _uagroBlue = Color(0xFF0D2A5C);
const Color _accentBlue = Color(0xFF2563EB);
const Color _success = Color(0xFF16A34A);
const Color _warning = Color(0xFFF59E0B);
const Color _danger = Color(0xFFEF4444);
const Color _background = Color(0xFFF8FAFC);
const Color _surface = Color(0xFFFFFFFF);
const Color _ink = Color(0xFF0F172A);
const Color _muted = Color(0xFF64748B);
const Color _line = Color(0xFFE2E8F0);

const Map<String, String> _categoryLabels = {
  'psicologia': 'Psicología',
  'medicina': 'Medicina',
  'nutricion': 'Nutrición',
  'vacunacion': 'Vacunación',
  'promocion_salud': 'Promoción de salud',
  'soporte_carnet': 'Soporte de carnet',
  'administrativo': 'Administrativo',
  'otro': 'Otro',
};

const Map<String, String> _priorityLabels = {
  'baja': 'Baja',
  'media': 'Media',
  'alta': 'Alta',
  'urgente': 'Urgente',
};

class CentroAtencionScreen extends StatefulWidget {
  const CentroAtencionScreen({super.key});

  @override
  State<CentroAtencionScreen> createState() => _CentroAtencionScreenState();
}

class _CentroAtencionScreenState extends State<CentroAtencionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _searchController = TextEditingController();

  String _categoria = 'soporte_carnet';
  String _prioridad = 'media';
  String _statusFilter = 'todos';
  String? _selectedRequestId;
  bool _initialTicketsLoadRequested = false;
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTicketsIfReady());
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Consumer<SessionProvider>(
        builder: (context, session, child) {
          if (session.isAuthenticated && session.carnet != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _loadTicketsIfReady(),
            );
          }

          if (session.isLoading ||
              (session.isAuthenticated && session.carnet == null)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!session.isAuthenticated || session.carnet == null) {
            return _buildSessionRequired(context);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1040;
              return Row(
                children: [
                  if (isWide) _buildSideBar(context, session),
                  Expanded(child: _buildPortal(context, session, isWide)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _loadTicketsIfReady() {
    if (!mounted || _initialTicketsLoadRequested) return;

    final session = context.read<SessionProvider>();
    if (!session.isAuthenticated || session.carnet == null) return;

    _initialTicketsLoadRequested = true;
    session.loadTickets(force: true).then((_) {
      if (mounted) setState(() => _lastUpdated = DateTime.now());
    });
  }

  Future<void> _refreshTickets(SessionProvider session) async {
    await session.loadTickets(force: true);
    if (mounted) setState(() => _lastUpdated = DateTime.now());
  }

  Widget _buildSessionRequired(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(28),
        decoration: _softCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 64, color: _uagroBlue),
            const SizedBox(height: 16),
            const Text(
              'Sesión requerida',
              style: TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión para consultar tu seguimiento universitario.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.4),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/login'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Ir a login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBar(BuildContext context, SessionProvider session) {
    final carnet = session.carnet;
    final initials = _studentInitials(carnet?.nombreCompleto ?? 'Alumno');

    return Container(
      width: 270,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071B3F), _uagroBlue, Color(0xFF03152F)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'SASU',
                        style: TextStyle(
                          color: _uagroRed,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UAGro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Universidad Autónoma\nde Guerrero',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              _SideNavItem(
                icon: Icons.home_rounded,
                label: 'Inicio',
                onTap: () => Navigator.of(context).pushNamed('/carnet'),
              ),
              _SideNavItem(
                icon: Icons.badge_rounded,
                label: 'Mi Carnet',
                onTap: () => Navigator.of(context).pushNamed('/carnet'),
              ),
              _SideNavItem(
                icon: Icons.school_rounded,
                label: 'Información académica',
                onTap: () => Navigator.of(context).pushNamed('/carnet'),
              ),
              _SideNavItem(
                icon: Icons.medical_information_rounded,
                label: 'Información médica',
                onTap: () => Navigator.of(context).pushNamed('/carnet'),
              ),
              _SideNavItem(
                icon: Icons.vaccines_rounded,
                label: 'Vacunas',
                onTap: () => Navigator.of(context).pushNamed('/vacunas'),
              ),
              _SideNavItem(
                icon: Icons.support_agent_rounded,
                label: 'Centro de Atención',
                active: true,
                onTap: () {},
              ),
              _SideNavItem(
                icon: Icons.campaign_rounded,
                label: 'Promociones',
                onTap: () => Navigator.of(context).pushNamed('/carnet'),
              ),
              const Spacer(),
              const Divider(color: Colors.white24),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF2563EB)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carnet?.nombreCompleto ?? 'Alumno UAGro',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Matrícula: ${carnet?.matricula ?? '--'}',
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
              const SizedBox(height: 14),
              Text(
                'Última conexión:\n${_formatDate(_lastUpdated)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortal(
    BuildContext context,
    SessionProvider session,
    bool isWide,
  ) {
    final tickets = session.tickets;
    final filteredTickets = _filteredTickets(tickets);
    final selectedTicket = _selectedTicket(filteredTickets, tickets);
    final carnet = session.carnet;

    return RefreshIndicator(
      onRefresh: () => _refreshTickets(session),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          isWide ? 34 : 18,
          isWide ? 28 : 18,
          isWide ? 34 : 18,
          26,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(context, session, isWide),
                const SizedBox(height: 24),
                _buildHero(context, session, isWide),
                const SizedBox(height: 24),
                _buildKpiGrid(tickets),
                const SizedBox(height: 24),
                if (session.ticketsError != null) ...[
                  _buildErrorNotice(session.ticketsError!),
                  const SizedBox(height: 18),
                ],
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 350,
                        child: Column(
                          children: [
                            _buildRequestsPanel(
                              context,
                              session,
                              filteredTickets,
                              selectedTicket,
                              isWide: true,
                            ),
                            const SizedBox(height: 18),
                            _buildImmediateHelpCard(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _TicketDetailPanel(
                          ticket: selectedTicket,
                          token: session.token ?? '',
                          studentName: carnet?.nombreCompleto ?? 'Alumno',
                          studentMatricula: carnet?.matricula ?? '',
                          studentCampus: _studentCampusLabel(carnet),
                          studentUnit: _studentUnitLabel(carnet),
                        ),
                      ),
                    ],
                  )
                else ...[
                  _buildRequestsPanel(
                    context,
                    session,
                    filteredTickets,
                    selectedTicket,
                    isWide: false,
                  ),
                  const SizedBox(height: 18),
                  _buildImmediateHelpCard(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    SessionProvider session,
    bool isWide,
  ) {
    final updatedLabel = _formatDate(_lastUpdated);
    final unreadTotal = session.tickets.where(_hasUnreadSignal).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isWide) ...[
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
        ],
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AttentionTitle(),
              SizedBox(height: 8),
              Text(
                'Estamos para apoyarte.\nConsulta, seguimiento y comunicación con los servicios universitarios.',
                style: TextStyle(color: _muted, fontSize: 15, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        _NotificationButton(count: unreadTotal),
        const SizedBox(width: 12),
        if (isWide)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Última actualización:',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                updatedLabel,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        const SizedBox(width: 12),
        IconButton.filled(
          tooltip: 'Actualizar',
          onPressed: session.isTicketsLoading
              ? null
              : () => _refreshTickets(session),
          icon: session.isTicketsLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildHero(
    BuildContext context,
    SessionProvider session,
    bool isWide,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 34 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_uagroRed, Color(0xFF3B0D49), _uagroBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: _uagroBlue.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿En qué podemos ayudarte?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crea una nueva solicitud o da seguimiento a tus consultas con la Universidad.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _uagroBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 17,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _openCreateRequestSheet(context, session),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Crear nueva solicitud',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: 26),
            const SizedBox(
              width: 320,
              height: 170,
              child: _SupportIllustration(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiGrid(List<TicketModel> tickets) {
    final kpis = [
      _KpiData(
        label: 'Activas',
        count: tickets.where((ticket) {
          final status = _normalize(ticket.estado);
          return status != 'resuelto' &&
              status != 'cerrado' &&
              status != 'cancelado';
        }).length,
        icon: Icons.confirmation_number_rounded,
        color: _accentBlue,
      ),
      _KpiData(
        label: 'En revisión',
        count: tickets
            .where((t) => _normalize(t.estado) == 'en_revision')
            .length,
        icon: Icons.schedule_rounded,
        color: _warning,
      ),
      _KpiData(
        label: 'En proceso',
        count: tickets
            .where((t) => _normalize(t.estado) == 'en_proceso')
            .length,
        icon: Icons.route_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _KpiData(
        label: 'Resueltas',
        count: tickets.where((t) => _normalize(t.estado) == 'resuelto').length,
        icon: Icons.verified_rounded,
        color: _success,
      ),
      _KpiData(
        label: 'Cerradas',
        count: tickets.where((t) {
          final status = _normalize(t.estado);
          return status == 'cerrado' || status == 'cancelado';
        }).length,
        icon: Icons.inventory_2_rounded,
        color: _muted,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080
            ? 5
            : constraints.maxWidth >= 760
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpis.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: constraints.maxWidth < 520 ? 1.55 : 1.95,
          ),
          itemBuilder: (context, index) => _KpiCard(data: kpis[index]),
        );
      },
    );
  }

  Widget _buildRequestsPanel(
    BuildContext context,
    SessionProvider session,
    List<TicketModel> filteredTickets,
    TicketModel? selectedTicket, {
    required bool isWide,
  }) {
    return Container(
      decoration: _softCardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mis solicitudes',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Crear nueva solicitud',
                onPressed: () => _openCreateRequestSheet(context, session),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar solicitud...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: _line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: _line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: _accentBlue),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusFilterMenu(
                value: _statusFilter,
                onChanged: (value) => setState(() => _statusFilter = value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (session.isTicketsLoading && session.tickets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredTickets.isEmpty)
            _buildEmptyRequests(hasAnyRequests: session.tickets.isNotEmpty)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = filteredTickets[index];
                return _AttentionRequestCard(
                  ticket: ticket,
                  selected: selectedTicket?.id == ticket.id,
                  unreadCount: _hasUnreadSignal(ticket) ? 1 : 0,
                  onTap: () {
                    setState(() => _selectedRequestId = ticket.id);
                    if (!isWide) {
                      _openRequestDetail(context, session, ticket);
                    }
                  },
                );
              },
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: session.isTicketsLoading
                  ? null
                  : () => _refreshTickets(session),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Actualizar seguimiento'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRequests({required bool hasAnyRequests}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _accentBlue.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 36,
              color: _accentBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasAnyRequests
                ? 'No encontramos solicitudes con ese filtro'
                : 'Aún no tienes solicitudes',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasAnyRequests
                ? 'Prueba con otro estado o busca por asunto.'
                : 'Cuando necesites apoyo, inicia una solicitud y te daremos seguimiento.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildImmediateHelpCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
        ),
        border: Border.all(color: const Color(0xFFDDEBFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Necesitas ayuda inmediata?',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Si se trata de una urgencia médica o situación crítica, contacta directamente con los servicios correspondientes.',
                  style: TextStyle(color: _muted, height: 1.45),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Acude al servicio universitario correspondiente o comunícate por los canales oficiales de tu unidad académica.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('Contactar ahora'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SizedBox(
            width: 118,
            height: 118,
            child: _MiniHeadsetIllustration(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorNotice(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.08),
        border: Border.all(color: _danger.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  List<TicketModel> _filteredTickets(List<TicketModel> tickets) {
    final query = _normalize(_searchController.text);
    return tickets.where((ticket) {
      final status = _normalize(ticket.estado);
      final matchesStatus = _statusFilter == 'todos' || status == _statusFilter;
      if (!matchesStatus) return false;

      if (query.isEmpty) return true;
      final haystack = _normalize(
        [
          ticket.id,
          ticket.titulo,
          ticket.descripcion,
          ticket.matricula,
          _categoryLabel(ticket.categoria),
          _statusLabel(ticket.estado),
          _priorityLabel(ticket.prioridad),
        ].join(' '),
      );
      return haystack.contains(query);
    }).toList()..sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt ?? DateTime(1900);
      final bDate = b.updatedAt ?? b.createdAt ?? DateTime(1900);
      return bDate.compareTo(aDate);
    });
  }

  TicketModel? _selectedTicket(
    List<TicketModel> filteredTickets,
    List<TicketModel> allTickets,
  ) {
    if (filteredTickets.isEmpty) return null;
    if (_selectedRequestId != null) {
      for (final ticket in filteredTickets) {
        if (ticket.id == _selectedRequestId) return ticket;
      }
    }
    return filteredTickets.first;
  }

  void _openCreateRequestSheet(BuildContext context, SessionProvider session) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer<SessionProvider>(
          builder: (context, liveSession, _) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.86,
              minChildSize: 0.55,
              maxChildSize: 0.96,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: 22,
                      right: 22,
                      top: 18,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: _buildCreateRequestForm(
                      context,
                      liveSession,
                      onClose: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCreateRequestForm(
    BuildContext context,
    SessionProvider session, {
    required VoidCallback onClose,
  }) {
    final carnet = session.carnet;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: _line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _accentBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_note_rounded, color: _accentBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nueva solicitud de apoyo',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      carnet == null
                          ? 'Datos del alumno no disponibles.'
                          : '${carnet.nombreCompleto} · Matrícula ${carnet.matricula}',
                      style: const TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildEmergencyNotice(),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _categoria,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Área de apoyo',
              prefixIcon: Icon(Icons.category_rounded),
            ),
            items: _categoryLabels.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            validator: (value) => value == null || value.isEmpty
                ? 'Selecciona un área de apoyo.'
                : null,
            onChanged: session.isTicketsLoading
                ? null
                : (value) {
                    if (value != null) setState(() => _categoria = value);
                  },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _prioridad,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Prioridad',
              prefixIcon: Icon(Icons.flag_rounded),
            ),
            items: _priorityLabels.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            validator: (value) => value == null || value.isEmpty
                ? 'Selecciona una prioridad.'
                : null,
            onChanged: session.isTicketsLoading
                ? null
                : (value) {
                    if (value != null) setState(() => _prioridad = value);
                  },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _tituloController,
            enabled: !session.isTicketsLoading,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Asunto',
              prefixIcon: Icon(Icons.title_rounded),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Escribe un asunto.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descripcionController,
            enabled: !session.isTicketsLoading,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Cuéntanos qué sucede',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Describe cómo podemos apoyarte.'
                : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: session.isTicketsLoading
                  ? null
                  : () async {
                      final created = await _submitRequest(context, session);
                      if (created && context.mounted) onClose();
                    },
              icon: session.isTicketsLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Enviar solicitud'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _warning.withValues(alpha: 0.12),
        border: Border.all(color: _warning.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: _warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este canal no sustituye atención de urgencias. En caso de emergencia, acude directamente al servicio correspondiente.',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _submitRequest(
    BuildContext context,
    SessionProvider session,
  ) async {
    if (!_formKey.currentState!.validate()) return false;

    final result = await session.createTicket(
      categoria: _categoria,
      prioridad: _prioridad,
      titulo: _tituloController.text.trim(),
      descripcion: _descripcionController.text.trim(),
    );

    if (!context.mounted) return false;

    final messenger = ScaffoldMessenger.of(context);
    if (result['success'] == true) {
      _formKey.currentState!.reset();
      _tituloController.clear();
      _descripcionController.clear();
      setState(() {
        _categoria = 'soporte_carnet';
        _prioridad = 'media';
        _lastUpdated = DateTime.now();
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Solicitud enviada correctamente.')),
      );
      return true;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'No se pudo enviar la solicitud.',
        ),
        backgroundColor: _danger,
      ),
    );
    return false;
  }

  void _openRequestDetail(
    BuildContext context,
    SessionProvider session,
    TicketModel ticket,
  ) {
    final token = session.token;
    if (token == null || token.isEmpty || token == 'DEMO_TOKEN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión requerida para ver respuestas.')),
      );
      return;
    }

    final carnet = session.carnet;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.62,
        maxChildSize: 0.98,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 18,
              ),
              child: _TicketDetailPanel(
                ticket: ticket,
                token: token,
                studentName: carnet?.nombreCompleto ?? 'Alumno',
                studentMatricula: carnet?.matricula ?? '',
                studentCampus: _studentCampusLabel(carnet),
                studentUnit: _studentUnitLabel(carnet),
                embedded: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AttentionTitle extends StatelessWidget {
  const _AttentionTitle();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 6,
      runSpacing: 0,
      children: [
        Text(
          'Centro de',
          style: TextStyle(
            color: _uagroBlue,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        Text(
          'Atención Universitaria',
          style: TextStyle(
            color: _uagroRed,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active ? _uagroRed : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 21),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
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
}

class _NotificationButton extends StatelessWidget {
  final int count;

  const _NotificationButton({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _uagroBlue.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: _uagroBlue,
          ),
        ),
        if (count > 0)
          Positioned(
            right: 3,
            top: 3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: const BoxDecoration(
                color: _danger,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SupportIllustration extends StatelessWidget {
  const _SupportIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          right: 22,
          top: 10,
          child: Icon(
            Icons.chat_bubble_rounded,
            size: 64,
            color: Colors.white.withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 22,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sms_rounded,
              color: Color(0xFFBBD2FF),
              size: 38,
            ),
          ),
        ),
        Positioned(
          right: 32,
          bottom: 10,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF93B4FF).withValues(alpha: 0.85),
                width: 10,
              ),
            ),
            child: const Icon(
              Icons.headset_mic_rounded,
              color: Color(0xFFBBD2FF),
              size: 78,
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 54,
          child: Icon(
            Icons.more_horiz_rounded,
            color: Colors.white.withValues(alpha: 0.72),
            size: 36,
          ),
        ),
        Positioned(
          left: 114,
          top: 34,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white.withValues(alpha: 0.50),
          ),
        ),
      ],
    );
  }
}

class _MiniHeadsetIllustration extends StatelessWidget {
  const _MiniHeadsetIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE0ECFF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _accentBlue.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.headset_mic_rounded,
          size: 58,
          color: Color(0xFF6887EA),
        ),
      ],
    );
  }
}

class _KpiData {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: data.color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: _uagroBlue.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.count}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
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

class _StatusFilterMenu extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusFilterMenu({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Filtrar',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'todos', child: Text('Todas')),
        PopupMenuItem(value: 'abierto', child: Text('Recibidas')),
        PopupMenuItem(value: 'en_revision', child: Text('En revisión')),
        PopupMenuItem(value: 'en_proceso', child: Text('En proceso')),
        PopupMenuItem(value: 'resuelto', child: Text('Resueltas')),
        PopupMenuItem(value: 'cerrado', child: Text('Cerradas')),
      ],
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _line),
          boxShadow: [
            BoxShadow(
              color: _uagroBlue.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.tune_rounded, color: _uagroBlue),
      ),
    );
  }
}

class _AttentionRequestCard extends StatefulWidget {
  final TicketModel ticket;
  final bool selected;
  final int unreadCount;
  final VoidCallback onTap;

  const _AttentionRequestCard({
    required this.ticket,
    required this.selected,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  State<_AttentionRequestCard> createState() => _AttentionRequestCardState();
}

class _AttentionRequestCardState extends State<_AttentionRequestCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final categoryColor = _categoryColor(ticket.categoria);
    final statusColor = _statusColor(ticket.estado);
    final updatedAt = ticket.updatedAt ?? ticket.createdAt;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.selected ? _accentBlue : _line,
            width: widget.selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _uagroBlue.withValues(alpha: _hovered ? 0.13 : 0.06),
              blurRadius: _hovered ? 24 : 18,
              offset: Offset(0, _hovered ? 14 : 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _categoryIcon(ticket.categoria),
                          color: categoryColor,
                        ),
                      ),
                      if (widget.unreadCount > 0)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: _danger,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${widget.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _categoryLabel(ticket.categoria),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket.titulo.trim().isEmpty
                              ? 'Solicitud sin asunto'
                              : ticket.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _MiniPill(
                              label: _statusLabel(ticket.estado),
                              color: statusColor,
                            ),
                            _MiniPill(
                              label: _priorityLabel(ticket.prioridad),
                              color: _priorityColor(ticket.prioridad),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Actualizado ${_formatRelativeDate(updatedAt)}',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _shortFolio(ticket.id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _uagroBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: _uagroBlue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketDetailPanel extends StatefulWidget {
  final TicketModel? ticket;
  final String token;
  final String studentName;
  final String studentMatricula;
  final String studentCampus;
  final String studentUnit;
  final bool embedded;

  const _TicketDetailPanel({
    required this.ticket,
    required this.token,
    required this.studentName,
    required this.studentMatricula,
    required this.studentCampus,
    required this.studentUnit,
    this.embedded = false,
  });

  @override
  State<_TicketDetailPanel> createState() => _TicketDetailPanelState();
}

class _TicketDetailPanelState extends State<_TicketDetailPanel> {
  Future<List<TicketMessageModel>>? _messagesFuture;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void didUpdateWidget(covariant _TicketDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticket?.id != widget.ticket?.id ||
        oldWidget.token != widget.token) {
      _loadMessages();
    }
  }

  void _loadMessages() {
    final ticket = widget.ticket;
    if (ticket == null || widget.token.isEmpty) {
      _messagesFuture = null;
      return;
    }
    _messagesFuture = ApiService.getTicketMessages(widget.token, ticket.id);
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    if (ticket == null) return _buildNoSelection();

    return Container(
      decoration: widget.embedded ? null : _softCardDecoration(),
      padding: EdgeInsets.all(widget.embedded ? 0 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.embedded)
            Center(
              child: Container(
                width: 46,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          _buildDetailHeader(ticket),
          const SizedBox(height: 20),
          _buildProgress(ticket),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 760;
              if (!twoColumns) {
                return Column(
                  children: [
                    _buildConversation(ticket),
                    const SizedBox(height: 16),
                    _buildInfoColumn(ticket),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildConversation(ticket)),
                  const SizedBox(width: 18),
                  SizedBox(width: 250, child: _buildInfoColumn(ticket)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoSelection() {
    return Container(
      constraints: const BoxConstraints(minHeight: 420),
      decoration: _softCardDecoration(),
      padding: const EdgeInsets.all(28),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, color: _accentBlue, size: 58),
            SizedBox(height: 14),
            Text(
              'Selecciona una solicitud',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Aquí verás el seguimiento y las respuestas de la Universidad.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHeader(TicketModel ticket) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _categoryColor(ticket.categoria).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _categoryIcon(ticket.categoria),
            color: _categoryColor(ticket.categoria),
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalle de solicitud',
                style: TextStyle(
                  color: _accentBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ticket.titulo.trim().isEmpty
                    ? 'Solicitud sin asunto'
                    : ticket.titulo,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Folio: ${_shortFolio(ticket.id)}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniPill(
                    label: _statusLabel(ticket.estado),
                    color: _statusColor(ticket.estado),
                  ),
                  _MiniPill(
                    label: _priorityLabel(ticket.prioridad),
                    color: _priorityColor(ticket.prioridad),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.embedded)
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }

  Widget _buildProgress(TicketModel ticket) {
    final currentStep = _progressIndex(ticket.estado);
    final steps = [
      _ProgressStep('Recibido', Icons.check_rounded),
      _ProgressStep('En revisión', Icons.schedule_rounded),
      _ProgressStep('Canalizado', Icons.route_rounded),
      _ProgressStep('Resuelto', Icons.verified_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: _ProgressNode(
                step: steps[i],
                active: i <= currentStep,
                current: i == currentStep,
              ),
            ),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  color: i < currentStep ? _success : _line,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversation(TicketModel ticket) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Text(
              'Conversación',
              style: TextStyle(
                color: _accentBlue,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Divider(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: FutureBuilder<List<TicketMessageModel>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text('No se pudieron cargar las respuestas.'),
                    ),
                  );
                }

                final messages = (snapshot.data ?? const <TicketMessageModel>[])
                    .where((message) => !_isInternalRole(message.senderRole))
                    .toList();

                return Column(
                  children: [
                    _ConversationBubble(
                      isStudent: true,
                      sender: 'Tú',
                      roleLabel: 'Alumno',
                      date: ticket.createdAt,
                      message: ticket.descripcion.trim().isEmpty
                          ? 'Solicitud enviada.'
                          : ticket.descripcion,
                      initials: _studentInitials(widget.studentName),
                    ),
                    if (messages.isEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _accentBlue.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'La Universidad recibió tu solicitud. Cuando haya una respuesta visible para ti, aparecerá en esta conversación.',
                          style: TextStyle(color: _muted, height: 1.4),
                        ),
                      )
                    else
                      ...messages.map((message) {
                        final isStudent = _isStudentRole(message.senderRole);
                        return _ConversationBubble(
                          isStudent: isStudent,
                          sender: isStudent
                              ? 'Tú'
                              : (message.senderName.trim().isEmpty
                                    ? 'Centro de Atención'
                                    : message.senderName),
                          roleLabel: isStudent ? 'Alumno' : 'Universidad',
                          date: message.createdAt,
                          message: message.message,
                          initials: isStudent
                              ? _studentInitials(widget.studentName)
                              : 'UA',
                        );
                      }),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _success.withValues(alpha: 0.16),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_rounded, color: _success, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Solo se muestran respuestas visibles para ti.',
                              style: TextStyle(
                                color: _success,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(TicketModel ticket) {
    return Column(
      children: [
        _InfoCard(
          title: 'Estado actual',
          children: [
            _InfoRow('Recibido', _formatDate(ticket.createdAt)),
            _InfoRow(
              _statusLabel(ticket.estado),
              _formatDate(ticket.updatedAt),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Información de la solicitud',
          children: [
            _InfoRow('Área', _categoryLabel(ticket.categoria)),
            _InfoRow('Prioridad', _priorityLabel(ticket.prioridad)),
            _InfoRow('Campus', widget.studentCampus),
            _InfoRow('Unidad', widget.studentUnit),
            _InfoRow('Matrícula', widget.studentMatricula),
            _InfoRow('Creación', _formatDate(ticket.createdAt)),
            _InfoRow('Última actualización', _formatDate(ticket.updatedAt)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _warning.withValues(alpha: 0.20)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: _warning),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Te notificaremos por este medio cuando haya novedades en tu solicitud.',
                  style: TextStyle(color: _ink, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  final bool isStudent;
  final String sender;
  final String roleLabel;
  final DateTime? date;
  final String message;
  final String initials;

  const _ConversationBubble({
    required this.isStudent,
    required this.sender,
    required this.roleLabel,
    required this.date,
    required this.message,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isStudent
        ? const Color(0xFFF3F0FF)
        : const Color(0xFFEFF6FF);
    final avatarColor = isStudent ? const Color(0xFF6D5DF6) : _uagroRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: isStudent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isStudent) _BubbleAvatar(initials: initials, color: avatarColor),
          if (!isStudent) const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: isStudent
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      sender,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _MiniPill(
                      label: roleLabel,
                      color: isStudent ? _accentBlue : _uagroRed,
                    ),
                    Text(
                      _formatDate(date),
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8),
                      topRight: const Radius.circular(8),
                      bottomLeft: Radius.circular(isStudent ? 8 : 2),
                      bottomRight: Radius.circular(isStudent ? 2 : 8),
                    ),
                    border: Border.all(
                      color: (isStudent ? _accentBlue : _uagroBlue).withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(color: _ink, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
          if (isStudent) const SizedBox(width: 12),
          if (isStudent) _BubbleAvatar(initials: initials, color: avatarColor),
        ],
      ),
    );
  }
}

class _BubbleAvatar extends StatelessWidget {
  final String initials;
  final Color color;

  const _BubbleAvatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProgressStep {
  final String label;
  final IconData icon;

  const _ProgressStep(this.label, this.icon);
}

class _ProgressNode extends StatelessWidget {
  final _ProgressStep step;
  final bool active;
  final bool current;

  const _ProgressNode({
    required this.step,
    required this.active,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _success : _muted.withValues(alpha: 0.45);
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: current ? 38 : 34,
          height: current ? 38 : 34,
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.14)
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: current ? 2 : 1),
          ),
          child: Icon(step.icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          step.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? _ink : _muted,
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? 'No disponible' : value,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

BoxDecoration _softCardDecoration() {
  return BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _line.withValues(alpha: 0.72)),
    boxShadow: [
      BoxShadow(
        color: _uagroBlue.withValues(alpha: 0.06),
        blurRadius: 28,
        offset: const Offset(0, 18),
      ),
    ],
  );
}

String _categoryLabel(String value) {
  return _categoryLabels[value] ?? value.replaceAll('_', ' ');
}

String _priorityLabel(String value) {
  return _priorityLabels[value] ?? value;
}

String _statusLabel(String value) {
  final status = _normalize(value);
  switch (status) {
    case 'en_revision':
      return 'En revisión';
    case 'en_proceso':
      return 'En proceso';
    case 'resuelto':
      return 'Resuelto';
    case 'cerrado':
      return 'Cerrado';
    case 'cancelado':
      return 'Cancelado';
    default:
      return 'Recibido';
  }
}

Color _statusColor(String value) {
  final status = _normalize(value);
  switch (status) {
    case 'en_revision':
      return _warning;
    case 'en_proceso':
      return const Color(0xFF8B5CF6);
    case 'resuelto':
      return _success;
    case 'cerrado':
    case 'cancelado':
      return _muted;
    default:
      return _accentBlue;
  }
}

Color _priorityColor(String priority) {
  switch (_normalize(priority)) {
    case 'urgente':
      return _danger;
    case 'alta':
      return _warning;
    case 'baja':
      return _success;
    default:
      return _accentBlue;
  }
}

IconData _categoryIcon(String category) {
  switch (_normalize(category)) {
    case 'psicologia':
      return Icons.psychology_rounded;
    case 'medicina':
      return Icons.medical_services_rounded;
    case 'nutricion':
      return Icons.restaurant_rounded;
    case 'vacunacion':
      return Icons.vaccines_rounded;
    case 'promocion_salud':
      return Icons.campaign_rounded;
    case 'administrativo':
      return Icons.assignment_rounded;
    case 'soporte_carnet':
      return Icons.badge_rounded;
    default:
      return Icons.support_agent_rounded;
  }
}

Color _categoryColor(String category) {
  switch (_normalize(category)) {
    case 'psicologia':
      return const Color(0xFF8B5CF6);
    case 'medicina':
      return _success;
    case 'nutricion':
      return const Color(0xFFF97316);
    case 'vacunacion':
      return const Color(0xFF14B8A6);
    case 'promocion_salud':
      return const Color(0xFFE11D48);
    case 'administrativo':
      return _warning;
    case 'soporte_carnet':
      return _accentBlue;
    default:
      return _muted;
  }
}

int _progressIndex(String status) {
  switch (_normalize(status)) {
    case 'en_revision':
      return 1;
    case 'en_proceso':
      return 2;
    case 'resuelto':
    case 'cerrado':
      return 3;
    default:
      return 0;
  }
}

bool _hasUnreadSignal(TicketModel ticket) {
  final created = ticket.createdAt;
  final updated = ticket.updatedAt;
  if (created == null || updated == null) return false;
  return updated.difference(created).inMinutes > 1 &&
      DateTime.now().difference(updated).inDays < 7;
}

bool _isStudentRole(String role) {
  final clean = _normalize(role);
  return clean == 'alumno' || clean == 'student' || clean == 'estudiante';
}

bool _isInternalRole(String role) {
  final clean = _normalize(role);
  return clean == 'internal' || clean == 'interno';
}

String _studentInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'AU';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _studentCampusLabel(CarnetModel? carnet) {
  final unit = carnet?.unidadMedica.trim() ?? '';
  if (unit.isNotEmpty) return unit;
  return 'CRES Llano Largo';
}

String _studentUnitLabel(CarnetModel? carnet) {
  final program = carnet?.programa.trim() ?? '';
  if (program.isNotEmpty) return program;
  final category = carnet?.categoria.trim() ?? '';
  if (category.isNotEmpty) return category;
  return 'Universidad Autónoma de Guerrero';
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Pendiente';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String _formatRelativeDate(DateTime? date) {
  if (date == null) return 'recientemente';
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) return 'justo ahora';
  if (difference.inMinutes < 60) {
    return 'hace ${difference.inMinutes} min';
  }
  if (difference.inHours < 24) {
    return 'hace ${difference.inHours} h';
  }
  if (difference.inDays == 1) return 'ayer';
  if (difference.inDays < 7) return 'hace ${difference.inDays} días';
  return _formatDate(date);
}

String _shortFolio(String id) {
  if (id.trim().isEmpty) return 'Folio pendiente';
  final clean = id.trim();
  if (clean.length <= 24) return clean;
  return '${clean.substring(0, 12)}...${clean.substring(clean.length - 6)}';
}

String _normalize(String value) {
  return value.trim().toLowerCase().replaceAll(' ', '_');
}
