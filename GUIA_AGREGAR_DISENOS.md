# 🎨 Guía para Agregar Nuevos Diseños al Carnet Digital UAGro

## 📋 Descripción General

El sistema está preparado para incorporar fácilmente nuevos diseños de carnet ganadores del concurso. Cada diseño es una pantalla Flutter independiente que muestra la misma información del carnet pero con diferente presentación visual.

## 🏆 Proceso de Integración de Diseños Ganadores

### 1. Crear el Archivo del Nuevo Diseño

**Ubicación:** `lib/screens/`  
**Nombre sugerido:** `carnet_screen_<nombre_diseño>.dart`

**Ejemplo para diseño ganador "Neon":**
```dart
// 🏥 CARNET DIGITAL UAGRO - DISEÑO NEON
// Diseñado por: [Nombre del ganador]
// Fecha: [Fecha del concurso]

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carnet_digital_uagro/providers/session_provider.dart';
import 'package:carnet_digital_uagro/models/carnet_model.dart';

class CarnetScreenNeon extends StatefulWidget {
  const CarnetScreenNeon({super.key});

  @override
  State<CarnetScreenNeon> createState() => _CarnetScreenNeonState();
}

class _CarnetScreenNeonState extends State<CarnetScreenNeon> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SessionProvider>(
        builder: (context, session, child) {
          if (session.carnet == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          // AQUÍ VA EL DISEÑO DEL GANADOR
          return _buildNeonDesign(session.carnet!);
        },
      ),
    );
  }

  Widget _buildNeonDesign(CarnetModel carnet) {
    // Implementación del diseño ganador
    return Container(
      // Tu diseño aquí...
    );
  }
}
```

### 2. Registrar el Diseño en el Selector

**Archivo:** `lib/screens/carnet_selector_screen.dart`

```dart
class CarnetSelectorScreen extends StatelessWidget {
  const CarnetSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    
    switch (session.carnetDesign) {
      case 'modern':
        return const CarnetScreenNew();
      case 'neon':  // ← AGREGAR NUEVO CASO
        return const CarnetScreenNeon();
      case 'wallet':
      default:
        return const CarnetScreen();
    }
  }
}
```

### 3. Agregar Opción en el Selector de Diseños

**Archivo:** Ambos `carnet_screen.dart` y `carnet_screen_new.dart`

Buscar el método `_mostrarSelectorDiseno` y agregar:

```dart
// Opción: Diseño Neon
_buildDisenoOption(
  context: context,
  titulo: 'Neon Futurista',
  descripcion: 'Diseño con efectos de neón y animaciones',
  icono: Icons.flash_on_outlined,
  valor: 'neon',  // ← ID único del diseño
  seleccionado: session.carnetDesign == 'neon',
  onTap: () async {
    await session.cambiarDiseno('neon');
    Navigator.pop(context);
  },
),
```

### 4. Actualizar Provider (si es necesario)

Si agregas más de 2-3 diseños, actualiza la validación en:

**Archivo:** `lib/providers/session_provider.dart`

```dart
Future<void> cambiarDiseno(String nuevoDiseno) async {
  // Validar diseños disponibles
  final disenosValidos = ['wallet', 'modern', 'neon', 'minimalista'];
  
  if (!disenosValidos.contains(nuevoDiseno)) {
    print('⚠️ Diseño no válido: $nuevoDiseno');
    return;
  }
  
  // ... resto del código
}
```

## 📊 Información Disponible del Carnet

Todos los diseños tienen acceso a través de `CarnetModel`:

### Datos Personales
- `nombreCompleto` - Nombre del estudiante
- `matricula` - Matrícula única
- `correo` - Email institucional
- `edad` - Edad del estudiante
- `sexo` - Sexo biológico
- `categoria` - Alumno/Académico/Administrativo
- `programa` - Programa académico

### Información Médica
- `tipoSangre` - Tipo de sangre
- `enfermedadCronica` - Enfermedades crónicas
- `alergias` - Alergias médicas
- `discapacidad` / `tipoDiscapacidad` - Información de discapacidad
- `donante` - Si es donador de órganos

