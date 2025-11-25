// 🌐 SERVICIO API SASU - OPTIMIZADO Y ROBUSTO
// Con reintentos automáticos, timeouts inteligentes y manejo de errores profesional

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:carnet_digital_uagro/models/carnet_model.dart';
import 'package:carnet_digital_uagro/models/cita_model.dart';
import 'package:carnet_digital_uagro/models/promocion_salud_model.dart';
import 'package:carnet_digital_uagro/models/vacuna_model.dart';
import 'package:carnet_digital_uagro/models/consulta_model.dart';

class ApiService {
  // 🌐 BACKEND PRODUCCIÓN EN RENDER
  static const String baseUrl = 'https://carnet-alumnos-nodes.onrender.com';
  // static const String baseUrl = 'http://localhost:3000'; // Para pruebas locales
  
  // ⚙️ CONFIGURACIÓN DE REINTENTOS Y TIMEOUTS
  static const int maxRetries = 3;
  static const Duration shortTimeout = Duration(seconds: 8);  // Health check
  static const Duration normalTimeout = Duration(seconds: 20); // Operaciones normales
  static const Duration longTimeout = Duration(seconds: 60);   // Login con cold start (Render puede tardar 50-60s)
  
  // 🔄 MÉTODO AUXILIAR: REINTENTO CON BACKOFF EXPONENCIAL
  static Future<T?> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxAttempts = maxRetries,
    String operationName = 'operación',
    bool isLogin = false, // Flag especial para login con cold start
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        print('🔄 Intento $attempt/$maxAttempts para $operationName');
        final result = await operation();
        print('✅ $operationName exitosa en intento $attempt');
        return result;
      } catch (e) {
        final isLastAttempt = attempt == maxAttempts;
        final errorMsg = e.toString();
        
        // No reintentar si son credenciales incorrectas
        if (errorMsg.contains('CREDENTIALS_ERROR')) {
          print('🚫 Credenciales incorrectas, no se reintentará');
          rethrow;
        }
        
        // Manejo especial del error 429 (rate limiting)
        if (errorMsg.contains('429')) {
          print('⏸️ Rate limit alcanzado (429) - Esperando 3 segundos antes de reintentar...');
          await Future.delayed(const Duration(seconds: 3));
          if (!isLastAttempt) continue;
        }
        
        if (isLastAttempt) {
          print('❌ $operationName falló después de $maxAttempts intentos: $e');
          rethrow;
        }
        
        // Backoff más largo para login (cold start de Render puede tardar mucho)
        final waitTime = isLogin 
            ? Duration(seconds: 8 * attempt) // 8s, 16s, 24s para login (total: 60+8+16=84s máx)
            : Duration(seconds: 2 * attempt); // 2s, 4s, 8s para operaciones normales
        
        final timeoutMsg = errorMsg.contains('TIMEOUT') ? '⏱️ Timeout - Render despertando' : '🔌 Error de conexión';
        print('⏳ Reintentando en ${waitTime.inSeconds}s... ($timeoutMsg)');
        await Future.delayed(waitTime);
      }
    }
    return null;
  }
  
  // 🏥 HEALTH CHECK: Verificar si el backend está activo
  static Future<Map<String, dynamic>> checkBackendHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      print('🏥 Verificando salud del backend: $url');
      
      final startTime = DateTime.now();
      final response = await http.get(url).timeout(shortTimeout);
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      
      final isHealthy = response.statusCode == 200;
      
      return {
        'healthy': isHealthy,
        'statusCode': response.statusCode,
        'responseTime': responseTime,
        'message': isHealthy 
          ? '✅ Backend activo (${responseTime}ms)' 
          : '⚠️ Backend responde con error ${response.statusCode}',
      };
    } catch (e) {
      print('❌ Health check falló: $e');
      
      // Detectar tipo de error
      final isColdStart = e.toString().contains('TimeoutException');
      
      return {
        'healthy': false,
        'statusCode': 0,
        'responseTime': -1,
        'message': isColdStart 
          ? '❄️ Backend iniciando (cold start Render)...' 
          : '❌ Backend no disponible: $e',
        'coldStart': isColdStart,
      };
    }
  }
  
  // 🔑 LOGIN CON JWT - VERSIÓN ROBUSTA CON REINTENTOS (MATRÍCULA + CONTRASEÑA)
  static Future<Map<String, dynamic>?> login(String matricula, String password) async {
    return await _retryWithBackoff<Map<String, dynamic>>(
      () => _performLogin(matricula, password),
      operationName: 'login',
      isLogin: true, // Usar tiempos de espera más largos para cold start de Render
    );
  }
  
  // 🔐 IMPLEMENTACIÓN INTERNA DE LOGIN
  static Future<Map<String, dynamic>> _performLogin(String matricula, String password) async {
    final startTime = DateTime.now();
    
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final body = {
        'matricula': matricula,
        'password': password,
      };
      
      print('🔍 LOGIN REQUEST: $url');
      print('🎓 Matrícula: $matricula');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        longTimeout,
        onTimeout: () {
          throw Exception('TIMEOUT: El servidor tardó más de ${longTimeout.inSeconds}s en responder. Posible cold start de Render.');
        },
      );
      
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      print('📊 LOGIN RESPONSE: ${response.statusCode} (${responseTime}ms)');
      
      // Detectar si fue cold start (respuesta lenta)
      final wasColdStart = responseTime > 10000;
      if (wasColdStart) {
        print('❄️ Cold start detectado: ${responseTime}ms');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['token'] != null) {
          print('✅ Login exitoso');
          return {
            'success': true,
            'token': data['token'],
            'matricula': data['matricula'] ?? matricula,
            'responseTime': responseTime,
            'coldStart': wasColdStart,
          };
        } else {
          throw Exception('INVALID_RESPONSE: Respuesta del servidor sin token válido');
        }
      } else if (response.statusCode == 401) {
        // Credenciales incorrectas - NO reintentar
        throw Exception('CREDENTIALS_ERROR: ${response.body}');
      } else if (response.statusCode == 500) {
        // Error del servidor - SÍ reintentar
        throw Exception('SERVER_ERROR: Error interno del servidor (${response.statusCode})');
      } else {
        throw Exception('HTTP_ERROR: Status code ${response.statusCode}');
      }
      
    } catch (e) {
      final errorType = _classifyError(e);
      print('❌ LOGIN ERROR: $errorType - $e');
      
      // Si es error de credenciales, no reintentar
      if (errorType == 'CREDENTIALS_ERROR') {
        return {
          'success': false,
          'errorType': 'CREDENTIALS',
          'message': 'Credenciales incorrectas. Verifica tu email y matrícula.',
        };
      }
      
      // Para otros errores, propagar para que el retry maneje
      rethrow;
    }
  }
  
  // 🏷️ CLASIFICAR TIPO DE ERROR
  static String _classifyError(dynamic error) {
    final errorStr = error.toString();
    
    if (errorStr.contains('CREDENTIALS_ERROR')) return 'CREDENTIALS_ERROR';
    if (errorStr.contains('TIMEOUT')) return 'TIMEOUT_ERROR';
    if (errorStr.contains('SocketException') || errorStr.contains('NetworkException')) return 'NETWORK_ERROR';
    if (errorStr.contains('SERVER_ERROR')) return 'SERVER_ERROR';
    if (errorStr.contains('FormatException')) return 'PARSE_ERROR';
    
    return 'UNKNOWN_ERROR';
  }
  
  // 📝 REGISTRO CON VALIDACIÓN DE CARNET EXISTENTE - CON REINTENTOS
  static Future<Map<String, dynamic>?> register(String email, String matricula, String password) async {
    return await _retryWithBackoff<Map<String, dynamic>>(
      () => _performRegister(email, matricula, password),
      operationName: 'registro',
    );
  }
  
  // 📝 IMPLEMENTACIÓN INTERNA DE REGISTRO
  static Future<Map<String, dynamic>> _performRegister(String email, String matricula, String password) async {
    final startTime = DateTime.now();
    
    try {
      final url = Uri.parse('$baseUrl/auth/register');
      final body = {
        'correo': email,
        'matricula': matricula,
        'password': password,
      };
      
      print('🔍 REGISTER REQUEST: $url');
      print('📧 Email: $email | 🎓 Matrícula: $matricula');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(
        normalTimeout,
        onTimeout: () {
          throw Exception('TIMEOUT: El servidor tardó más de ${normalTimeout.inSeconds}s en responder.');
        },
      );
      
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      print('📊 REGISTER RESPONSE: ${response.statusCode} (${responseTime}ms)');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          print('✅ Registro exitoso');
          return {
            'success': true,
            'message': data['message'] ?? 'Cuenta creada exitosamente',
            'responseTime': responseTime,
          };
        } else {
          throw Exception('INVALID_RESPONSE: Respuesta del servidor sin éxito confirmado');
        }
      } else if (response.statusCode == 404) {
        // Carnet no encontrado o correo/matrícula no coinciden
        final data = jsonDecode(response.body);
        final errorType = data['errorType'] ?? 'NOT_FOUND';
        
        return {
          'success': false,
          'errorType': errorType,
          'message': data['message'] ?? 'Carnet no encontrado',
        };
      } else if (response.statusCode == 409) {
        // Usuario ya existe
        return {
          'success': false,
          'errorType': 'ALREADY_EXISTS',
          'message': 'Ya existe una cuenta con esta matrícula',
        };
      } else if (response.statusCode == 400) {
        // Error de validación
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'errorType': 'VALIDATION',
          'message': data['message'] ?? 'Datos inválidos',
        };
      } else if (response.statusCode == 500) {
        // Error del servidor - SÍ reintentar
        throw Exception('SERVER_ERROR: Error interno del servidor (${response.statusCode})');
      } else {
        throw Exception('HTTP_ERROR: Status code ${response.statusCode}');
      }
      
    } catch (e) {
      final errorType = _classifyError(e);
      print('❌ REGISTER ERROR: $errorType - $e');
      
      // Propagar para que el retry maneje
      rethrow;
    }
  }
  
  // 🎓 OBTENER DATOS DEL CARNET CON JWT - CON REINTENTOS
  static Future<CarnetModel?> getMyCarnet(String token) async {
    return await _retryWithBackoff<CarnetModel>(
      () => _performGetCarnet(token),
      operationName: 'obtener carnet',
    );
  }
  
  // 🔐 IMPLEMENTACIÓN INTERNA DE GET CARNET
  static Future<CarnetModel> _performGetCarnet(String token) async {
    try {
      final url = Uri.parse('$baseUrl/me/carnet');
      
      print('🔍 GET CARNET REQUEST: $url');
      print('🔑 TOKEN: ${token.substring(0, min(20, token.length))}...');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        normalTimeout,
        onTimeout: () {
          throw Exception('TIMEOUT: Timeout obteniendo carnet');
        },
      );
      
      print('📊 CARNET RESPONSE: ${response.statusCode}');
      
      // Manejo específico del error 429 (rate limiting)
      if (response.statusCode == 429) {
        print('⏸️ Error 429: Rate limit alcanzado - Demasiadas peticiones');
        throw Exception('HTTP_ERROR_429: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📋 RESPONSE DATA: ${data}');
        
        if (data['success'] == true && data['data'] != null) {
          print('✅ Carnet obtenido exitosamente');
          return CarnetModel.fromJson(data['data']);
        } else {
          throw Exception('INVALID_RESPONSE: Respuesta sin datos de carnet válidos');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('🚫 Token inválido detectado - limpiando sesión');
        throw Exception('INVALID_TOKEN: Token inválido o expirado');
      } else if (response.statusCode == 404) {
        throw Exception('NOT_FOUND: Carnet no encontrado');
      } else if (response.statusCode == 500) {
        throw Exception('SERVER_ERROR: Error interno del servidor');
      } else {
        throw Exception('HTTP_ERROR: Status code ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ GET CARNET ERROR: $e');
      rethrow; // Propagar para que el retry maneje
    }
  }
  
  // 🏥 OBTENER CITAS MÉDICAS - ENDPOINT REAL SASU
  static Future<List<CitaModel>> getCitas(String token) async {
    try {
      final url = Uri.parse('$baseUrl/me/citas'); // ✅ ENDPOINT CORRECTO
      
      print('🔍 GET CITAS REQUEST: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('📊 CITAS RESPONSE: ${response.statusCode}');
      print('📋 RESPONSE BODY: ${response.body}');
      
      if (response.statusCode == 429) {
        print('⏸️ Error 429: Rate limit alcanzado en citas');
        throw Exception('HTTP_ERROR_429: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> citasJson = data['data'];
          return citasJson.map((json) => CitaModel.fromJson(json)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('❌ GET CITAS ERROR: $e');
      return [];
    }
  }

  // 🗑️ ELIMINAR CITAS PASADAS
  static Future<Map<String, dynamic>> deleteCitasPasadas(String token) async {
    try {
      final url = Uri.parse('$baseUrl/me/citas/pasadas');
      
      print('🔍 DELETE CITAS PASADAS REQUEST: $url');
      
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        normalTimeout,
        onTimeout: () {
          throw Exception('TIMEOUT: Timeout eliminando citas pasadas');
        },
      );
      
      print('📊 DELETE CITAS RESPONSE: ${response.statusCode}');
      print('📋 RESPONSE BODY: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'eliminadas': data['eliminadas'] ?? 0,
          'message': data['message'] ?? 'Citas eliminadas correctamente',
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          'success': false,
          'errorType': 'INVALID_TOKEN',
          'message': 'Token inválido o expirado',
        };
      } else {
        return {
          'success': false,
          'errorType': 'SERVER_ERROR',
          'message': 'Error eliminando citas pasadas',
        };
      }
      
    } catch (e) {
      print('❌ DELETE CITAS PASADAS ERROR: $e');
      return {
        'success': false,
        'errorType': 'NETWORK',
        'message': 'Error de conexión: $e',
      };
    }
  }

  // 🏥 OBTENER PROMOCIONES DE SALUD ACTIVAS - BACKEND REAL
  static Future<List<PromocionSaludModel>> getPromocionesSalud(String token, String matricula) async {
    try {
      // Endpoint del nuevo backend de promociones SASU
      final url = Uri.parse('$baseUrl/me/promociones');
      
      print('🔍 PROMOCIONES REQUEST: $url');
      print('🎓 MATRICULA: $matricula');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('📊 PROMOCIONES RESPONSE: ${response.statusCode}');
      print('📋 RESPONSE BODY: ${response.body}');
      
      if (response.statusCode == 429) {
        print('⏸️ Error 429: Rate limit alcanzado en promociones');
        throw Exception('HTTP_ERROR_429: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Verificar formato de respuesta del backend
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> promocionesJson = responseData['data'];
          
          print('📦 ${promocionesJson.length} promociones recibidas del backend');
          
          // Convertir JSON a modelos
          final promociones = <PromocionSaludModel>[];
          
          for (var json in promocionesJson) {
            try {
              // Mapear formato del backend SASU al modelo existente
              final promocionData = {
                'id': json['id']?.toString() ?? '',
                'matricula': matricula,
                'link': json['link'] ?? '',
                'departamento': json['departamento'] ?? 'SASU',
                'categoria': json['categoria'] ?? 'General',
                'programa': json['titulo'] ?? json['programa'] ?? 'Sin título',
                'destinatario': 'Alumno',
                'autorizado': true,
                'createdAt': json['fecha_publicacion'] ?? json['created_at'] ?? DateTime.now().toIso8601String(),
                'createdBy': json['departamento'] ?? 'Sistema SASU',
                // Campos adicionales para compatibilidad
                'titulo': json['titulo'] ?? '',
                'descripcion': json['descripcion'] ?? '',
                'resumen': json['resumen'] ?? json['descripcion']?.substring(0, 150) ?? '',
                'imagen_url': json['imagen_url'],
                'fecha_inicio': json['fecha_inicio'],
                'fecha_fin': json['fecha_fin'],
                'destacado': json['destacado'] ?? false,
                'urgente': json['urgente'] ?? false,
                'prioridad': json['prioridad'] ?? 5,
                'es_especifica': json['matricula_target'] != null,
              };
              
              final promocion = PromocionSaludModel.fromJson(promocionData);
              promociones.add(promocion);
              
              print('   ✅ ${promocion.titulo} (${promocion.categoria})');
              
            } catch (e) {
              print('   ❌ Error parseando promoción: $e');
              print('   📄 JSON: $json');
            }
          }
          
          print('✅ PROMOCIONES FINALES: ${promociones.length}');
          return promociones;
          
        } else {
          print('❌ Formato de respuesta inválido: ${responseData}');
        }
        
      } else if (response.statusCode == 404) {
        print('❌ Endpoint de promociones no encontrado (404)');
        print('💡 Asegúrate de que el backend SASU está ejecutándose');
      } else if (response.statusCode == 401) {
        print('❌ No autorizado (401) - token inválido');
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
      }
      
      return [];
    } catch (e) {
      print('❌ GET PROMOCIONES ERROR: $e');
      return [];
    }
  }

  // � REGISTRAR CLICK EN PROMOCIÓN
  static Future<bool> registrarClickPromocion(String token, String promocionId) async {
    try {
      final url = Uri.parse('$baseUrl/me/promociones/$promocionId/click');
      
      print('🔍 REGISTRAR CLICK: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('📊 CLICK RESPONSE: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Click registrado: ${data['message']}');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ REGISTRAR CLICK ERROR: $e');
      return false;
    }
  }

  // 🗑️ MARCAR PROMOCIÓN COMO VISTA (DEPRECADO)
  static Future<bool> marcarPromocionVista(String token, String promocionId) async {
    // Este método está deprecado, usar registrarClickPromocion en su lugar
    return registrarClickPromocion(token, promocionId);
  }

  // 💉 OBTENER VACUNAS DEL ESTUDIANTE - CON REINTENTOS
  static Future<List<VacunaModel>> getVacunas(String token) async {
    final result = await _retryWithBackoff<List<VacunaModel>>(
      () => _performGetVacunas(token),
      maxAttempts: maxRetries,
      operationName: 'obtener vacunas',
    );
    return result ?? [];
  }

  // 💉 IMPLEMENTACIÓN DE OBTENCIÓN DE VACUNAS
  static Future<List<VacunaModel>> _performGetVacunas(String token) async {
    try {
      final url = Uri.parse('$baseUrl/me/vacunas');
      
      print('🔍 GET VACUNAS REQUEST: $url');
      print('🔑 TOKEN: ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        normalTimeout,
        onTimeout: () {
          throw Exception('TIMEOUT: Timeout obteniendo vacunas');
        },
      );
      
      print('📊 VACUNAS RESPONSE: ${response.statusCode}');
      print('📋 RESPONSE BODY: ${response.body}');
      
      if (response.statusCode == 429) {
        print('⏸️ Error 429: Rate limit alcanzado en vacunas');
        throw Exception('HTTP_ERROR_429: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> vacunasJson = data['data'];
          final vacunas = vacunasJson.map((json) => VacunaModel.fromJson(json)).toList();
          print('✅ VACUNAS OBTENIDAS: ${vacunas.length} registros');
          return vacunas;
        } else {
          print('⚠️ RESPUESTA SIN DATOS DE VACUNAS');
          return [];
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('🚫 Token inválido detectado - limpiando sesión');
        throw Exception('INVALID_TOKEN: Token inválido o expirado');
      } else if (response.statusCode == 404) {
        print('📭 No hay vacunas registradas');
        return [];
      } else {
        print('❌ ERROR HTTP: ${response.statusCode}');
        return [];
      }
      
    } catch (e) {
      print('❌ GET VACUNAS ERROR: $e');
      
      // Si es error de token, propagarlo
      if (e.toString().contains('INVALID_TOKEN')) {
        rethrow;
      }
      
      // Para otros errores, retornar lista vacía
      return [];
    }
  }
  // 📋 OBTENER CONSULTAS DE ATENCIÓN DEL ESTUDIANTE - CON REINTENTOS
  static Future<List<ConsultaModel>> getConsultas(String token) async {
    final result = await _retryWithBackoff<List<ConsultaModel>>(
      () => _performGetConsultas(token),
      maxAttempts: maxRetries,
      operationName: 'obtener consultas de atención',
    );
    return result ?? [];
  }

  // 📋 IMPLEMENTACIÓN DE OBTENCIÓN DE CONSULTAS DE ATENCIÓN
  static Future<List<ConsultaModel>> _performGetConsultas(String token) async {
    try {
      final url = Uri.parse('$baseUrl/me/consultas');
      
      print('🔍 GET CONSULTAS REQUEST: $url');
      print('🔑 TOKEN: ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        normalTimeout,
        onTimeout: () {
          throw Exception('TIMEOUT: Timeout obteniendo consultas de atención');
        },
      );
      
      print('📊 CONSULTAS RESPONSE: ${response.statusCode}');
      print('📋 RESPONSE BODY: ${response.body}');
      
      if (response.statusCode == 429) {
        print('⏸️ Error 429: Rate limit alcanzado en consultas');
        throw Exception('HTTP_ERROR_429: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> consultasJson = data['data'];
          final consultas = consultasJson.map((json) => ConsultaModel.fromJson(json)).toList();
          print('✅ CONSULTAS OBTENIDAS: ${consultas.length} registros');
          return consultas;
        } else {
          print('⚠️ RESPUESTA SIN DATOS DE CONSULTAS');
          return [];
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('🚫 Token inválido detectado - limpiando sesión');
        throw Exception('INVALID_TOKEN: Token inválido o expirado');
      } else if (response.statusCode == 404) {
        print('📭 No hay consultas de atención registradas');
        return [];
      } else {
        print('❌ ERROR HTTP: ${response.statusCode}');
        return [];
      }
      
    } catch (e) {
      print('❌ GET CONSULTAS ERROR: $e');
      
      // Si es error de token, propagarlo
      if (e.toString().contains('INVALID_TOKEN')) {
        rethrow;
      }
      
      // Para otros errores, retornar lista vacía
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🎨 ALEBRIJES - SISTEMA TAMAGOTCHI
  // ═══════════════════════════════════════════════════════════

  /// GET /me/alebrije - Obtener alebrije del usuario
  static Future<Map<String, dynamic>?> getAlebrije(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/me/alebrije'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            normalTimeout,
            onTimeout: () {
              throw Exception('TIMEOUT: Timeout obteniendo alebrije');
            },
          );

      print('🎨 ALEBRIJE GET RESPONSE: ${response.statusCode}');
      print('📦 RESPONSE BODY LENGTH: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        print('📋 RESPONSE BODY: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
        
        final data = jsonDecode(response.body);
        print('🔍 PARSED DATA KEYS: ${data.keys.toList()}');
        print('🔍 data["success"]: ${data['success']}');
        print('🔍 data["data"]: ${data['data'] != null ? "EXISTS" : "NULL"}');
        print('🔍 data["id"]: ${data['id']}');
        print('🔍 data["matricula"]: ${data['matricula']}');
        
        // Manejar dos formatos de respuesta:
        // Formato 1: {"success": true, "data": {...alebrije...}}
        // Formato 2: {...alebrije directo...}
        
        if (data['success'] == true && data['data'] != null) {
          // Formato con wrapper
          print('✅ Alebrije cargado desde backend (formato wrapper)');
          return data['data'] as Map<String, dynamic>;
        } else if (data['id'] != null && data['matricula'] != null) {
          // Formato directo (el alebrije es el objeto raíz)
          print('✅ Alebrije cargado desde backend (formato directo)');
          print('   - Nombre: ${data['nombre']}');
          print('   - Matrícula: ${data['matricula']}');
          return data as Map<String, dynamic>;
        }
        
        print('⚠️ Backend devolvió 200 pero formato no reconocido');
        print('   Contenido completo: ${response.body}');
        return null;
      } else if (response.statusCode == 404) {
        print('📭 No hay alebrije en backend (normal para nuevo usuario)');
        return null;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('INVALID_TOKEN: Token inválido');
      } else {
        print('⚠️ Error obteniendo alebrije: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo alebrije: $e');
      return null;
    }
  }

  /// POST /me/alebrije - Crear nuevo alebrije
  static Future<bool> createAlebrije(String token, Map<String, dynamic> alebrijeData) async {
    final result = await _retryWithBackoff(
      () async {
        print('📤 ENVIANDO ALEBRIJE A BACKEND:');
        print('   - Nombre: ${alebrijeData['nombre']}');
        print('   - Especie: ${alebrijeData['dna']?['especieBase']}');
        
        final response = await http
            .post(
              Uri.parse('$baseUrl/me/alebrije'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(alebrijeData),
            )
            .timeout(
              normalTimeout,
              onTimeout: () {
                throw Exception('TIMEOUT: Timeout creando alebrije');
              },
            );

        print('🎨 ALEBRIJE CREATE RESPONSE: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Alebrije creado en backend');
          return true;
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception('INVALID_TOKEN: Token inválido');
        } else {
          print('⚠️ Error creando alebrije: ${response.statusCode}');
          print('📋 RESPONSE BODY: ${response.body}');
          return false;
        }
      },
      operationName: 'CREATE alebrije',
    );
    return result ?? false;
  }

  /// PUT /me/alebrije - Actualizar alebrije existente
  static Future<bool> updateAlebrije(String token, Map<String, dynamic> alebrijeData) async {
    final result = await _retryWithBackoff(
      () async {
        print('📤 ENVIANDO ACTUALIZACIÓN DE ALEBRIJE:');
        print('   - Nombre: ${alebrijeData['nombre']}');
        print('   - Nivel: ${alebrijeData['nivelEvolucion']}');
        print('   - XP: ${alebrijeData['puntosExperiencia']}');
        print('   - Hambre: ${alebrijeData['estado']?['hambre']}');
        print('   - Felicidad: ${alebrijeData['estado']?['felicidad']}');
        
        final response = await http
            .put(
              Uri.parse('$baseUrl/me/alebrije'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(alebrijeData),
            )
            .timeout(
              normalTimeout,
              onTimeout: () {
                throw Exception('TIMEOUT: Timeout actualizando alebrije');
              },
            );

        print('🎨 ALEBRIJE UPDATE RESPONSE: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          print('📋 RESPONSE BODY: ${response.body}');
        }

        if (response.statusCode == 200) {
          print('✅ Alebrije actualizado EXITOSAMENTE en backend');
          return true;
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw Exception('INVALID_TOKEN: Token inválido');
        } else {
          print('⚠️ Error actualizando alebrije: ${response.statusCode}');
          return false;
        }
      },
      operationName: 'UPDATE alebrije',
    );
    return result ?? false;
  }

  /// POST /me/alebrije/interaccion - Registrar interacción (alimentar, jugar, etc.)
  static Future<bool> registrarInteraccion(
    String token,
    String tipo,
    int cantidad,
  ) async {
    final result = await _retryWithBackoff(
      () async {
        final response = await http
            .post(
              Uri.parse('$baseUrl/me/alebrije/interaccion'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'tipo': tipo,
                'cantidad': cantidad,
              }),
            )
            .timeout(
              shortTimeout,
              onTimeout: () {
                throw Exception('TIMEOUT: Timeout registrando interacción');
              },
            );

        if (response.statusCode == 200) {
          print('✅ Interacción registrada: $tipo');
          return true;
        } else {
          print('⚠️ Error registrando interacción: ${response.statusCode}');
          return false;
        }
      },
      operationName: 'INTERACCION alebrije',
      maxAttempts: 1, // No reintentar interacciones, es opcional
    );
    return result ?? false;
  }

  /// POST /me/alebrije/capsula - Registrar cápsula obtenida
  static Future<bool> registrarCapsula(
    String token,
    Map<String, dynamic> capsulaData,
    String servicioSalud,
  ) async {
    final result = await _retryWithBackoff(
      () async {
        final response = await http
            .post(
              Uri.parse('$baseUrl/me/alebrije/capsula'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'capsula': capsulaData,
                'servicioSalud': servicioSalud,
              }),
            )
            .timeout(
              shortTimeout,
              onTimeout: () {
                throw Exception('TIMEOUT: Timeout registrando cápsula');
              },
            );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('💊 Cápsula registrada: ${data['capsula']['nombre']}');
          return true;
        } else {
          print('⚠️ Error registrando cápsula: ${response.statusCode}');
          return false;
        }
      },
      operationName: 'CAPSULA alebrije',
      maxAttempts: 1, // No reintentar, es opcional
    );
    return result ?? false;
  }

}
