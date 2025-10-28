# Carnet Digital UAGro - AI Coding Guide

## Architecture Overview

This is a **Flutter Web + Node.js** health card management system for Universidad Autónoma de Guerrero (UAGro). The app displays digital student health cards, medical appointments, health promotions, and vaccination records.

### System Components

```
Flutter Web (localhost:3000 dev, GitHub Pages prod)
    ↓ HTTPS REST API
Node.js Backend (Render: carnet-alumnos-nodes.onrender.com)
    ↓ Azure SDK
Azure Cosmos DB (NoSQL)
```

**Frontend:** `lib/` - Flutter web app with Provider state management  
**Backend:** `carnet_alumnos_nodes/` - Express.js API with JWT auth  
**Deployment:** Frontend on GitHub Pages, Backend on Render with auto-deploy

## Critical Developer Workflows

### Local Development

**Frontend (Flutter):**
```powershell
flutter build web --release
cd build\web
python -m http.server 3000
# Access at http://localhost:3000
```

**Backend (Node.js):**
```powershell
cd carnet_alumnos_nodes
npm install
npm run dev  # Requires .env with COSMOS_* variables
```

### Deployment

- **Frontend:** Automatic via GitHub Actions on push to `main`. Uses `deploy.ps1` for manual deployment.
- **Backend:** Automatic via Render on push. Watch for cold starts (60s).

### Testing Auth Flow
Test credentials: `juan.perez@uagro.mx` / `15662`  
Endpoint: `POST /auth/login` returns JWT stored in `SharedPreferences` (7-day cache)

## Project-Specific Conventions

### State Management Pattern
**Always use Provider pattern** - `SessionProvider` is the single source of truth:
- `lib/providers/session_provider.dart` manages auth, carnet, citas, promociones
- **Never** call `ApiService` directly from screens - always through Provider methods
- Use `Consumer<SessionProvider>` or `context.watch<SessionProvider>()` in widgets

### API Service Design
`lib/services/api_service.dart` implements **retry with exponential backoff**:
- 3 retries max for all operations
- Timeouts: 35s login (handles Render cold start), 20s normal, 8s health check
- **All methods are static** - no instantiation needed

### Error Handling Pattern
Specific error types in `SessionProvider`:
```dart
_setError('User message', 'ERROR_TYPE');
// Types: NETWORK, CREDENTIALS, SERVER, TOKEN_INVALID, CONNECTION
```

Display errors using `session.error` and `session.errorType` in UI.

### Data Filtering Logic (Cosmos DB)

**Promociones (Health Promotions):** Multi-level filtering in both backend and frontend:

**Backend Query** (`carnet_alumnos_nodes/config/database.js:findPromocionesByMatricula()`):
- `destinatario="general"` + `autorizado=true` → All users
- `destinatario="alumno"` + `matricula="XXXX"` → Specific student (NO authorization required)
- `destinatario="alumno"` + empty `matricula` + `autorizado=true` → All students
- **Time filter**: Only shows promotions from last 7 days (based on `createdAt`)

**Frontend Filter** (`lib/providers/session_provider.dart:loadPromociones()`):
- Additional client-side validation for security
- Same logic as backend
- Double-checks 7-day expiration

**CRITICAL RULES:**
- Individual promotions (specific matricula) do NOT require `autorizado: true`
- General promotions and bulk student promotions MUST have `autorizado: true`
- **All promotions expire after 7 days** from `createdAt` date

## Integration Points

### Flutter ↔ Backend Communication
**Base URL:** `lib/services/api_service.dart:14`
```dart
static const String baseUrl = 'https://carnet-alumnos-nodes.onrender.com';
```

**JWT Flow:**
1. Login → Receive token → Store in `SharedPreferences` with key `'auth_token'`
2. All requests include header: `Authorization: Bearer {token}`
3. Token auto-restored on app launch via `SessionRestoreScreen`

