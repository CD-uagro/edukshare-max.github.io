# SASU 2.6.0 - Centro de Atencion Universitaria MVP

## Objetivo de la fase

Implementar el MVP visual para estudiantes del Centro de Atencion Universitaria sin tocar produccion, sin deploy y sin agregar funciones fuera de alcance.

Alcance de esta fase:

- Opcion de menu: `Centro de Atencion`.
- Ruta nueva: `/atencion`.
- Pantalla nueva: `CentroAtencionScreen`.
- Vista `Mis Tickets`.
- Vista `Crear Ticket`.
- Consumo de backend existente:
  - `GET /tickets/my`
  - `POST /tickets`

Fuera de alcance por ahora:

- Conversacion.
- Mensajes.
- Videollamadas.
- Adjuntos.
- Notificaciones.
- WebSockets.
- Push.

## Arquitectura propuesta

La integracion debe seguir el patron actual de la app:

- `main.dart` registra rutas nombradas en `MaterialApp.routes`.
- `SessionProvider` concentra estado autenticado, token, carnet y cargas de datos.
- `ApiService` concentra HTTP, headers Bearer, timeouts y parseo de respuestas.
- Las pantallas consumen `SessionProvider` con `provider`.
- Los modelos viven en `lib/models`.

El Centro de Atencion debe agregarse como modulo estudiante autenticado, no como flujo publico. La pantalla debe depender de:

- `session.token` para autenticar peticiones.
- `session.carnet` para obtener matricula y datos del alumno.
- Nuevos metodos de `SessionProvider` para cargar y crear tickets.
- Nuevos metodos de `ApiService` para `GET /tickets/my` y `POST /tickets`.

## Estado actual relevante

### Sesion

Archivo: `lib/providers/session_provider.dart`

Hallazgos:

- `SessionProvider` ya expone `token`, `carnet`, `isLoading` y `error`.
- El carnet en sesion contiene la matricula y datos basicos del alumno.
- Hay patron existente para colecciones autenticadas:
  - `_citas`, `_consultas`, `_promociones`, `_vacunas`.
  - timestamps de cache como `_lastConsultasFetch`.
  - metodos publicos como `loadCitas()` y `loadConsultas()`.
- El login y restore cargan datos secundarios en `_loadSecondaryDataInBackground`.

Decision:

- Agregar estado especifico de tickets en `SessionProvider`, pero no cargarlo obligatoriamente durante login en esta fase. Para MVP visual conviene cargar tickets cuando se abre `/atencion`, evitando mas latencia en inicio de sesion.

### API

Archivo: `lib/services/api_service.dart`

Hallazgos:

- `baseUrl` apunta al backend de produccion actual: `https://carnet-alumnos-nodes.onrender.com`.
- Las peticiones autenticadas usan:
  - `Authorization: Bearer $token`
  - `Content-Type: application/json`
- Los GET existentes aceptan respuestas estilo `{ success: true, data: [...] }`.
- Algunos metodos devuelven lista vacia en errores no criticos y propagan `INVALID_TOKEN` cuando aplica.
- Para POST/DELETE existentes se usa `Map<String, dynamic>` con `success`, `message`, `statusCode` y `errorType`.

Decision:

- Implementar `ApiService.getMyTickets(String token)`.
- Implementar `ApiService.createTicket(String token, CrearTicketRequest request)`.
- Mantener `normalTimeout`.
- Manejar `401/403` como `INVALID_TOKEN`.
- Aceptar de forma defensiva respuestas con wrapper `{ success, data }` y, si backend devuelve lista directa en GET, mapearla tambien.

### Pantalla principal y menu

Archivos:

- `lib/main.dart`
- `lib/screens/carnet_selector_screen.dart`
- `lib/screens/carnet_screen_new.dart`

Hallazgos:

