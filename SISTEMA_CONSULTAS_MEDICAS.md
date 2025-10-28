# 📋 SISTEMA DE CONSULTAS MÉDICAS - RESUMEN DE IMPLEMENTACIÓN

## 🎯 Objetivo
Implementar una página en el carnet digital que muestre el historial de atención médica del estudiante, permitiéndole demostrar a sus profesores que asistió a consulta.

## ✅ Componentes Implementados

### 1. Backend - Base de Datos (database.js)
**Archivo**: `carnet_alumnos_nodes/config/database.js`

**Funcionalidades agregadas:**
- ✅ Configuración del contenedor `notas_medicas` en Cosmos DB
- ✅ Función `findNotasMedicasByMatricula(matricula)` para consultar notas médicas por matrícula
- ✅ Ordenamiento por fecha descendente (consultas más recientes primero)
- ✅ Limpieza de documentos Cosmos DB

**Código clave:**
```javascript
const notasContainerName = 'notas_medicas';
let notasContainer;

async function findNotasMedicasByMatricula(matricula) {
  const querySpec = {
    query: 'SELECT * FROM c WHERE c.matricula = @matricula ORDER BY c.fecha DESC',
    parameters: [{ name: '@matricula', value: matricula }]
  };
  const { resources } = await notasContainer.items.query(querySpec).fetchAll();
  return resources.map(cleanCosmosDocument);
}
```

### 2. Backend - API REST (consultas.js)
**Archivo**: `carnet_alumnos_nodes/routes/consultas.js`

**Endpoint implementado:**
- **GET** `/me/consultas` - Obtiene historial de consultas médicas del usuario autenticado

**Características:**
- ✅ Autenticación JWT requerida
- ✅ Obtiene información completa del carnet (nombre del alumno)
- ✅ Transforma notas médicas a formato de consulta
- ✅ Manejo robusto de errores
- ✅ Logs detallados para debugging

**Datos devueltos:**
```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "matricula": "20180001",
      "nombreCompleto": "Juan Pérez García",
      "fecha": "2025-10-15T10:30:00Z",
      "diagnostico": "Consulta médica general",
      "medico": "Dr. García López",
      "departamento": "Consultorio Médico",
      "observaciones": "...",
      "tipo": "Consulta general"
    }
  ],
  "total": 1
}
```

### 3. Backend - Registro de Rutas (index.js)
**Archivo**: `carnet_alumnos_nodes/index.js`

**Cambios:**
- ✅ Import de `routes/consultas.js`
- ✅ Registro de ruta: `app.use('/', consultasRoutes)`

### 4. Frontend - Modelo de Datos (consulta_model.dart)
**Archivo**: `lib/models/consulta_model.dart`

**Campos del modelo:**
- `id`: ID único de la consulta
- `matricula`: Matrícula del estudiante
- `nombreCompleto`: Nombre completo del estudiante
- `fecha`: Fecha y hora de la consulta
- `diagnostico`: Diagnóstico médico
- `medico`: Nombre del médico
- `departamento`: Departamento o servicio médico
- `observaciones`: Observaciones adicionales
- `tipo`: Tipo de consulta

**Características:**
- ✅ Factory method `fromJson()` para parsear respuestas del API
- ✅ Manejo robusto de fechas (parse de strings, timestamps, etc.)
- ✅ Valores por defecto para campos opcionales
- ✅ Método `toJson()` para serialización

### 5. Frontend - Servicio API (api_service.dart)
**Archivo**: `lib/services/api_service.dart`

**Métodos agregados:**
- `getConsultas(String token)` - Método público con reintentos
- `_performGetConsultas(String token)` - Implementación del request

**Características:**
- ✅ Reintentos automáticos con backoff exponencial
- ✅ Timeout de 20 segundos
- ✅ Manejo de errores de autenticación (401/403)
- ✅ Logs detallados para debugging
- ✅ Retorna lista vacía en caso de error (no crashea)

### 6. Frontend - Pantalla de Consultas (consultas_screen.dart)
**Archivo**: `lib/screens/consultas_screen.dart`

**Características principales:**
- ✅ **AppBar** con título "Mis Consultas Médicas" en color UAGro
- ✅ **Pull-to-refresh** para recargar consultas
- ✅ **Estados manejados**:
  - Loading (spinner)
  - Error con botón de reintentar
  - Vacío con mensaje informativo
  - Lista de consultas

**Diseño de cards de consulta:**
- 🏥 Icono médico con fondo UAGro
- 📅 Fecha y hora de la consulta
- 🏷️ Badge del tipo de consulta
- 👤 Nombre completo del estudiante
- 🎫 Matrícula
- 📋 Diagnóstico médico
- 👨‍⚕️ Nombre del médico

**Interactividad:**
- ✅ Tap en card abre diálogo con detalles completos
- ✅ Botón de actualizar en estado vacío
- ✅ Diseño responsive y profesional

### 7. Funcionalidad Extra - Limpiar Citas Pasadas
**Archivo**: `lib/screens/citas_screen.dart`

