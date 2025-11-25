import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/alebrije_model.dart';

/// Generador algorítmico de alebrijes usando SVG y generación procedural
/// Crea representaciones visuales únicas basadas en el DNA genético
class AlebrijeGenerator {
  final AlebrijeModel alebrije;
  final Random _random;

  AlebrijeGenerator(this.alebrije)
      : _random = Random(alebrije.dna.hashCode);

  /// Genera el SVG del alebrije completo
  String generarSVG({double width = 300, double height = 300}) {
    final cx = width / 2;
    final cy = height / 2;
    final escala = _calcularEscala(alebrije.dna.genCuerpo.tamano, width);

    final partes = <String>[];

    // Orden de renderizado (de atrás hacia adelante)
    if (alebrije.dna.genAlas.tiene) {
      partes.add(_generarAlas(cx, cy - 20, escala));
    }
    if (alebrije.dna.genCola.tiene) {
      partes.add(_generarCola(cx + 60, cy + 40, escala));
    }
    partes.add(_generarCuerpo(cx, cy, escala));
    partes.add(_generarExtremidades(cx, cy, escala));
    partes.add(_generarCabeza(cx, cy - 50, escala));

    // Efectos de brillantez y patrones
    partes.add(_generarPatrones(cx, cy, escala));
    partes.add(_generarEfectoBrillantez(cx, cy, escala));

    return '''
<svg viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg">
  <defs>
    ${_generarGradientes()}
    ${_generarFiltros()}
  </defs>
  <rect width="$width" height="$height" fill="transparent"/>
  ${partes.join('\n  ')}
</svg>
    ''';
  }

  double _calcularEscala(String tamano, double baseWidth) {
    switch (tamano) {
      case 'pequeno':
        return 0.7;
      case 'mediano':
        return 1.0;
      case 'grande':
        return 1.3;
      case 'masivo':
        return 1.6;
      default:
        return 1.0;
    }
  }

  /// Genera los gradientes de colores para el alebrije
  String _generarGradientes() {
    final colores = alebrije.dna.colores;
    return '''
    <linearGradient id="gradPrimario" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:${colores.colorPrimario};stop-opacity:1" />
      <stop offset="50%" style="stop-color:${colores.colorSecundario};stop-opacity:1" />
      <stop offset="100%" style="stop-color:${colores.colorTerciario};stop-opacity:1" />
    </linearGradient>
    <radialGradient id="gradAcento" cx="50%" cy="50%" r="50%">
      <stop offset="0%" style="stop-color:${colores.colorAcento};stop-opacity:0.8" />
      <stop offset="100%" style="stop-color:${colores.colorPrimario};stop-opacity:0.3" />
    </radialGradient>
    ''';
  }

  /// Genera filtros SVG para efectos visuales
  String _generarFiltros() {
    final brillantez = alebrije.dna.colores.brillantez;
    return '''
    <filter id="brillo">
      <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
      <feOffset dx="0" dy="0" result="offsetblur"/>
      <feFlood flood-color="${alebrije.dna.colores.colorAcento}" flood-opacity="${brillantez * 0.5}"/>
      <feComposite in2="offsetblur" operator="in"/>
      <feMerge>
        <feMergeNode/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <filter id="sombra">
      <feDropShadow dx="2" dy="2" stdDeviation="2" flood-opacity="0.3"/>
    </filter>
    ''';
  }

  /// Genera la cabeza del alebrije
  String _generarCabeza(double cx, double cy, double escala) {
    final gen = alebrije.dna.genCabeza;
    final partes = <String>[];

    // Forma base de la cabeza
    switch (gen.forma) {
      case 'felina':
        partes.add(_cabezaFelina(cx, cy, escala));
        break;
      case 'aviar':
        partes.add(_cabezaAviar(cx, cy, escala));
        break;
      case 'reptil':
        partes.add(_cabezaReptil(cx, cy, escala));
        break;
      case 'cervido':
        partes.add(_cabezaCervido(cx, cy, escala));
        break;
      case 'pequena':
        partes.add(_cabezaPequena(cx, cy, escala));
        break;
      default:
        partes.add(_cabezaFelina(cx, cy, escala));
    }

    // Orejas
    if (gen.orejas != 'ausentes') {
      partes.add(_generarOrejas(cx, cy, escala, gen.orejas));
    }

    // Cuernos
    if (gen.cuernos != 'ausentes') {
      partes.add(_generarCuernos(cx, cy, escala, gen.cuernos));
    }

    // Ojos
    partes.add(_generarOjos(cx, cy, escala, gen.ojos));

    return '<g id="cabeza">${partes.join('')}</g>';
  }

