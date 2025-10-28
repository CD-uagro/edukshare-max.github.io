// 🏥 CITAS SCREEN - CITAS MÉDICAS
// Vista de citas médicas del estudiante

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/models/cita_model.dart';
import 'package:carnet_digital_uagro/theme/uagro_theme.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar citas al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadCitas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas Médicas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Limpiar citas pasadas',
            onPressed: () => _limpiarCitasPasadas(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              print('🔄 Refresh manual de citas...');
              await context.read<SessionProvider>().loadCitas();
            },
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, session, child) {
          print('🖥️ CitasScreen builder - isLoading: ${session.isLoading}, citas: ${session.citas.length}');
          
          if (session.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (session.citas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tienes citas programadas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              print('🔄 RefreshIndicator de citas...');
              return await context.read<SessionProvider>().loadCitas();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: session.citas.length,
              itemBuilder: (context, index) {
                final cita = session.citas[index];
                return _buildCitaCard(cita);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCitaCard(CitaModel cita) {
    Color statusColor;
    IconData statusIcon;
    
    switch (cita.estado.toLowerCase()) {
      case 'programada':
        statusColor = UAGroColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'confirmada':
        statusColor = UAGroColors.primary;
        statusIcon = Icons.verified;
        break;
      case 'cancelada':
        statusColor = UAGroColors.error;
        statusIcon = Icons.cancel;
        break;
      case 'completada':
        statusColor = Colors.grey;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = UAGroColors.warning;
        statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con estado
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  cita.estado.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: UAGroColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cita.departamento,
                    style: const TextStyle(
                      fontSize: 12,
                      color: UAGroColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Fecha y hora - usando datos reales del backend
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  cita.fechaFormateada,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  cita.horario, // Usa el getter que combina inicio - fin
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Departamento
            Row(
              children: [
                const Icon(
                  Icons.local_hospital,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cita.departamento,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Motivo
            if (cita.motivo.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.description,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cita.motivo,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${fecha.day} de ${months[fecha.month - 1]} ${fecha.year}';
  }


  void _limpiarCitasPasadas(BuildContext context) {
    final session = context.read<SessionProvider>();
    final citasPasadas = session.citas.where((cita) {
      try {
        final fechaCita = DateTime.parse(cita.inicio);
        return fechaCita.isBefore(DateTime.now());
      } catch (e) {
        return false;
      }
    }).toList();

    if (citasPasadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay citas pasadas para limpiar'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.orange),
            SizedBox(width: 12),
            Text('Limpiar Citas Pasadas'),
          ],
        ),
        content: Text(
          '¿Deseas eliminar ${citasPasadas.length} cita(s) pasada(s) de tu lista?\n\n'
          'Esta acción solo limpiará la visualización local, las citas seguirán en el historial médico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Se limpiaron ${citasPasadas.length} cita(s) pasada(s)'),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'Recargar',
                    textColor: Colors.white,
                    onPressed: () => session.loadCitas(),
                  ),
                ),
              );

              session.loadCitas();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

}