**Características agregadas:**
- ✅ Botón en AppBar con icono `delete_sweep`
- ✅ Tooltip "Limpiar citas pasadas"
- ✅ Diálogo de confirmación con contador de citas a eliminar
- ✅ Filtrado de citas pasadas vs. futuras
- ✅ SnackBar de confirmación con opción de recargar
- ✅ Actualización automática después de limpiar

**Método implementado:**
```dart
void _limpiarCitasPasadas(BuildContext context) {
  // Filtra citas que ya pasaron
  // Muestra diálogo de confirmación
  // Recarga la lista desde el servidor
}
```

### 8. Navegación - Integración en Menú Principal
**Archivo**: `lib/screens/carnet_screen.dart`

**Puntos de acceso agregados:**

**A) AppBar - Botón rápido:**
- ✅ Icono `assignment_outlined` en AppBar
- ✅ Tooltip "Mis Consultas"
- ✅ Navega directamente a ConsultasScreen

**B) Drawer/Menú lateral:**
- ✅ Nueva opción "Mis Consultas" bajo sección Salud
- ✅ Icono azul con background redondeado
- ✅ Subtítulo "Historial de atención médica"
- ✅ Cierra drawer automáticamente al navegar

## 🗄️ Estructura de Datos - Cosmos DB

### Contenedor: `notas_medicas`
**Partition Key**: `/matricula`

**Esquema sugerido de documentos:**
```json
{
  "id": "nota_20180001_20251015_1030",
  "matricula": "20180001",
  "fecha": "2025-10-15T10:30:00Z",
  "diagnostico": "Infección respiratoria aguda",
  "nota": "Paciente presenta síntomas de gripe...",
  "medico": "Dr. María García López",
  "doctor": "Dr. García",
  "departamento": "Consultorio Médico General",
  "servicio": "Medicina General",
  "observaciones": "Reposo 3 días",
  "tratamiento": "Antibiótico cada 8 horas",
  "tipo": "Consulta general",
  "createdAt": "2025-10-15T10:30:00Z"
}
```

## 📱 Flujo de Usuario

1. **Estudiante abre el carnet digital**
2. **Accede a "Mis Consultas"** (desde AppBar o menú lateral)
3. **Ve su historial** ordenado por fecha (más recientes primero)
4. **Tap en consulta** para ver detalles completos
5. **Puede mostrar a profesor** que asistió a consulta médica con:
   - ✅ Nombre completo
   - ✅ Matrícula
   - ✅ Diagnóstico
   - ✅ Fecha y hora
   - ✅ Médico que atendió

## 🔧 Configuración Requerida

### Variables de Entorno (Backend)
```env
COSMOS_CONTAINER_NOTAS=notas_medicas
```

### Dependencias (Frontend)
Ya incluidas en `pubspec.yaml`:
- `provider` - Estado
- `http` - Requests HTTP
- `intl` - Formateo de fechas

## 🚀 Deployment

### Backend
```bash
cd carnet_alumnos_nodes
git add .
git commit -m "feat: Sistema de consultas médicas con historial de atención"
git push origin main
```

Render detectará cambios y desplegará automáticamente.

### Frontend
```bash
cd "Carnet_digital _alumnos"
flutter build web
git add .
git commit -m "feat: Página de consultas médicas + botón limpiar citas pasadas"
git push origin main
```

GitHub Pages se actualizará automáticamente en `app.carnetdigital.space`.

## 📊 Testing

### 1. Probar Backend
```bash
# Con token válido
curl -H "Authorization: Bearer <TOKEN>" \
  https://carnet-alumnos-nodes.onrender.com/me/consultas
```

### 2. Probar Frontend
1. Login en `app.carnetdigital.space`
2. Click en icono de consultas en AppBar
3. Verificar que carga lista de consultas
4. Tap en consulta para ver detalles

### 3. Probar Limpiar Citas
1. Ir a "Salud" → "Citas Médicas"
2. Click en icono de escoba en AppBar
3. Confirmar limpieza
4. Verificar que se actualizan las citas

## ✨ Mejoras Futuras Sugeridas

1. **Filtros de consultas**:
   - Por rango de fechas
   - Por tipo de consulta
   - Por médico

2. **Exportar consulta como PDF**:
   - Generar comprobante imprimible
   - Con código QR de verificación

3. **Estadísticas de salud**:
   - Gráfica de consultas por mes
   - Tipos de diagnósticos más frecuentes

4. **Notificaciones**:
   - Push notification cuando se registra nueva consulta

5. **Backend - Eliminar citas pasadas**:
   - Endpoint DELETE para limpiar citas del servidor
   - No solo del estado local

## 📝 Notas Importantes

- ✅ El contenedor `notas_medicas` debe existir en Cosmos DB
- ✅ Las notas deben tener campo `matricula` como partition key
- ✅ El sistema es compatible con múltiples formatos de fecha
- ✅ Manejo robusto de errores en toda la cadena
- ✅ UI/UX consistente con diseño UAGro

## 👨‍💻 Autor
**Dr. Gilberto Valenzuela Herrera**  
Dirección de Innovación en Salud Universitaria  
Centro de Investigación Transdisciplinar  
Universidad Autónoma de Guerrero

---
**Fecha de implementación**: 17 de Octubre de 2025  
**Versión**: 1.0.0