  String _cabezaFelina(double cx, double cy, double escala) {
    final w = 50 * escala;
    final h = 45 * escala;
    return '<ellipse cx="$cx" cy="$cy" rx="$w" ry="$h" fill="url(#gradPrimario)" filter="url(#sombra)"/>';
  }

  String _cabezaAviar(double cx, double cy, double escala) {
    final w = 40 * escala;
    final h = 50 * escala;
    return '<ellipse cx="$cx" cy="$cy" rx="$w" ry="$h" fill="url(#gradPrimario)" filter="url(#sombra)"/>';
  }

  String _cabezaReptil(double cx, double cy, double escala) {
    final w = 55 * escala;
    final h = 35 * escala;
    return '<ellipse cx="$cx" cy="$cy" rx="$w" ry="$h" fill="url(#gradPrimario)" filter="url(#sombra)"/>';
  }

  String _cabezaCervido(double cx, double cy, double escala) {
    final w = 45 * escala;
    final h = 55 * escala;
    return '<ellipse cx="$cx" cy="$cy" rx="$w" ry="$h" fill="url(#gradPrimario)" filter="url(#sombra)"/>';
  }

  String _cabezaPequena(double cx, double cy, double escala) {
    final r = 30 * escala;
    return '<circle cx="$cx" cy="$cy" r="$r" fill="url(#gradPrimario)" filter="url(#sombra)"/>';
  }

  String _generarOrejas(double cx, double cy, double escala, String tipo) {
    switch (tipo) {
      case 'puntiagudas':
        return '''
          <path d="M ${cx - 35 * escala} ${cy - 30 * escala} L ${cx - 45 * escala} ${cy - 60 * escala} L ${cx - 30 * escala} ${cy - 35 * escala} Z" fill="${alebrije.dna.colores.colorSecundario}"/>
          <path d="M ${cx + 35 * escala} ${cy - 30 * escala} L ${cx + 45 * escala} ${cy - 60 * escala} L ${cx + 30 * escala} ${cy - 35 * escala} Z" fill="${alebrije.dna.colores.colorSecundario}"/>
        ''';
      case 'redondeadas':
        return '''
          <ellipse cx="${cx - 40 * escala}" cy="${cy - 40 * escala}" rx="${15 * escala}" ry="${25 * escala}" fill="${alebrije.dna.colores.colorSecundario}"/>
          <ellipse cx="${cx + 40 * escala}" cy="${cy - 40 * escala}" rx="${15 * escala}" ry="${25 * escala}" fill="${alebrije.dna.colores.colorSecundario}"/>
        ''';
      case 'largas':
        return '''
          <rect x="${cx - 50 * escala}" y="${cy - 70 * escala}" width="${10 * escala}" height="${50 * escala}" rx="5" fill="${alebrije.dna.colores.colorSecundario}"/>
          <rect x="${cx + 40 * escala}" y="${cy - 70 * escala}" width="${10 * escala}" height="${50 * escala}" rx="5" fill="${alebrije.dna.colores.colorSecundario}"/>
        ''';
      default:
        return '';
    }
  }

