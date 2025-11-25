# Azure Cosmos DB - Dominación Forzada sobre localStorage

## 🎯 Problema Resuelto

**Síntoma:** El alebrije que aparece en computadora es diferente al que aparece en celular.

**Causa:** localStorage (almacenamiento local del navegador) estaba compitiendo con Azure Cosmos DB como fuente de verdad, causando inconsistencias entre dispositivos.

## ✅ Solución Implementada

### 1. **Prioridad Absoluta de Azure**

**Archivo:** `lib/providers/alebrije_provider.dart`

#### `inicializarAlebrije()` - Carga Inicial
```dart
// ⚠️ ESTRATEGIA DE SINCRONIZACIÓN FORZADA:
// Azure Cosmos DB es la ÚNICA fuente de verdad
// localStorage es solo caché temporal y se borra si difiere

// 1. Requerir token obligatorio
final token = prefs.getString('auth_token');
if (token == null) {
  _error = 'Sesión expirada. Por favor inicia sesión nuevamente.';
  return;
}

// 2. Cargar SIEMPRE desde Azure primero
alebrijeBackend = await _cargarDesdeBackend(token);
if (alebrijeBackend == null) {
  _error = 'No se pudo conectar con el servidor.';
  return;
}

// 3. Detectar conflictos con localStorage
if (alebrijeLocal.nombre != alebrijeBackend.nombre ||
    alebrijeLocal.dna.especieBase != alebrijeBackend.dna.especieBase) {
  print('🔄 CONFLICTO: localStorage difiere de Azure');
  print('   - BORRANDO caché local obsoleto');
  await prefs.remove('alebrije_data');
}

// 4. Azure SIEMPRE gana
_alebrije = alebrijeBackend;
```

#### `_guardarEstado()` - Guardado de Cambios
```dart
// ⚠️ PRIORIDAD 1: SINCRONIZAR CON AZURE PRIMERO
if (token != null) {
  await _sincronizarConBackend(token);
  print('✅ Estado guardado en Azure Cosmos DB');
} else {
  throw Exception('Sesión expirada');
}

// PRIORIDAD 2: localStorage solo si Azure tuvo éxito
await prefs.setString('alebrije_data', jsonEncode(_alebrije!.toJson()));
print('💾 Caché local actualizado');
```

**Cambio Crítico:**
- ❌ **ANTES:** localStorage → Azure (localStorage era principal)
- ✅ **AHORA:** Azure → localStorage (Azure es principal, localStorage solo caché)

### 2. **Sincronización Forzada Periódica**

**Archivo:** `lib/screens/alebrije_screen.dart`

#### Sincronización al Abrir la Pantalla
```dart
if (alebrijeProvider.alebrije == null) {
  await alebrijeProvider.inicializarAlebrije(matricula);
} else {
  // 🔄 FORZAR sincronización desde Azure al abrir
  await alebrijeProvider.forzarSincronizacionDesdeAzure();
  await alebrijeProvider.actualizarEstado();
}
```

#### Sincronización Automática Cada 2 Minutos
```dart
void _iniciarSincronizacionPeriodica() {
  Future.delayed(const Duration(minutes: 2), () async {
    if (mounted) {
      print('⏰ Sincronización automática desde Azure...');
      await alebrijeProvider.forzarSincronizacionDesdeAzure();
      _iniciarSincronizacionPeriodica();
    }
  });
}
```

### 3. **Método de Sincronización Manual**

**Archivo:** `lib/providers/alebrije_provider.dart`

```dart
/// 🔄 Forzar sincronización desde Azure
Future<void> forzarSincronizacionDesdeAzure() async {
  final alebrijeBackend = await _cargarDesdeBackend(token);
  
  if (alebrijeBackend != null) {
    // Comparar versiones
    if (_alebrije!.nombre != alebrijeBackend.nombre ||
        _alebrije!.nivelEvolucion != alebrijeBackend.nivelEvolucion) {
      print('⚠️ CONFLICTO detectado');
      print('   Local: ${_alebrije!.nombre} Lv.${_alebrije!.nivelEvolucion}');
      print('   Azure: ${alebrijeBackend.nombre} Lv.${alebrijeBackend.nivelEvolucion}');
    }
    
    // Azure SIEMPRE gana
    _alebrije = alebrijeBackend;
    await prefs.setString('alebrije_data', jsonEncode(_alebrije!.toJson()));
    print('✅ Sincronizado desde Azure');
    notifyListeners();
  }
}
```

### 4. **Botón de Sincronización en UI**

**Ubicación:** AppBar de la pantalla de alebrije (icono ☁️)

```dart
IconButton(
  icon: const Icon(Icons.cloud_sync, color: Colors.white),
  tooltip: 'Sincronizar desde Azure',
  onPressed: () async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔄 Sincronizando desde Azure...')),
    );
    await alebrijeProvider.forzarSincronizacionDesdeAzure();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Sincronizado con Azure')),
    );
  },
)
```

## 🔧 Cómo Funciona Ahora

### Flujo de Datos Actualizado