### Backend ↔ Cosmos DB
**Connection:** `carnet_alumnos_nodes/config/database.js:connectToCosmosDB()`  
**Containers:**
- `carnets_id` - Student health cards
- `cita_id` - Medical appointments  
- `promociones_salud` - Health promotions
- `usuarios_matricula` - User credentials

**Environment Variables Required:**
- `COSMOS_ENDPOINT`, `COSMOS_KEY`, `COSMOS_DATABASE`
- Set in Render dashboard, NOT committed to git

### Routes Structure
Backend routes in `carnet_alumnos_nodes/routes/`:
- `auth.js` - `/auth/login` (public)
- `carnet.js` - `/me/carnet` (authenticated)
- `promociones.js` - `/me/promociones`, `/me/promociones/:id/click` (authenticated)
- `citas.js` - `/me/citas` (authenticated)

Auth middleware: `carnet_alumnos_nodes/middleware/auth.js:authenticateToken`

## UI/UX Patterns

### Screen Design Philosophy
Two carnet designs coexist:
- `carnet_screen.dart` - Wallet-style collapsible card with promotions carousel
- `carnet_screen_new.dart` - Health card design (modern gradient, centered)

**Active screen:** Defined in `main.dart` routes (`'/carnet'` vs `'/carnet-new'`)

### Responsive Design
Mobile detection: `MediaQuery.of(context).size.width < 600`  
Reduce animations on mobile: `MediaQuery.of(context).disableAnimations`

### UAGro Brand Colors
Theme in `lib/theme/uagro_theme.dart`:
- Primary: `Color(0xFF8B1538)` (UAGro red)
- Accent: `Color(0xFF1565C0)` (Blue for health)

## Common Debugging Scenarios

### "Promociones no aparecen"
**Check:**
1. For **individual promotions** (specific `matricula`): No authorization needed, just verify `matricula` matches
2. For **general/bulk promotions**: Cosmos DB document MUST have `"autorizado": true`
3. `destinatario` field must be `"general"` or `"alumno"`
4. Backend logs: `console.log` in `findPromocionesByMatricula()`
5. Frontend logs: `print` statements in `session_provider.dart:loadPromociones()`

**Authorization Logic:**
- Individual (with matricula) → Shows immediately, no authorization
- General/Bulk (without matricula) → Requires `autorizado: true`

### "Login fails with timeout"
**Cause:** Render cold start (60s)  
**Solution:** Already handled with 35s timeout + 3 retries. Show user friendly message.

### "Token inválido" error
**Check:**
1. Token expired? (Cosmos DB query may have failed silently)
2. Verify token in Chrome DevTools → Application → Local Storage
3. Backend logs for 401 responses

## Key Files Reference

**State Management:**
- `lib/providers/session_provider.dart` - Central state, auth, data loading

**API Layer:**
- `lib/services/api_service.dart` - All backend communication with retries

**Models:**
- `lib/models/carnet_model.dart` - Health card structure
- `lib/models/promocion_salud_model.dart` - Promotion with `autorizado` field

**Main Screens:**
- `lib/screens/login_screen.dart` - Auth entry point
- `lib/screens/carnet_screen.dart` - Primary wallet design
- `lib/screens/citas_screen.dart` - Medical appointments

**Backend Core:**
- `carnet_alumnos_nodes/index.js` - Express server setup, CORS, middleware
- `carnet_alumnos_nodes/config/database.js` - Cosmos DB queries and connection
- `carnet_alumnos_nodes/middleware/auth.js` - JWT verification

**Deployment:**
- `deploy.ps1` - PowerShell script for frontend deployment
- `.github/workflows/` - CI/CD (if exists)
- `DEPLOYMENT_EXITOSO.md` - Production verification checklist

## Documentation Files
Extensive markdown docs exist - reference them for specific features:
- `USAR_SISTEMA.md` - How to run the system
- `DIAGNOSTICO_ERROR_CARNET.md` - Common carnet loading issues
- `INTEGRACION_STATUS.md` - Backend integration details
- `DEPLOYMENT_EXITOSO.md` - Production deployment guide