  String _generarCuernos(double cx, double cy, double escala, String tipo) {
    switch (tipo) {
      case 'ramificados':
        return '''
          <path d="M ${cx - 30 * escala} ${cy - 40 * escala} L ${cx - 35 * escala} ${cy - 70 * escala} M ${cx - 35 * escala} ${cy - 60 * escala} L ${cx - 45 * escala} ${cy - 65 * escala} M ${cx - 35 * escala} ${cy - 55 * escala} L ${cx - 40 * escala} ${cy - 50 * escala}" 
                stroke="${alebrije.dna.colores.colorAcento}" stroke-width="${3 * escala}" fill="none"/>
          <path d="M ${cx + 30 * escala} ${cy - 40 * escala} L ${cx + 35 * escala} ${cy - 70 * escala} M ${cx + 35 * escala} ${cy - 60 * escala} L ${cx + 45 * escala} ${cy - 65 * escala} M ${cx + 35 * escala} ${cy - 55 * escala} L ${cx + 40 * escala} ${cy - 50 * escala}" 
                stroke="${alebrije.dna.colores.colorAcento}" stroke-width="${3 * escala}" fill="none"/>
        ''';
      case 'espirales':
        return '''
          <path d="M ${cx - 30 * escala} ${cy - 40 * escala} Q ${cx - 40 * escala} ${cy - 50 * escala} ${cx - 35 * escala} ${cy - 65 * escala} T ${cx - 30 * escala} ${cy - 75 * escala}" 
                stroke="${alebrije.dna.colores.colorAcento}" stroke-width="${4 * escala}" fill="none"/>
          <path d="M ${cx + 30 * escala} ${cy - 40 * escala} Q ${cx + 40 * escala} ${cy - 50 * escala} ${cx + 35 * escala} ${cy - 65 * escala} T ${cx + 30 * escala} ${cy - 75 * escala}" 
                stroke="${alebrije.dna.colores.colorAcento}" stroke-width="${4 * escala}" fill="none"/>
        ''';
      case 'pequenos':
        return '''
          <circle cx="${cx - 35 * escala}" cy="${cy - 45 * escala}" r="${5 * escala}" fill="${alebrije.dna.colores.colorAcento}"/>
          <circle cx="${cx + 35 * escala}" cy="${cy - 45 * escala}" r="${5 * escala}" fill="${alebrije.dna.colores.colorAcento}"/>
        ''';
      default:
        return '';
    }
  }

  String _generarOjos(double cx, double cy, double escala, String tipo) {
    final offsetX = 20 * escala;
    final partes = <String>[];

    switch (tipo) {
      case 'grandes':
        partes.add('<circle cx="${cx - offsetX}" cy="$cy" r="${10 * escala}" fill="white"/>');
        partes.add('<circle cx="${cx + offsetX}" cy="$cy" r="${10 * escala}" fill="white"/>');
        partes.add('<circle cx="${cx - offsetX}" cy="$cy" r="${6 * escala}" fill="black"/>');
        partes.add('<circle cx="${cx + offsetX}" cy="$cy" r="${6 * escala}" fill="black"/>');
        break;
      case 'rasgados':
        partes.add('<ellipse cx="${cx - offsetX}" cy="$cy" rx="${12 * escala}" ry="${6 * escala}" fill="white"/>');
        partes.add('<ellipse cx="${cx + offsetX}" cy="$cy" rx="${12 * escala}" ry="${6 * escala}" fill="white"/>');
        partes.add('<ellipse cx="${cx - offsetX}" cy="$cy" rx="${6 * escala}" ry="${4 * escala}" fill="black"/>');
        partes.add('<ellipse cx="${cx + offsetX}" cy="$cy" rx="${6 * escala}" ry="${4 * escala}" fill="black"/>');
        break;
      case 'brillantes':
        partes.add('<circle cx="${cx - offsetX}" cy="$cy" r="${8 * escala}" fill="${alebrije.dna.colores.colorAcento}"/>');
        partes.add('<circle cx="${cx + offsetX}" cy="$cy" r="${8 * escala}" fill="${alebrije.dna.colores.colorAcento}"/>');
        partes.add('<circle cx="${cx - offsetX - 2}" cy="${cy - 2}" r="${3 * escala}" fill="white" filter="url(#brillo)"/>');
        partes.add('<circle cx="${cx + offsetX - 2}" cy="${cy - 2}" r="${3 * escala}" fill="white" filter="url(#brillo)"/>');
        break;
      case 'misteriosos':
        partes.add('<ellipse cx="${cx - offsetX}" cy="$cy" rx="${10 * escala}" ry="${8 * escala}" fill="#8B1538"/>');
        partes.add('<ellipse cx="${cx + offsetX}" cy="$cy" rx="${10 * escala}" ry="${8 * escala}" fill="#8B1538"/>');
        partes.add('<circle cx="${cx - offsetX}" cy="$cy" r="${2 * escala}" fill="white" opacity="0.8"/>');
        partes.add('<circle cx="${cx + offsetX}" cy="$cy" r="${2 * escala}" fill="white" opacity="0.8"/>');
        break;
    }

    return partes.join('');
  }