- La ruta `/carnet` carga `CarnetSelectorScreen`.
- `CarnetSelectorScreen` devuelve `CarnetScreenNew`.
- El menu activo esta en `CarnetScreenNew`, no en el drawer antiguo de `carnet_screen.dart`.
- En desktop existe `_buildSidebar`, con items como `Inicio`, `Mi Carnet`, `Vacunas`, `Citas y Consultas`, `Promociones`, `Ajustes`, `Ayuda`.
- En mobile existe `_showMobileMenu`, con `ListTile` equivalentes.
- La barra inferior mobile (`_buildBottomNav`) ya tiene cinco destinos; para MVP no conviene forzar ahi el nuevo modulo si rompe el layout.

Decision:

- Agregar `Centro de Atencion` en:
  - `_buildSidebar` de `CarnetScreenNew`.
  - `_showMobileMenu` de `CarnetScreenNew`.
- Navegar con `Navigator.pushNamed(context, '/atencion')`.
- No agregarlo inicialmente a `_buildBottomNav` para evitar saturar la navegacion inferior mobile. El acceso mobile queda en el menu superior/bottom sheet.
- Opcional visual dentro del dashboard: agregar una tarjeta o panel simple en la seccion `Ayuda` o junto a `Citas y Consultas` solo si se decide en la fase de implementacion. Para este MVP, el requisito minimo queda cubierto con menu + ruta.

## Ruta nueva

Archivo a modificar: `lib/main.dart`

Agregar import:

```dart
import 'package:carnet_digital_uagro/screens/centro_atencion_screen.dart';
```

Agregar ruta:

```dart
'/atencion': (context) => const CentroAtencionScreen(),
```

La ruta debe ser accesible solo desde sesion autenticada. Si se abre sin `session.token` o sin `session.carnet`, la pantalla debe mostrar estado de sesion invalida y ofrecer volver a login o carnet.

## Pantalla nueva

Archivo nuevo:

- `lib/screens/centro_atencion_screen.dart`

Responsabilidades:

- Mostrar titulo `Centro de Atencion Universitaria`.
- Usar tabs o selector local para dos vistas:
  - `Mis Tickets`
  - `Crear Ticket`
- En `initState`, disparar `session.loadTickets(force: true)` despues del primer frame.
- Consumir `session.tickets`, `session.isLoading` o, preferiblemente, estados especificos de tickets.
- Mostrar empty state cuando no haya tickets.
- Permitir `RefreshIndicator` en `Mis Tickets`.
- Al crear ticket exitosamente:
  - limpiar formulario.
  - volver a `Mis Tickets`.
  - recargar lista.
  - mostrar `SnackBar` de confirmacion.

No debe incluir:

- Chat del ticket.
- Timeline de mensajes.
- Adjuntos.
- Estado en tiempo real.
- Botones de llamada o videollamada.

## Modelos nuevos requeridos

### `TicketModel`

Archivo nuevo:

- `lib/models/ticket_model.dart`

Campos recomendados para el MVP:

