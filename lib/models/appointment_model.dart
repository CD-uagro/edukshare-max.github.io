class AppointmentModel {
  final String id;
  final AppointmentStudent student;
  final String area;
  final String reasonCategory;
  final String reasonText;
  final String preferredDate;
  final String preferredTimeBlock;
  final String? scheduledStart;
  final String? scheduledEnd;
  final String status;
  final String priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? cancellationReason;
  final String? rescheduleReason;
  final List<AppointmentHistoryEntry> history;

  const AppointmentModel({
    required this.id,
    required this.student,
    required this.area,
    required this.reasonCategory,
    required this.reasonText,
    required this.preferredDate,
    required this.preferredTimeBlock,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.cancellationReason,
    required this.rescheduleReason,
    required this.history,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final studentJson = json['student'] is Map
        ? Map<String, dynamic>.from(json['student'] as Map)
        : <String, dynamic>{};
    return AppointmentModel(
      id: _readString(json, ['id']),
      student: AppointmentStudent.fromJson(studentJson),
      area: _readString(json, ['area']),
      reasonCategory: _readString(json, ['reason_category', 'reasonCategory']),
      reasonText: _readString(json, ['reason_text', 'reasonText']),
      preferredDate: _readString(json, ['preferred_date', 'preferredDate']),
      preferredTimeBlock: _readString(json, [
        'preferred_time_block',
        'preferredTimeBlock',
      ]),
      scheduledStart: _readNullableString(json, [
        'scheduled_start',
        'scheduledStart',
      ]),
      scheduledEnd: _readNullableString(json, [
        'scheduled_end',
        'scheduledEnd',
      ]),
      status: _readString(json, ['status'], fallback: 'requested'),
      priority: _readString(json, ['priority'], fallback: 'normal'),
      createdAt: _readDate(json, ['created_at', 'createdAt']),
      updatedAt: _readDate(json, ['updated_at', 'updatedAt']),
      cancellationReason: _readNullableString(json, [
        'cancellation_reason',
        'cancellationReason',
      ]),
      rescheduleReason: _readNullableString(json, [
        'reschedule_reason',
        'rescheduleReason',
      ]),
      history: _readList(
        json['history'],
      ).map((item) => AppointmentHistoryEntry.fromJson(item)).toList(),
    );
  }

  bool get canCancel =>
      status == 'requested' || status == 'confirmed' || status == 'rescheduled';
}

class AppointmentStudent {
  final String matricula;
  final String nombre;
  final String correoInstitucional;
  final String programa;
  final String campus;

  const AppointmentStudent({
    required this.matricula,
    required this.nombre,
    required this.correoInstitucional,
    required this.programa,
    required this.campus,
  });

  factory AppointmentStudent.fromJson(Map<String, dynamic> json) {
    return AppointmentStudent(
      matricula: _readString(json, ['matricula']),
      nombre: _readString(json, ['nombre', 'nombreCompleto']),
      correoInstitucional: _readString(json, [
        'correo_institucional',
        'correoInstitucional',
      ]),
      programa: _readString(json, ['programa']),
      campus: _readString(json, ['campus']),
    );
  }
}

class AppointmentHistoryEntry {
  final String fromStatus;
  final String toStatus;
  final String actor;
  final String actorRole;
  final String message;
  final DateTime? createdAt;

  const AppointmentHistoryEntry({
    required this.fromStatus,
    required this.toStatus,
    required this.actor,
    required this.actorRole,
    required this.message,
    required this.createdAt,
  });

  factory AppointmentHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AppointmentHistoryEntry(
      fromStatus: _readString(json, ['from', 'from_status']),
      toStatus: _readString(json, ['to', 'to_status']),
      actor: _readString(json, ['actor']),
      actorRole: _readString(json, ['actor_role', 'actorRole']),
      message: _readString(json, ['message']),
      createdAt: _readDate(json, ['created_at', 'createdAt']),
    );
  }
}

class CreateAppointmentRequest {
  final String area;
  final String reasonCategory;
  final String reasonText;
  final String preferredDate;
  final String preferredTimeBlock;

  const CreateAppointmentRequest({
    required this.area,
    required this.reasonCategory,
    required this.reasonText,
    required this.preferredDate,
    required this.preferredTimeBlock,
  });

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'reason_category': reasonCategory,
      'reason_text': reasonText,
      'preferred_date': preferredDate,
      'preferred_time_block': preferredTimeBlock,
    };
  }
}

List<Map<String, dynamic>> _readList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return fallback;
}

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  return value.isEmpty ? null : value;
}

DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}
