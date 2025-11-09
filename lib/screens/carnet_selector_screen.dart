// 🎨 SELECTOR DE DISEÑO DE CARNET
// Selecciona entre múltiples diseños de carnet disponibles

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/screens/carnet_screen.dart';
import 'package:carnet_digital_uagro/screens/carnet_screen_new.dart';

class CarnetSelectorScreen extends StatelessWidget {
  const CarnetSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    
    // Selector de diseño basado en preferencia del usuario
    switch (session.carnetDesign) {
      case 'modern':
        return const CarnetScreenNew();
      case 'wallet':
      default:
        return const CarnetScreen();
    }
  }
}