```dart
class TicketModel {
  final String id;
  final String matricula;
  final String categoria;
  final String prioridad;
  final String titulo;
  final String descripcion;
  final String estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

Notas:

- `estado` debe tener fallback local, por ejemplo `abierto` o `pendiente`, segun lo devuelva backend.
- `fromJson` debe tolerar variantes comunes:
  - `createdAt` / `created_at`
  - `updatedAt` / `updated_at`
  - `titulo` / `title`
  - `descripcion` / `description`
  - `categoria` / `category`
  - `prioridad` / `priority`
- `toJson` puede servir para debug, no es obligatorio para GET.

### `CrearTicketRequest`

Puede vivir en el mismo archivo `ticket_model.dart` para mantener el MVP simple.

Campos:

```dart
class CrearTicketRequest {
  final String categoria;
  final String prioridad;
  final String titulo;
  final String descripcion;
  final String matricula;
  final String nombreCompleto;
  final String correo;
}
```

`toJson` recomendado:

```dart
{
  'categoria': categoria,
  'prioridad': prioridad,
  'titulo': titulo,
  'descripcion': descripcion,
  'matricula': matricula,
  'nombreCompleto': nombreCompleto,
  'correo': correo,
}
```

Si el backend deriva identidad exclusivamente desde JWT, mantener los datos de alumno disponibles en el request local pero ajustar `toJson` al contrato confirmado del backend. La fuente debe seguir siendo `session.carnet`, nunca campos manuales del formulario.

## Categorias y prioridades

Categorias permitidas:

- `psicologia`
- `medicina`
- `nutricion`
- `vacunacion`
- `promocion_salud`
- `soporte_carnet`
- `administrativo`
- `otro`

Prioridades permitidas:

- `baja`
- `media`
- `alta`
- `urgente`

Recomendacion UI:

- Mostrar etiquetas humanas, pero enviar valores canonicos.
- Categoria default: `soporte_carnet` o `otro`.
- Prioridad default: `media`.
- Validar titulo y descripcion no vacios antes del POST.

## Servicios

Archivo a modificar:

- `lib/services/api_service.dart`

### GET `/tickets/my`

Metodo propuesto:

```dart
static Future<List<TicketModel>> getMyTickets(String token)
```

Flujo:

1. `GET Uri.parse('$baseUrl/tickets/my')`.
2. Headers Bearer + JSON.
3. Timeout `normalTimeout`.
4. Si `200`:
   - parsear `data['data']` si existe.
   - aceptar lista directa si el backend responde `[...]`.
   - convertir con `TicketModel.fromJson`.
5. Si `401/403`:
   - lanzar `Exception('INVALID_TOKEN: Token invalido o expirado')`.
6. Si `404`:
   - devolver `[]`.
7. Otros errores:
   - devolver `[]` para no romper la UI del MVP.

### POST `/tickets`

Metodo propuesto:

```dart
static Future<Map<String, dynamic>> createTicket(
  String token,
  CrearTicketRequest request,
)
```

Flujo:

1. `POST Uri.parse('$baseUrl/tickets')`.
2. Headers Bearer + JSON.
3. Body `jsonEncode(request.toJson())`.
4. Timeout `normalTimeout`.
5. Si `200` o `201`:
   - devolver `success: true`.
   - incluir `data` si backend lo envia.
6. Si `400`:
   - devolver `success: false`, `errorType: VALIDATION`.
7. Si `401/403`:
   - lanzar `INVALID_TOKEN`.
8. Si `500` u otro:
   - devolver `success: false`, `errorType: SERVER_ERROR`.

## SessionProvider

Archivo a modificar:

- `lib/providers/session_provider.dart`

Nuevos imports:

```dart
import 'package:carnet_digital_uagro/models/ticket_model.dart';
```

Estado nuevo:

```dart
List<TicketModel> _tickets = [];
DateTime? _lastTicketsFetch;
bool _isTicketsLoading = false;
String? _ticketsError;
```

Getters:

```dart
List<TicketModel> get tickets => _tickets;
bool get isTicketsLoading => _isTicketsLoading;
String? get ticketsError => _ticketsError;
```

Metodos:

```dart
Future<void> loadTickets({bool force = false})
Future<Map<String, dynamic>> createTicket({
  required String categoria,
  required String prioridad,
  required String titulo,
  required String descripcion,
})
```

Reglas:

- Validar token antes de llamar API.
- Validar `carnet != null` antes de crear ticket.
- Usar `carnet.matricula`, `carnet.nombreCompleto` y `carnet.correo`.
- En `INVALID_TOKEN`, limpiar cache y hacer `logout()`, siguiendo el patron existente.
- En `logout()` y `logoutCompleto()`, limpiar `_tickets`, `_lastTicketsFetch`, `_isTicketsLoading` y `_ticketsError`.
- No agregar tickets a `_loadSecondaryDataInBackground` en el primer MVP para no cargar datos no visibles al login.

## Archivos a modificar

Obligatorios:

- `lib/main.dart`
  - Importar pantalla.
  - Registrar `/atencion`.

- `lib/screens/carnet_screen_new.dart`
  - Agregar item `Centro de Atencion` en desktop sidebar.
  - Agregar item `Centro de Atencion` en menu mobile.
  - Navegar con `Navigator.pushNamed(context, '/atencion')`.

- `lib/services/api_service.dart`
  - Importar `ticket_model.dart`.
  - Agregar `getMyTickets`.
  - Agregar `createTicket`.

- `lib/providers/session_provider.dart`
  - Importar `ticket_model.dart`.
  - Agregar estado/getters/metodos de tickets.
  - Limpiar estado al logout.

Nuevos:

- `lib/models/ticket_model.dart`
- `lib/screens/centro_atencion_screen.dart`

Opcionales:

- `test/` para pruebas de parseo del modelo si se decide validar sin tocar backend.

No modificar en esta fase:

- Backend.
- Deploy.
- `deploy.ps1`.
- Rutas existentes.
- Flujo de login.
- Produccion.

## Plan por commits

### Commit 1 - Modelo de tickets

Mensaje sugerido:

```text
feat: add ticket models
```

Archivos:

- `lib/models/ticket_model.dart`

Contenido:

- `TicketModel`.
- `CrearTicketRequest`.
- Parseo defensivo de fechas y aliases de campos.

### Commit 2 - Servicio API de tickets

Mensaje sugerido:

```text
feat: add ticket api methods
```

Archivos:

- `lib/services/api_service.dart`

Contenido:

- Import del modelo.
- `getMyTickets`.
- `createTicket`.
- Manejo de errores consistente con el servicio actual.

### Commit 3 - Estado de tickets en sesion

Mensaje sugerido:

```text
feat: add ticket session state
```

Archivos:

- `lib/providers/session_provider.dart`

Contenido:

- Estado, getters y carga de tickets.
- Creacion de tickets usando datos del carnet.
- Limpieza en logout.

### Commit 4 - Pantalla Centro de Atencion

Mensaje sugerido:

```text
feat: add student support center screen
```

Archivos:

- `lib/screens/centro_atencion_screen.dart`

Contenido:

- AppBar.
- Tabs/vistas `Mis Tickets` y `Crear Ticket`.
- Lista, empty state, refresh.
- Formulario minimo.

### Commit 5 - Ruta y menu

Mensaje sugerido:

```text
feat: add support center route
```

Archivos:

- `lib/main.dart`
- `lib/screens/carnet_screen_new.dart`

Contenido:

- Ruta `/atencion`.
- Opcion `Centro de Atencion` en sidebar y menu mobile.

## Respuestas directas a las decisiones solicitadas

### 1. Donde agregar Centro de Atencion

- Ruta: `lib/main.dart`, dentro de `MaterialApp.routes`, como `/atencion`.
- Menu desktop: `lib/screens/carnet_screen_new.dart`, en `_buildSidebar`.
- Menu mobile: `lib/screens/carnet_screen_new.dart`, en `_showMobileMenu`.
- No tocar inicialmente el drawer viejo de `carnet_screen.dart`, porque la app activa usa `CarnetSelectorScreen -> CarnetScreenNew`.

### 2. Como consumir GET `/tickets/my`

- Crear `ApiService.getMyTickets(token)`.
- Llamarlo desde `SessionProvider.loadTickets(force: true)`.
- Disparar `loadTickets` desde `CentroAtencionScreen.initState`.
- Renderizar `session.tickets` en la vista `Mis Tickets`.

### 3. Como consumir POST `/tickets`

- Crear `ApiService.createTicket(token, request)`.
- Construir `CrearTicketRequest` desde:
  - formulario: categoria, prioridad, titulo, descripcion.
  - sesion: matricula, nombre completo, correo.
- Exponer `SessionProvider.createTicket(...)`.
- Al exito, recargar tickets y volver a `Mis Tickets`.

### 4. Que modelos nuevos se requieren

- `TicketModel` para lista y detalle basico.
- `CrearTicketRequest` para payload de creacion.

No se requieren todavia modelos de mensajes, adjuntos, videollamadas, notificaciones ni conversaciones.
