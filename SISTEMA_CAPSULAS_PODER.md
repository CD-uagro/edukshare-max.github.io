# 💊 Sistema de Cápsulas de Poder - Alebrije UAGro

## 🎯 Descripción

Sistema de recompensas gamificado que incentiva a los estudiantes a usar los servicios de salud universitarios. Cada visita médica o psicológica otorga una **Cápsula Virtual** con poderes especiales para su alebrije guardián.

## ✨ Características Principales

### 7 Tipos de Cápsulas

1. **💚 Cápsula de Vitalidad** (Salud)
   - Restaura +30 salud
   - Aumenta +10 energía
   - Ideal de: Consultas médicas

2. **💪 Cápsula de Poder** (Fuerza)
   - Aumenta +20 hambre
   - Multiplicador de XP: x1.5 a x3.5
   - Ideal de: Servicios generales

3. **🧠 Cápsula de Sabiduría** (Inteligencia)
   - Aumenta +15 felicidad
   - Multiplicador de XP: x2.0 a x6.0
   - Acelera evoluciones

4. **⚡ Cápsula de Agilidad** (Velocidad)
   - Aumenta +25 energía
   - Reduce decaimiento hasta 50%
   - Mantiene stats más tiempo

5. **✨ Cápsula de Alegría** (Carisma)
   - Aumenta +30 felicidad
   - Aumenta +10 hambre
   - Mejora aura visual

6. **🛡️ Cápsula de Protección** (Resilencia)
   - Aumenta +20 salud
   - Reduce decaimiento hasta 75%
   - Protege contra bajas críticas

7. **❤️ Cápsula Suprema** (Vitalidad)
   - Aumenta TODOS los stats +25
   - Multiplicador de XP: x1.75
   - Reduce decaimiento 15%
   - La más balanceada

### 4 Niveles de Rareza

| Rareza | Probabilidad | Duración | Multiplicador | Color |
|--------|--------------|----------|---------------|-------|
| 🔵 Común | 60% | 2 horas | x1.0 | Gris |
| 🟣 Rara | 30% | 6 horas | x1.5 | Azul |
| 🟡 Épica | 8% | 24 horas | x2.5 | Morado |
| 🟠 Legendaria | 2% | **PERMANENTE** | x5.0 | Dorado |

## 🎲 Sistema de Obtención

### Consulta Médica
```dart
onConsultaMedica() {
  // Efectos inmediatos
  +30 hambre
  +50 XP
  
  // Cápsula aleatoria
  Tipo preferido: Vitalidad, Poder, Protección
  Rareza: Según probabilidades
}
```

### Vacunación
```dart
onVacuna() {
  // Efectos inmediatos
  +40 salud
  +100 XP
  
  // Cápsula aleatoria
  Tipo preferido: Vitalidad, Protección, Sabiduría
  Rareza: Según probabilidades
}
```

### Consulta Psicológica
```dart
onConsultaPsicologica() {
  // Cápsula aleatoria
  Tipo preferido: Sabiduría, Agilidad, Alegría
  Rareza: Según probabilidades
}
```

## 💻 Implementación Técnica

### Modelo de Datos
```dart
class CapsulaPoder {
  final TipoCapsula tipo;
  final RarezaCapsula rareza;
  final String nombre;
  final String descripcion;
  final String emoji;
  
  // Efectos
  final int bonosSalud;
  final int bonosHambre;
  final int bonosFelicidad;
  final int bonosEnergia;
  final double multiplicadorExperiencia;
  final double reduccionDecaimiento;
  
  // Duración
  final Duration? duracion; // null = permanente
  final DateTime? activadaEn;
  final bool activa;
  
  // Origen
  final String origenServicio;
  final DateTime obtenidaEn;
}
```

### Generación Aleatoria
```dart
CapsulaPowerGenerator.generarCapsula('Consulta Médica')
// 1. Determina rareza según probabilidades
// 2. Asigna duración según rareza
// 3. Elige tipo basado en servicio
// 4. Calcula efectos × multiplicador de rareza
```

### Persistencia
- **localStorage**: `alebrije_capsulas` (array de cápsulas)
- **Backend**: POST `/me/alebrije/capsula` (registro de historial)
- **Limpieza automática**: Elimina expiradas al cargar

### Estados de Cápsula
1. **Pendiente**: Obtenida pero no aplicada
2. **Activa**: Aplicada y en efecto
3. **Expirada**: Duración terminada (se elimina)
4. **Permanente**: Nunca expira (legendarias)

## 🎨 UI/UX

### Panel de Cápsulas Pendientes
```
┌─────────────────────────────────────┐
│ 💊 Cápsulas de Poder     [2 activas]│
├─────────────────────────────────────┤
│ 🎁 Nuevas cápsulas obtenidas:       │
│                                     │
│ ┌───────────────────────────────┐  │
│ │ 💚 Cápsula de Vitalidad       │  │
│ │ [RARA] - 6 horas              │  │
│ │ Restaura y protege la salud   │  │
│ │ De: Consulta Médica           │  │
│ │                    [¡Aplicar!]│  │
│ └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Panel de Cápsulas Activas
```
┌─────────────────────────────────────┐
│ ✨ Efectos activos:                 │
│                                     │
│ 💪 Cápsula de Poder                │
│ ████████░░ 4h 23m restantes        │
│ ⭐ x2.0 XP  🍽️ +30                 │
│                                     │
│ 🛡️ Cápsula de Protección          │
│ ∞ PERMANENTE                        │
│ ❤️ +100  🔰 -30% decaimiento       │
└─────────────────────────────────────┘
```

### Animación de Aplicación
```dart
onAplicarCapsula() {
  1. Animación de partículas (sparkle)
  2. Mensaje del alebrije: "¡Siento el poder!"
  3. Actualización visual de stats
  4. Sonido de éxito (opcional)
  5. Mover de pendientes → activas
}
```

## 📊 Ejemplos de Efectos

### Caso 1: Estudiante recibe consulta médica
```
1. Usuario asiste a consulta médica
2. Sistema genera cápsula: "Cápsula de Vitalidad ÉPICA"
3. Cápsula va a pendientes (notificación)
4. Usuario abre alebrije screen
5. Ve panel: "🎁 Nueva cápsula obtenida"
6. Presiona [¡Aplicar!]
7. Efectos inmediatos:
   - Salud: 60 → 135 (+75 épica)
   - Energía: 50 → 75 (+25 épica)
