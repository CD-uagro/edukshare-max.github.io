import 'package:carnet_digital_uagro/models/ticket_model.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/theme/uagro_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CentroAtencionScreen extends StatefulWidget {
  const CentroAtencionScreen({super.key});

  @override
  State<CentroAtencionScreen> createState() => _CentroAtencionScreenState();
}

class _CentroAtencionScreenState extends State<CentroAtencionScreen>
    with SingleTickerProviderStateMixin {
  static const Map<String, String> _categorias = {
    'psicologia': 'Psicología',
    'medicina': 'Medicina',
    'nutricion': 'Nutrición',
    'vacunacion': 'Vacunación',
    'promocion_salud': 'Promoción de salud',
    'soporte_carnet': 'Soporte de carnet',
    'administrativo': 'Administrativo',
    'otro': 'Otro',
  };

  static const Map<String, String> _prioridades = {
    'baja': 'Baja',
    'media': 'Media',
    'alta': 'Alta',
    'urgente': 'Urgente',
  };

  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  String _categoria = 'soporte_carnet';
  String _prioridad = 'media';
  bool _initialTicketsLoadRequested = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTicketsIfReady());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Atención'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: UAGroColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.confirmation_number_rounded),
              text: 'Mis Tickets',
            ),
            Tab(
              icon: Icon(Icons.add_circle_outline_rounded),
              text: 'Crear Ticket',
            ),
          ],
        ),
      ),
      body: Consumer<SessionProvider>(
        builder: (context, session, child) {
          if (session.isAuthenticated && session.carnet != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _loadTicketsIfReady(),
            );
          }

          if (session.isLoading ||
              (session.isAuthenticated && session.carnet == null)) {
            return _buildSessionLoading();
          }

          if (!session.isAuthenticated || session.carnet == null) {
            return _buildSessionRequired(context);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTicketsView(context, session),
              _buildCreateTicketView(context, session),
            ],
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
    session.loadTickets(force: true);
  }

  Widget _buildSessionLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildSessionRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: UAGroColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sesión requerida',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión para consultar o crear tickets de atención.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
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

  Widget _buildTicketsView(BuildContext context, SessionProvider session) {
    if (session.isTicketsLoading && session.tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => session.loadTickets(force: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEmergencyNotice(),
          if (session.ticketsError != null) ...[
            const SizedBox(height: 12),
            _buildErrorNotice(session.ticketsError!),
          ],
          const SizedBox(height: 16),
          if (session.tickets.isEmpty)
            _buildEmptyTickets()
          else
            ...session.tickets.map(_buildTicketCard),
        ],
      ),
    );
  }

  Widget _buildCreateTicketView(BuildContext context, SessionProvider session) {
    final carnet = session.carnet;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEmergencyNotice(),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crear Ticket',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    carnet == null
                        ? 'Datos del alumno no disponibles.'
                        : '${carnet.nombreCompleto} · Matrícula ${carnet.matricula}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _categoria,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: _categorias.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Selecciona una categoría.'
                        : null,
                    onChanged: session.isTicketsLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _categoria = value);
                            }
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
                    items: _prioridades.entries.map((entry) {
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
                            if (value != null) {
                              setState(() => _prioridad = value);
                            }
                          },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _tituloController,
                    enabled: !session.isTicketsLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe un título.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descripcionController,
                    enabled: !session.isTicketsLoading,
                    minLines: 5,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe una descripción.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: session.isTicketsLoading
                          ? null
                          : () => _submitTicket(context, session),
                      icon: session.isTicketsLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Crear ticket'),
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

  Future<void> _submitTicket(
    BuildContext context,
    SessionProvider session,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final result = await session.createTicket(
      categoria: _categoria,
      prioridad: _prioridad,
      titulo: _tituloController.text.trim(),
      descripcion: _descripcionController.text.trim(),
    );

    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (result['success'] == true) {
      _formKey.currentState!.reset();
      _tituloController.clear();
      _descripcionController.clear();
      setState(() {
        _categoria = 'soporte_carnet';
        _prioridad = 'media';
      });
      _tabController.animateTo(0);
      messenger.showSnackBar(
        const SnackBar(content: Text('Ticket creado correctamente.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'No se pudo crear el ticket.',
          ),
          backgroundColor: UAGroColors.error,
        ),
      );
    }
  }

  Widget _buildEmergencyNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UAGroColors.warning.withValues(alpha: 0.12),
        border: Border.all(color: UAGroColors.warning.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: UAGroColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este canal no sustituye atención de urgencias. En caso de emergencia, acude directamente al servicio correspondiente.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorNotice(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: UAGroColors.error.withValues(alpha: 0.08),
        border: Border.all(color: UAGroColors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: UAGroColors.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Widget _buildEmptyTickets() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          const Text(
            'No tienes tickets registrados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando crees una solicitud, aparecerá en esta lista.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _tabController.animateTo(1),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Crear ticket'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    final priorityColor = _priorityColor(ticket.prioridad);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: UAGroColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    color: UAGroColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.titulo.isEmpty
                            ? 'Ticket sin título'
                            : ticket.titulo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(ticket.createdAt),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  _categoryLabel(ticket.categoria),
                  UAGroColors.primary,
                ),
                _buildChip(_priorityLabel(ticket.prioridad), priorityColor),
                _buildChip(_statusLabel(ticket.estado), UAGroColors.success),
              ],
            ),
            if (ticket.descripcion.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                ticket.descripcion,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade800),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _categoryLabel(String value) {
    return _categorias[value] ?? value.replaceAll('_', ' ');
  }

  String _priorityLabel(String value) {
    return _prioridades[value] ?? value;
  }

  String _statusLabel(String value) {
    if (value.trim().isEmpty) return 'Abierto';
    final clean = value.replaceAll('_', ' ');
    return clean[0].toUpperCase() + clean.substring(1);
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgente':
        return UAGroColors.error;
      case 'alta':
        return UAGroColors.warning;
      case 'baja':
        return UAGroColors.success;
      default:
        return UAGroColors.primary;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha no disponible';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