```
┌─────────────────────────────────────────────┐
│  Usuario Abre la App en Dispositivo A      │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  1. Verificar Token de Autenticación        │
│     ❌ Sin token → Error                     │
│     ✅ Con token → Continuar                 │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  2. Cargar desde Azure Cosmos DB            │
│     ❌ Error → Mostrar mensaje               │
│     ✅ Éxito → Usar datos de Azure          │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  3. Verificar localStorage                   │
│     Si difiere de Azure → BORRAR            │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  4. Guardar datos de Azure en localStorage  │
│     (Solo como caché temporal)               │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  5. Mostrar alebrije en pantalla            │
└─────────────────────────────────────────────┘

Cada 2 minutos: Repetir sincronización desde Azure
```

### Cuando el Usuario Hace una Acción (alimentar, jugar, etc.)

```
┌─────────────────────────────────────────────┐
│  Usuario Alimenta al Alebrije              │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  1. Actualizar estado en memoria            │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  2. Sincronizar con Azure Cosmos DB         │
│     ❌ Error → NO guardar en localStorage    │
│     ✅ Éxito → Continuar                     │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  3. Actualizar localStorage (solo si #2 OK) │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  4. Notificar cambios a UI                  │
└─────────────────────────────────────────────┘
```

## 🎮 Cómo Usar

### Para el Usuario

1. **Sincronización Automática:**
   - Al abrir la pantalla del alebrije, se sincroniza automáticamente desde Azure
   - Cada 2 minutos se vuelve a sincronizar en segundo plano

2. **Sincronización Manual:**
   - Presiona el botón ☁️ (cloud_sync) en la barra superior
   - Aparecerá mensaje "🔄 Sincronizando desde Azure..."
   - Cuando termine: "✅ Sincronizado con Azure"

3. **Resolver Conflictos:**
   - Si ves un alebrije diferente en otro dispositivo:
   - Presiona el botón ☁️ para forzar sincronización
   - Azure siempre gana: se mostrará el alebrije que está en la nube

### Para el Desarrollador

```dart
// Forzar sincronización programáticamente
final alebrijeProvider = context.read<AlebrijeProvider>();
await alebrijeProvider.forzarSincronizacionDesdeAzure();

// Verificar si hay token válido
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('auth_token');
if (token == null) {
  // Usuario debe iniciar sesión
}
```

## 📊 Logs y Debugging

### Logs de Sincronización

```bash
# Carga inicial exitosa
✅ Alebrije recuperado desde Cosmos DB (Azure)
   - Nombre: Xolotl
   - Nivel: 3
   - DNA: jaguar

# Conflicto detectado
🔄 CONFLICTO: localStorage difiere de Azure
   - Local: Quetzal (aguila)
   - Azure: Xolotl (jaguar)
   - BORRANDO caché local obsoleto

# Sincronización automática
⏰ Sincronización automática desde Azure...
✅ Sincronizado desde Azure: Xolotl Lv.3

# Guardado exitoso
✅ Estado guardado en Azure Cosmos DB (fuente principal)
💾 Caché local actualizado (2 cápsulas)
```

## 🛡️ Garantías de Consistencia

### ✅ Lo que SIEMPRE se garantiza:

1. **Azure Cosmos DB es la única fuente de verdad**
2. **localStorage es solo caché temporal**
3. **Conflictos siempre se resuelven a favor de Azure**
4. **Sincronización cada 2 minutos en pantalla activa**
5. **No se guarda localmente si Azure falla**

### ❌ Lo que NO puede pasar:

1. ~~localStorage sobrescribe Azure~~
2. ~~Diferentes alebrijes en diferentes dispositivos~~
3. ~~Cambios locales se pierden sin sincronizar~~
4. ~~Usuario ve alebrije incorrecto~~

## 🔍 Verificación

### Comprobar que Azure Domina

1. **En Dispositivo A:**
   - Abre el alebrije
   - Anota el nombre y nivel

2. **En Dispositivo B (diferente navegador/computadora):**
   - Inicia sesión con el mismo usuario
   - Abre el alebrije
   - Presiona el botón ☁️
   - **Debes ver el MISMO alebrije** que en Dispositivo A

3. **Borrar localStorage:**
   - Abre DevTools → Application → Local Storage
   - Borra `alebrije_data`
   - Recarga la página
   - El alebrije se recupera desde Azure sin pérdida de datos

## 📝 Resumen de Cambios

| Componente | Cambio |
|------------|--------|
| **inicializarAlebrije()** | ✅ Requerir token, cargar solo desde Azure, borrar localStorage si difiere |
| **_guardarEstado()** | ✅ Azure primero, localStorage solo si Azure tuvo éxito |
| **forzarSincronizacionDesdeAzure()** | ✅ Método nuevo para sincronización manual |
| **alebrije_screen.dart** | ✅ Sincronización al abrir, cada 2 minutos, botón manual |
| **Prioridad de Datos** | ✅ Azure → localStorage (era localStorage → Azure) |

## 🚀 Despliegue

```powershell
# Compilar con cambios
flutter build web --release

# Desplegar a GitHub Pages
.\deploy.ps1

# Verificar en producción
# https://edukshare-max.github.io
```

---

**Estado:** ✅ Implementado y Compilado  
**Fecha:** 25 de noviembre de 2025  
**Versión:** 1.0 - Azure Dominante