8. Efecto activo por 24 horas
```

### Caso 2: Acumulación de cápsulas
```
Cápsulas activas simultáneas:
- Vitalidad Rara: +45 salud, +15 energía
- Poder Común: +20 hambre, x1.5 XP
- Agilidad Legendaria: +25 energía, -30% decaimiento (PERMANENTE)

Total acumulado:
- Salud: +45
- Hambre: +20
- Energía: +40
- Multiplicador XP: x1.5
- Reducción decaimiento: -30%
```

### Caso 3: Cápsula legendaria
```
¡CÁPSULA LEGENDARIA OBTENIDA!
🟠 Cápsula Suprema de Vitalidad

Efectos PERMANENTES:
- Todos los stats: +125
- Multiplicador XP: x3.75
- Reducción decaimiento: -75%
- Nunca expira

Rareza: 2% probabilidad (1 en 50 consultas)
```

## 🔗 Integración con Backend

### POST /me/alebrije/capsula
```json
Request:
{
  "capsula": {
    "id": "cap_1732506129000",
    "tipo": "salud",
    "rareza": "rara",
    "nombre": "Cápsula de Vitalidad",
    "emoji": "💚",
    "bonosSalud": 45,
    "bonosEnergia": 15,
    "duracion": 21600000,
    "multiplicadorExperiencia": 1.5
  },
  "servicioSalud": "Consulta Médica"
}

Response:
{
  "mensaje": "¡Cápsula obtenida!",
  "capsula": {
    "nombre": "Cápsula de Vitalidad",
    "rareza": "rara",
    "emoji": "💚"
  },
  "servicio": "Consulta Médica"
}
```

### GET /me/alebrije/capsulas/historial
```json
Response:
{
  "mensaje": "Historial de cápsulas",
  "matricula": "15662",
  "total": 15,
  "legendarias": 0,
  "epicas": 2,
  "raras": 5,
  "comunes": 8
}
```

## 🎮 Estrategia de Gamificación

### Incentivos Psicológicos
1. **Recompensa variable**: Rareza aleatoria mantiene interés
2. **FOMO**: Cápsulas legendarias crean emoción
3. **Colección**: Usuarios buscan todas las rarezas
4. **Progresión**: Cápsulas aceleran evolución del alebrije
5. **Impacto inmediato**: Efectos visibles al instante

### Bucle de Engagement
```
Consulta médica → Cápsula aleatoria → ¿Legendaria? 
     ↑                                       ↓
     └────────── Motivación para regresar ──┘
```

### Métricas de Éxito
- **Aumento de visitas médicas**: +30-50% esperado
- **Retención diaria**: +20% por efecto de cápsulas activas
- **Satisfacción**: Recompensa tangible por cuidar salud

## 🛠️ Mantenimiento

### Limpieza Automática
```dart
limpiarCapsulasExpiradas() {
  // Ejecutar al iniciar app
  // Elimina cápsulas con duración terminada
  // Mantiene permanentes
}
```

### Balanceo de Efectos
Si el sistema está muy roto:
```dart
// Reducir multiplicadores en CapsulaPowerGenerator
case RarezaCapsula.legendaria:
  return 3.0; // Antes: 5.0
```

### Debug
```dart
// Logs importantes
print('💊 Cápsula obtenida: ${nombre} [${rareza}]');
print('✨ Cápsula aplicada: ${nombre}');
print('🧹 ${count} cápsulas expiradas eliminadas');
print('⚡ Bonus de cápsulas: ${puntos} XP → ${puntosConBonus} XP');
```

## 📈 Roadmap Futuro

### Fase 2 (Opcional)
- [ ] Cápsulas con efectos visuales únicos (aura, brillo)
- [ ] Combos de cápsulas (efectos sinérgicos)
- [ ] Intercambio de cápsulas entre estudiantes
- [ ] Eventos especiales con cápsulas exclusivas
- [ ] Logros por colección de rarezas
- [ ] Estadísticas de cápsulas obtenidas

### Fase 3 (Avanzado)
- [ ] Crafteo: Combinar 3 comunes → 1 rara
- [ ] Mercado: Comprar cápsulas con puntos
- [ ] Misiones: Objetivos para ganar cápsulas
- [ ] Battle Pass: Sistema de temporada

---

## 🎉 Resultado Final

Un sistema completo de gamificación que:
1. ✅ Incentiva visitas a servicios de salud
2. ✅ Mantiene engagement con el alebrije
3. ✅ Proporciona recompensas tangibles
4. ✅ Es justo pero emocionante (RNG balanceado)
5. ✅ Persiste correctamente en localStorage
6. ✅ Se integra naturalmente con el sistema existente

**El alebrije ahora es una razón más para cuidar tu salud.** 💊✨
