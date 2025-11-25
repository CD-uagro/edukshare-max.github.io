# 🧪 PRUEBA DE SINCRONIZACIÓN COSMOS DB

## ✅ Cambios Realizados

**Backend modificado** (`carnet_alumnos_nodes/routes/alebrije.js`):
- ✅ Endpoint POST ahora acepta objeto completo del alebrije
- ✅ Endpoint PUT ahora acepta objeto completo del alebrije  
- ✅ Si el alebrije ya existe en POST, automáticamente hace UPDATE
- ✅ Desplegado en Render (auto-deploy activado)

**Estado del despliegue:**
- Backend: En proceso de despliegue en Render (~2-3 minutos)
- Frontend: Corriendo en http://localhost:3000

---

## 🔬 Cómo Probar

### Paso 1: Esperar despliegue del backend
Render tarda ~2-3 minutos en desplegar. Espera a que esté listo:
- URL: https://carnet-alumnos-nodes.onrender.com
- Verificar: https://carnet-alumnos-nodes.onrender.com/health

### Paso 2: Iniciar sesión
1. Abre: http://localhost:3000
2. Ingresa credenciales de prueba:
   - Usuario: `juan.perez@uagro.mx`
   - Contraseña: `15662`
3. Ve a la pantalla de Alebrije (icono del guardián)

### Paso 3: Renombrar tu alebrije
1. En la pantalla del alebrije, click en el título (nombre actual + ícono de lápiz)
2. Ingresa un nuevo nombre (ej: "Xóchitl", "Cuauhtémoc", "Luna")
3. Guarda el cambio
4. **IMPORTANTE:** Abre la consola del navegador (F12) y busca estos mensajes:

```
🔄 Intentando sincronizar con Cosmos DB...
✅ Alebrije creado en Cosmos DB
   - Nombre: [tu nombre]
   - Matrícula: 15662
   - Especie: [especie de tu alebrije]
```

O si ya existía:

```
🔄 Intentando sincronizar con Cosmos DB...
✅ Alebrije actualizado en Cosmos DB
   - Nombre: [tu nombre]
   - Nivel: 1
```

### Paso 4: Verificar en Azure Portal
1. Ve al Azure Portal: https://portal.azure.com
2. Busca tu recurso de Cosmos DB
3. Ve a "Data Explorer"
4. Navega a: **SASU → alebrijes_estudiantes**
5. Ejecuta esta consulta:

```sql
SELECT * FROM c WHERE c.matricula = "15662"
```

6. **Deberías ver un documento con:**
   - `id`: UUID del alebrije
   - `matricula`: "15662"
   - `nombre`: El nombre que ingresaste
   - `dna`: Objeto completo con genes del alebrije
   - `estado`: Hambre, felicidad, salud, energía
   - `nivelEvolucion`: 1
   - `puntosExperiencia`: 0
   - `historialEvoluciones`: Array con la evolución inicial
   - `createdAt`: Timestamp
   - `updatedAt`: Timestamp

---

## 🔍 Qué buscar en la consola del navegador

### Logs exitosos (lo que quieres ver):
```
🔄 Intentando sincronizar con Cosmos DB...
🔗 Verificando si alebrije existe en backend...
✅ Alebrije creado en Cosmos DB
   - Nombre: Xóchitl
   - Matrícula: 15662
   - Especie: colibri
```

### Logs de error (si algo falla):
```
❌ Error al sincronizar con backend
⚠️ Cosmos DB no disponible, datos guardados solo en localStorage
```

---

## 🐛 Si no aparece en Cosmos DB

**Verifica:**

1. **Backend desplegado correctamente:**
   - URL: https://carnet-alumnos-nodes.onrender.com/health
   - Debe responder: `{"status": "ok"}`

2. **Consola del navegador:**
   - Abre DevTools (F12) → Console
   - Busca mensajes de error en rojo
   - Copia y pega cualquier error que veas

3. **Network tab:**
   - DevTools → Network
   - Filtra por "alebrije"
   - Busca request a POST /me/alebrije o PUT /me/alebrije
   - Verifica que el Status Code sea 200 o 201
   - Revisa la respuesta (Response)

4. **Token válido:**
   - DevTools → Application → Local Storage
   - Verifica que exista `auth_token`
   - Si no existe, cierra sesión e inicia sesión de nuevo

---

## 📊 Datos esperados en Cosmos DB

El documento guardado debe tener esta estructura:

```json
{
  "id": "abc123-uuid",
  "matricula": "15662",
  "nombre": "Xóchitl",
  "dna": {
    "especieBase": "colibri",
    "genes": {
      "color1": "#E91E63",
      "color2": "#9C27B0",
      "color3": "#3F51B5",
      "patron": "galaxia",
      "tamaño": 1.2,
      "forma": "compacto",
      "energia": "brillante",
      "personalidad": "curioso"
    },
    "mutaciones": [],
    "generacion": 1
  },
  "estado": {
    "hambre": 100,
    "felicidad": 100,
    "salud": 100,
    "energia": 100
  },
  "nivelEvolucion": 1,
  "puntosExperiencia": 0,
  "historialEvoluciones": [
    {
      "nivel": 1,
      "timestamp": "2025-11-25T07:00:00.000Z",
      "dna": { ...mismo dna... }
    }
  ],
  "capsulasAplicadas": [],
  "interacciones": {
    "totalAlimentaciones": 0,
    "totalJuegos": 0,
    "totalCuraciones": 0,
    "totalDescansos": 0,
    "ultimaInteraccion": null
  },
  "createdAt": "2025-11-25T07:00:00.000Z",
  "updatedAt": "2025-11-25T07:00:00.000Z"
}
```

---

## ✅ Criterio de éxito

La prueba es **exitosa** si:
1. ✅ Puedes renombrar tu alebrije
2. ✅ La consola muestra "✅ Alebrije creado/actualizado en Cosmos DB"
3. ✅ El documento aparece en Azure Portal en el contenedor `alebrijes_estudiantes`
4. ✅ El documento tiene la matrícula correcta ("15662")
5. ✅ El documento tiene el nombre que ingresaste
6. ✅ El documento contiene toda la estructura completa del alebrije

---

## 🚀 Próximos pasos después de la prueba exitosa

Una vez que confirmes que funciona:
1. Desplegar el frontend a GitHub Pages con `.\deploy.ps1`
2. Verificar que funciona en producción
3. Probar con otros usuarios de prueba
4. Listo para uso real ✨