  /// Genera el cuerpo del alebrije
  String _generarCuerpo(double cx, double cy, double escala) {
    final gen = alebrije.dna.genCuerpo;
    final proporcion = gen.proporcion;

    switch (gen.forma) {
      case 'compacto':
        return '<ellipse cx="$cx" cy="$cy" rx="${60 * escala}" ry="${55 * escala * proporcion}" fill="url(#gradPrimario)" filter="url(#sombra)"/>';
      case 'alargado':
        return '<ellipse cx="$cx" cy="$cy" rx="${50 * escala * proporcion}" ry="${70 * escala}" fill="url(#gradPrimario)" filter="url(#sombra)"/>';
      case 'robusto':
        return '<ellipse cx="$cx" cy="$cy" rx="${70 * escala}" ry="${60 * escala * proporcion}" fill="url(#gradPrimario)" filter="url(#sombra)"/>';
      case 'esbelto':
        return '<ellipse cx="$cx" cy="$cy" rx="${45 * escala * proporcion}" ry="${75 * escala}" fill="url(#gradPrimario)" filter="url(#sombra)"/>';
      default:
        return '<ellipse cx="$cx" cy="$cy" rx="${60 * escala}" ry="${60 * escala}" fill="url(#gradPrimario)" filter="url(#sombra)"/>';
    }
  }

  /// Genera las extremidades (patas)
  String _generarExtremidades(double cx, double cy, double escala) {
    final gen = alebrije.dna.genExtremidades;
    final partes = <String>[];

    if (gen.numeroPatas == 0) return '';

    final anchoBase = gen.tamano == 'pequenas' ? 8.0 : gen.tamano == 'medianas' ? 12.0 : 16.0;
    final largo = 40.0 * escala;
    final ancho = anchoBase * escala;

    if (gen.numeroPatas >= 2) {
      // Patas traseras
      partes.add(_generarPata(cx - 30 * escala, cy + 40 * escala, ancho, largo, gen.tipo));
      partes.add(_generarPata(cx + 30 * escala, cy + 40 * escala, ancho, largo, gen.tipo));
    }

    if (gen.numeroPatas >= 4) {
      // Patas delanteras
      partes.add(_generarPata(cx - 25 * escala, cy + 20 * escala, ancho, largo, gen.tipo));
      partes.add(_generarPata(cx + 25 * escala, cy + 20 * escala, ancho, largo, gen.tipo));
    }

    return '<g id="extremidades">${partes.join('')}</g>';
  }

  String _generarPata(double x, double y, double ancho, double largo, String tipo) {
    final color = alebrije.dna.colores.colorTerciario;
    return '''
      <rect x="${x - ancho / 2}" y="$y" width="$ancho" height="$largo" rx="${ancho / 2}" fill="$color" filter="url(#sombra)"/>
      <ellipse cx="$x" cy="${y + largo + 5}" rx="${ancho * 1.2}" ry="${ancho * 0.8}" fill="$color"/>
    ''';
  }

  /// Genera la cola del alebrije
  String _generarCola(double cx, double cy, double escala) {
    final gen = alebrije.dna.genCola;
    if (!gen.tiene) return '';

    final color = alebrije.dna.colores.colorSecundario;
    
    switch (gen.tipo) {
      case 'larga':
        return '<path d="M $cx $cy Q ${cx + 40 * escala} ${cy + 20 * escala} ${cx + 60 * escala} ${cy - 10 * escala}" stroke="$color" stroke-width="${10 * escala}" fill="none" filter="url(#sombra)"/>';
      case 'corta':
        return '<ellipse cx="${cx + 20 * escala}" cy="${cy + 10 * escala}" rx="${15 * escala}" ry="${10 * escala}" fill="$color" filter="url(#sombra)"/>';
      case 'plumosa':
        return '''
          <path d="M $cx $cy Q ${cx + 30 * escala} ${cy + 15 * escala} ${cx + 50 * escala} ${cy}" stroke="$color" stroke-width="${12 * escala}" fill="none" filter="url(#sombra)"/>
          <path d="M ${cx + 20 * escala} ${cy + 5 * escala} L ${cx + 25 * escala} ${cy + 20 * escala}" stroke="$color" stroke-width="${3 * escala}"/>
          <path d="M ${cx + 35 * escala} ${cy + 8 * escala} L ${cx + 38 * escala} ${cy + 23 * escala}" stroke="$color" stroke-width="${3 * escala}"/>
        ''';
      case 'escamosa':
        return '''
          <path d="M $cx $cy Q ${cx + 30 * escala} ${cy + 10 * escala} ${cx + 55 * escala} ${cy - 5 * escala}" stroke="$color" stroke-width="${8 * escala}" fill="none" filter="url(#sombra)"/>
          ${_generarEscamas(cx, cy, escala)}
        ''';
      case 'espiral':
        return '<path d="M $cx $cy Q ${cx + 20 * escala} ${cy + 30 * escala} ${cx + 40 * escala} ${cy + 10 * escala} T ${cx + 60 * escala} ${cy + 20 * escala}" stroke="$color" stroke-width="${8 * escala}" fill="none" filter="url(#sombra)"/>';
      default:
        return '';
    }
  }

