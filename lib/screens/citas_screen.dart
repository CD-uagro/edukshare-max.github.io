import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:carnet_digital_uagro/models/appointment_model.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/theme/uagro_theme.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  static const _areas = {
    'medicina': '🏥 Médico',
    'psicologia': '🧠 Psicología',
    'nutricion': '🥗 Nutrición',
    'odontologia': '🦷 Odontología',
    'atencion_estudiantil': '🎓 Atención estudiantil',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadAppointments(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Agenda Universitaria'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              context.read<SessionProvider>().loadAppointments(force: true);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, session, child) {
          if (session.isAppointmentsLoading && session.appointments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => session.loadAppointments(force: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
              children: [
                _buildHero(showAction: session.appointments.isNotEmpty),
                const SizedBox(height: 16),
                if (session.appointmentsError != null)
                  _ErrorBanner(message: session.appointmentsError!),
                if (session.appointments.isEmpty)
                  _buildEmpty(context)
                else
                  ...session.appointments.map(
                    (appointment) => _AppointmentCard(
                      appointment: appointment,
                      areaLabel: _areaLabel(appointment.area),
                      onTap: () => _showDetail(context, appointment),
                      onCancel: appointment.canCancel
                          ? () => _confirmCancel(context, appointment)
                          : null,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero({required bool showAction}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF002B5B), Color(0xFF0B67C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002B5B).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                  'Agenda Universitaria',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pide apoyo medico, psicologico, nutricional, odontologico o estudiantil y sigue cada paso desde tu carnet.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.84),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                if (showAction) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF002B5B),
                    ),
                    onPressed: () => _showCreateAppointmentSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Solicitar atencion'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              size: 40,
              color: Color(0xFF0B67C7),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Necesitas apoyo?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Puedes solicitar atencion medica, psicologica, nutricional, odontologica o estudiantil. Nuestro equipo revisara tu solicitud y dara seguimiento.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.35),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _showCreateAppointmentSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Solicitar atencion'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateAppointmentSheet(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateAppointmentSheet(),
    );
    if (created == true && mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 44,
          ),
          title: const Text('Solicitud enviada'),
          content: const Text(
            'Tu solicitud fue registrada correctamente.\n\nEl equipo SASU revisara tu solicitud y te notificara cuando sea atendida.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showDetail(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AppointmentDetailSheet(
        appointment: appointment,
        areaLabel: _areaLabel(appointment.area),
        onCancel: appointment.canCancel
            ? () => _confirmCancel(context, appointment)
            : null,
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    AppointmentModel appointment,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: TextField(
          controller: reasonController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Motivo opcional'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar cita'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    final result = await context.read<SessionProvider>().cancelAppointment(
      appointment.id,
      reason: reason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Cita actualizada'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  static String _areaLabel(String value) =>
      _areas[value] ?? value.replaceAll('_', ' ');
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final String areaLabel;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.areaLabel,
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _cardDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusIcon(status: appointment.status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          areaLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          appointment.reasonCategory,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: appointment.status),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                appointment.reasonText.isEmpty
                    ? 'Sin comentario adicional'
                    : appointment.reasonText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.calendar_today_rounded,
                    text: appointment.scheduledStart == null
                        ? 'Preferencia: ${appointment.preferredDate}'
                        : 'Confirmada: ${_formatDate(appointment.scheduledStart)}',
                  ),
                  _InfoPill(
                    icon: Icons.schedule_rounded,
                    text: appointment.scheduledStart == null
                        ? _blockLabel(appointment.preferredTimeBlock)
                        : _formatTime(appointment.scheduledStart),
                  ),
                ],
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar solicitud'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateAppointmentSheet extends StatefulWidget {
  const _CreateAppointmentSheet();

  @override
  State<_CreateAppointmentSheet> createState() =>
      _CreateAppointmentSheetState();
}

class _CreateAppointmentSheetState extends State<_CreateAppointmentSheet> {
  final _reasonController = TextEditingController();
  final _commentController = TextEditingController();
  DateTime? _preferredDate;
  String _area = 'medicina';
  String _timeBlock = 'morning';
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 45)),
      initialDate: _preferredDate ?? now,
    );
    if (picked != null) {
      setState(() => _preferredDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final reason = _reasonController.text.trim();
    if (reason.isEmpty || _preferredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indica que necesitas y la fecha que prefieres.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await context.read<SessionProvider>().createAppointment(
      area: _area,
      reasonCategory: reason,
      reasonText: _commentController.text.trim(),
      preferredDate: DateFormat('yyyy-MM-dd').format(_preferredDate!),
      preferredTimeBlock: _timeBlock,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'No se pudo solicitar la cita',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          AbsorbPointer(
            absorbing: _submitting,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Solicitar atencion',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Cuentanos que apoyo necesitas. SASU revisara tu solicitud y te avisara el siguiente paso.',
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: _area,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de apoyo',
                      ),
                      items: _CitasScreenState._areas.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: _submitting
                          ? null
                          : (value) => setState(() => _area = value ?? _area),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Que necesitas',
                        hintText: 'Ej. Me siento mal, orientacion, seguimiento',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Cuentanos un poco mas (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickDate,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(
                        _preferredDate == null
                            ? 'Elegir fecha preferida'
                            : DateFormat('dd/MM/yyyy').format(_preferredDate!),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'morning',
                          icon: Icon(Icons.wb_sunny_outlined),
                          label: Text('Manana'),
                        ),
                        ButtonSegment(
                          value: 'afternoon',
                          icon: Icon(Icons.nights_stay_outlined),
                          label: Text('Tarde'),
                        ),
                      ],
                      selected: {_timeBlock},
                      onSelectionChanged: _submitting
                          ? null
                          : (value) {
                              setState(() => _timeBlock = value.first);
                            },
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Solicitar atencion'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_submitting)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.38),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: const Center(child: _SubmittingCard()),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubmittingCard extends StatelessWidget {
  const _SubmittingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Enviando solicitud...',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Espera un momento. No necesitas volver a tocar el boton.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _AppointmentDetailSheet extends StatelessWidget {
  final AppointmentModel appointment;
  final String areaLabel;
  final VoidCallback? onCancel;

  const _AppointmentDetailSheet({
    required this.appointment,
    required this.areaLabel,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final visibleHistory = appointment.history
        .where((item) => item.actorRole.toLowerCase() != 'system')
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    areaLabel,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusChip(status: appointment.status),
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Folio', value: appointment.id),
            _DetailRow(
              label: 'Apoyo solicitado',
              value: appointment.reasonCategory,
            ),
            _DetailRow(label: 'Comentario', value: appointment.reasonText),
            _DetailRow(
              label: 'Preferencia',
              value:
                  '${appointment.preferredDate} / ${_blockLabel(appointment.preferredTimeBlock)}',
            ),
            _DetailRow(
              label: 'Siguiente paso',
              value: appointment.scheduledStart == null
                  ? 'SASU revisara tu solicitud'
                  : '${_formatDate(appointment.scheduledStart)} ${_formatTime(appointment.scheduledStart)}',
            ),
            const SizedBox(height: 18),
            const Text(
              'Como va tu solicitud',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (visibleHistory.isEmpty)
              const Text('SASU aun no ha agregado movimientos.')
            else
              ...visibleHistory.asMap().entries.map(
                (entry) => _TimelineEntry(
                  item: entry.value,
                  isLast: entry.key == visibleHistory.length - 1,
                ),
              ),
            if (onCancel != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar solicitud'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final AppointmentHistoryEntry item;
  final bool isLast;

  const _TimelineEntry({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.toStatus);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 18, color: color),
            ),
            if (!isLast)
              Container(width: 2, height: 46, color: const Color(0xFFE0E7F1)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(item.toStatus),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message.isEmpty
                      ? 'SASU actualizo el seguimiento.'
                      : item.message,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(item.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.event_note_rounded, color: _statusColor(status)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0B67C7)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 3),
          Text(value.isEmpty ? 'No especificado' : value),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE6ECF5)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _statusLabel(String value) {
  switch (value) {
    case 'requested':
      return 'Solicitud enviada';
    case 'confirmed':
      return 'Atencion confirmada';
    case 'rescheduled':
      return 'Fecha reprogramada';
    case 'cancelled_by_student':
      return 'Cancelada por ti';
    case 'cancelled_by_staff':
      return 'Cancelada por SASU';
    case 'attended':
      return 'Atencion completada';
    case 'no_show':
      return 'No asististe';
    case 'rejected':
      return 'Rechazada';
    default:
      return value.replaceAll('_', ' ');
  }
}

Color _statusColor(String value) {
  switch (value) {
    case 'requested':
      return Colors.amber.shade800;
    case 'confirmed':
      return UAGroColors.primary;
    case 'rescheduled':
      return Colors.orange.shade700;
    case 'attended':
      return Colors.green.shade700;
    case 'cancelled_by_student':
    case 'cancelled_by_staff':
    case 'rejected':
      return Colors.grey.shade700;
    case 'no_show':
      return Colors.red.shade400;
    default:
      return UAGroColors.primary;
  }
}

String _blockLabel(String value) {
  switch (value) {
    case 'morning':
      return 'Mañana';
    case 'afternoon':
      return 'Tarde';
    default:
      return value;
  }
}

String _formatDate(String? value) {
  final parsed = value == null ? null : DateTime.tryParse(value);
  if (parsed == null) return 'Pendiente';
  return DateFormat('dd/MM/yyyy').format(parsed.toLocal());
}

String _formatTime(String? value) {
  final parsed = value == null ? null : DateTime.tryParse(value);
  if (parsed == null) return 'Horario pendiente';
  return DateFormat('HH:mm').format(parsed.toLocal());
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'Fecha pendiente';
  return DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
}