### Seguro Médico
- `unidadMedica` - IMSS, ISSSTE, otro
- `numeroAfiliacion` - Número de afiliación
- `usoSeguroUniversitario` - Si usa seguro universitario

### Contacto de Emergencia
- `emergenciaContacto` - Nombre del contacto
- `emergenciaTelefono` - Teléfono de emergencia

### Expediente
- `expedienteNotas` - Notas adicionales del expediente

## 🎨 Requisitos de Diseño

### Obligatorios
1. **Responsive:** Funcionar en móviles y escritorio (usar `MediaQuery`)
2. **Accesibilidad:** Contraste adecuado, tamaño de fuente legible
3. **Colores UAGro:** Incluir el rojo institucional `#8B1538`
4. **QR Code:** Debe incluir código QR con `matricula`
5. **Menú:** Botón para cambiar diseño y cerrar sesión

### Recomendados
1. **Animaciones:** Usar `AnimationController` para transiciones suaves
2. **Gradientes:** Aprovechar los colores institucionales
3. **Iconografía:** Usar Material Icons coherentemente
4. **Sombras:** Para dar profundidad (no más de 3 niveles)
5. **Bordes redondeados:** Mantener consistencia (12-20px)

### Evitar
- ❌ Ocultar información médica importante
- ❌ Usar colores que dificulten la lectura
- ❌ Animaciones excesivas que distraigan
- ❌ Dependencias externas no aprobadas
- ❌ Diseños que no escalen bien

## 🔧 Herramientas Útiles

### Widgets Recomendados
```dart
// Gradientes
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF8B1538), Color(0xFFC41E3A)],
    ),
  ),
)

// Sombras
BoxShadow(
  color: Colors.black.withOpacity(0.15),
  blurRadius: 20,
  offset: Offset(0, 10),
)

// Animaciones
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
)

// QR Code
QrImageView(
  data: 'SAL-${carnet.matricula}',
  version: QrVersions.auto,
  size: 200,
)
```

### Paleta de Colores UAGro
```dart
// Colores principales
const Color primaryRed = Color(0xFF8B1538);
const Color accentBlue = Color(0xFF1565C0);

// Colores de soporte
const Color lightGray = Color(0xFFf8f9fa);
const Color darkGray = Color(0xFF333333);
const Color successGreen = Color(0xFF4CAF50);
const Color warningYellow = Color(0xFFFFC107);
const Color errorRed = Color(0xFFD32F2F);
```

## 🧪 Pruebas

Antes de integrar, verifica:

1. **Compilación:** `flutter build web --release`
2. **Responsive:**
   - Móvil: 360x640
   - Tablet: 768x1024  
   - Desktop: 1920x1080
3. **Rendimiento:** Sin lag en animaciones
4. **Datos:** Probar con diferentes longitudes de texto

## 📝 Documentación del Diseño

Cada diseño ganador debe incluir un comentario al inicio:

```dart
// 🏥 CARNET DIGITAL UAGRO - DISEÑO [NOMBRE]
// 
// Diseñador: [Nombre del ganador]
// Fecha del concurso: [DD/MM/AAAA]
// Descripción: [Breve descripción del concepto]
// 
// Características:
// - [Característica 1]
// - [Característica 2]
// - [Característica 3]
```

## 🚀 Deployment

Una vez integrado y probado:

```bash
# 1. Compilar
flutter build web --release

# 2. Commit
git add .
git commit -m "Agregar diseño ganador: [Nombre]"

# 3. Deploy
git push origin main
```

GitHub Actions desplegará automáticamente a producción.

## 📞 Soporte Técnico

Para dudas durante la integración:
- Revisar diseños existentes: `carnet_screen.dart` y `carnet_screen_new.dart`
- Consultar documentación Flutter: https://flutter.dev
- Verificar funcionamiento del selector en el carnet desplegado

---

**¡Listos para recibir diseños creativos de los estudiantes! 🎨🏆**