  String _generarEscamas(double cx, double cy, double escala) {
    final partes = <String>[];
    for (int i = 0; i < 8; i++) {
      final x = cx + (i * 7 * escala);
      final y = cy + (i % 2 == 0 ? 5 * escala : -5 * escala);
      partes.add('<circle cx="$x" cy="$y" r="${3 * escala}" fill="${alebrije.dna.colores.colorAcento}" opacity="0.6"/>');
    }
    return partes.join('');
  }

  /// Genera las alas del alebrije
  String _generarAlas(double cx, double cy, double escala) {
    final gen = alebrije.dna.genAlas;
    if (!gen.tiene) return '';

    final tamanoMultiplicador = gen.tamano == 'pequenas' ? 0.7 : gen.tamano == 'medianas' ? 1.0 : gen.tamano == 'grandes' ? 1.3 : 1.6;
    final color = alebrije.dna.colores.colorAcento;

    switch (gen.tipo) {
      case 'plumas':
        return _generarAlasPlumas(cx, cy, escala * tamanoMultiplicador, color);
      case 'membrana':
        return _generarAlasMembrana(cx, cy, escala * tamanoMultiplicador, color);
      case 'energia':
        return _generarAlasEnergia(cx, cy, escala * tamanoMultiplicador, color);
      case 'cristal':
        return _generarAlasCristal(cx, cy, escala * tamanoMultiplicador, color);
      default:
        return '';
    }
  }

  String _generarAlasPlumas(double cx, double cy, double escala, String color) {
    return '''
      <path d="M $cx $cy Q ${cx - 60 * escala} ${cy - 20 * escala} ${cx - 80 * escala} ${cy - 40 * escala}" fill="$color" opacity="0.8" filter="url(#sombra)"/>
      <path d="M $cx $cy Q ${cx + 60 * escala} ${cy - 20 * escala} ${cx + 80 * escala} ${cy - 40 * escala}" fill="$color" opacity="0.8" filter="url(#sombra)"/>
    ''';
  }

  String _generarAlasMembrana(double cx, double cy, double escala, String color) {
    return '''
      <path d="M $cx $cy L ${cx - 70 * escala} ${cy - 30 * escala} L ${cx - 50 * escala} ${cy + 10 * escala} Z" fill="$color" opacity="0.6" filter="url(#sombra)"/>
      <path d="M $cx $cy L ${cx + 70 * escala} ${cy - 30 * escala} L ${cx + 50 * escala} ${cy + 10 * escala} Z" fill="$color" opacity="0.6" filter="url(#sombra)"/>
    ''';
  }

  String _generarAlasEnergia(double cx, double cy, double escala, String color) {
    return '''
      <path d="M $cx $cy Q ${cx - 50 * escala} ${cy - 40 * escala} ${cx - 70 * escala} ${cy - 50 * escala}" stroke="$color" stroke-width="${6 * escala}" fill="none" opacity="0.9" filter="url(#brillo)"/>
      <path d="M $cx $cy Q ${cx + 50 * escala} ${cy - 40 * escala} ${cx + 70 * escala} ${cy - 50 * escala}" stroke="$color" stroke-width="${6 * escala}" fill="none" opacity="0.9" filter="url(#brillo)"/>
    ''';
  }

  String _generarAlasCristal(double cx, double cy, double escala, String color) {
    return '''
      <polygon points="${cx - 10 * escala},$cy ${cx - 60 * escala},${cy - 40 * escala} ${cx - 50 * escala},${cy + 5 * escala}" fill="$color" opacity="0.7" filter="url(#brillo)"/>
      <polygon points="${cx + 10 * escala},$cy ${cx + 60 * escala},${cy - 40 * escala} ${cx + 50 * escala},${cy + 5 * escala}" fill="$color" opacity="0.7" filter="url(#brillo)"/>
    ''';
  }

  /// Genera patrones geométricos sobre el alebrije
  String _generarPatrones(double cx, double cy, double escala) {
    final partes = <String>[];
    
    for (final patron in alebrije.dna.patronesGeometricos) {
      switch (patron) {
        case 'espirales':
          partes.add(_patronEspirales(cx, cy + 10, escala));
          break;
        case 'ondas':
          partes.add(_patronOndas(cx, cy, escala));
          break;
        case 'zigzag':
          partes.add(_patronZigzag(cx, cy + 20, escala));
          break;
        case 'puntos':
          partes.add(_patronPuntos(cx, cy, escala));
          break;
        case 'rayas':
          partes.add(_patronRayas(cx, cy, escala));
          break;
      }
    }

    return '<g id="patrones" opacity="0.6">${partes.join('')}</g>';
  }

  String _patronEspirales(double cx, double cy, double escala) {
    return '<path d="M ${cx - 20 * escala} $cy Q ${cx - 10 * escala} ${cy + 10 * escala} $cx ${cy + 5 * escala} T ${cx + 20 * escala} ${cy + 10 * escala}" stroke="${alebrije.dna.colores.colorAcento}" stroke-width="${2 * escala}" fill="none"/>';
  }

  String _patronOndas(double cx, double cy, double escala) {
    return '<path d="M ${cx - 40 * escala} $cy Q ${cx - 20 * escala} ${cy - 10 * escala} $cx $cy T ${cx + 40 * escala} $cy" stroke="${alebrije.dna.colores.colorAcento}" stroke-width="${2 * escala}" fill="none"/>';
  }

  String _patronZigzag(double cx, double cy, double escala) {
    return '<path d="M ${cx - 30 * escala} $cy L ${cx - 20 * escala} ${cy - 8 * escala} L ${cx - 10 * escala} $cy L $cx ${cy - 8 * escala} L ${cx + 10 * escala} $cy L ${cx + 20 * escala} ${cy - 8 * escala} L ${cx + 30 * escala} $cy" stroke="${alebrije.dna.colores.colorAcento}" stroke-width="${2 * escala}" fill="none"/>';
  }

  String _patronPuntos(double cx, double cy, double escala) {
    final partes = <String>[];
    for (int i = -3; i <= 3; i++) {
      for (int j = -2; j <= 2; j++) {
        if (_random.nextBool()) {
          partes.add('<circle cx="${cx + i * 15 * escala}" cy="${cy + j * 15 * escala}" r="${2 * escala}" fill="${alebrije.dna.colores.colorAcento}"/>');
        }
      }
    }
    return partes.join('');
  }

  String _patronRayas(double cx, double cy, double escala) {
    final partes = <String>[];
    for (int i = -2; i <= 2; i++) {
      partes.add('<line x1="${cx - 40 * escala}" y1="${cy + i * 15 * escala}" x2="${cx + 40 * escala}" y2="${cy + i * 15 * escala}" stroke="${alebrije.dna.colores.colorAcento}" stroke-width="${1.5 * escala}"/>');
    }
    return partes.join('');
  }

  /// Genera efecto de brillantez
  String _generarEfectoBrillantez(double cx, double cy, double escala) {
    final brillantez = alebrije.dna.colores.brillantez;
    if (brillantez < 0.5) return '';

    return '''
      <circle cx="${cx - 15 * escala}" cy="${cy - 20 * escala}" r="${3 * escala}" fill="white" opacity="${brillantez * 0.8}" filter="url(#brillo)"/>
      <circle cx="${cx + 20 * escala}" cy="${cy - 15 * escala}" r="${2 * escala}" fill="white" opacity="${brillantez * 0.6}" filter="url(#brillo)"/>
      <circle cx="$cx" cy="${cy + 25 * escala}" r="${2.5 * escala}" fill="white" opacity="${brillantez * 0.7}" filter="url(#brillo)"/>
    ''';
  }

  /// Genera una animación CSS para el alebrije
  String generarAnimacionCSS() {
    final estado = alebrije.saludGeneral;
    
    if (estado >= 80) {
      return '''
        @keyframes feliz {
          0%, 100% { transform: translateY(0) scale(1); }
          50% { transform: translateY(-10px) scale(1.05); }
        }
        animation: feliz 2s ease-in-out infinite;
      ''';
    } else if (estado >= 50) {
      return '''
        @keyframes neutro {
          0%, 100% { transform: translateX(0); }
          50% { transform: translateX(5px); }
        }
        animation: neutro 3s ease-in-out infinite;
      ''';
    } else {
      return '''
        @keyframes triste {
          0%, 100% { transform: translateY(0) rotate(0deg); }
          25% { transform: translateY(5px) rotate(-2deg); }
          75% { transform: translateY(5px) rotate(2deg); }
        }
        animation: triste 4s ease-in-out infinite;
      ''';
    }
  }
}
