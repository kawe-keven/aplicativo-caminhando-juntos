import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:caminhandojuntos/services/map_tile_cache.dart';
import 'package:caminhandojuntos/widgets/app_tile_layer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

enum TileHttpResultType { success, authError, notFound, transientError }

class CircuitBreakerState {
  String state = 'closed'; // 'closed', 'open', 'halfOpen'
  int consecutiveFailures = 0;
  DateTime? openUntil;
  int failureCountTotal = 0;

  bool canAttempt() {
    final now = DateTime.now();
    if (state == 'open') {
      if (openUntil != null && now.isAfter(openUntil!)) {
        state = 'halfOpen';
        return true;
      }
      return false;
    }
    return true;
  }

  void recordSuccess() {
    state = 'closed';
    consecutiveFailures = 0;
    openUntil = null;
  }

  void recordFailure() {
    consecutiveFailures++;
    failureCountTotal++;
    if (state == 'halfOpen' || consecutiveFailures >= 10) {
      state = 'open';
      // Backoff exponencial com jitter: base 10s * 2^(failures-10), máximo 60s
      final exp = min(consecutiveFailures - 10, 3);
      final backoffSeconds = min(10 * pow(2, max(exp, 0)).toInt(), 60);
      final jitter = Random().nextInt(5);
      openUntil = DateTime.now().add(Duration(seconds: backoffSeconds + jitter));
    }
  }
}

class LocalTileProvider extends TileProvider {
  final String provedor; // 'mapbox' ou 'osm'
  final String estilo;
  final MapTileCache _cache = MapTileCache();
  
  static final Uint8List kTransparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
  );

  // Circuit breakers por provedor
  static final Map<String, CircuitBreakerState> _circuitBreakers = {
    'mapbox': CircuitBreakerState(),
    'osm': CircuitBreakerState(),
  };

  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..maxConnectionsPerHost = 10
    ..autoUncompress = true; 
  
  static DateTime _lastLogTime = DateTime.fromMillisecondsSinceEpoch(0);
  static int diagCount = 0;

  // Métricas globais de observabilidade
  static int cacheHits = 0;
  static int cacheMisses = 0;
  static int networkSuccesses = 0;
  static int authErrorsCount = 0;
  static int notFoundErrorsCount = 0;

  LocalTileProvider({this.provedor = 'osm', this.estilo = 'osm'});

  static void logDiagnostic(String msg) {
    if (kDebugMode) {
      final now = DateTime.now();
      if (now.difference(_lastLogTime).inSeconds >= 10 || diagCount < 15) {
        debugPrint('[TileDiag] $msg');
        _lastLogTime = now;
        diagCount++;
      }
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _LocalTileImageProvider(
      coordinates: coordinates,
      options: options,
      provedor: provedor,
      estilo: estilo,
      cache: _cache,
    );
  }
}

class _LocalTileImageProvider extends ImageProvider<_LocalTileImageProvider> {
  final TileCoordinates coordinates;
  final TileLayer options;
  final String provedor;
  final String estilo;
  final MapTileCache cache;

  _LocalTileImageProvider({
    required this.coordinates,
    required this.options,
    required this.provedor,
    required this.estilo,
    required this.cache,
  });

  @override
  Future<_LocalTileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_LocalTileImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(_LocalTileImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: 'LocalTileImageProvider($provedor, ${coordinates.z}, ${coordinates.x}, ${coordinates.y})',
    );
  }

  Future<ui.Codec> _loadAsync(_LocalTileImageProvider key, ImageDecoderCallback decode) async {
    final z = coordinates.z.toInt();
    final x = coordinates.x.toInt();
    final y = coordinates.y.toInt();

    // 1. Tentar Cache Local
    final Uint8List? cachedData = await cache.getTile(provedor, estilo, z, x, y);
    
    if (cachedData != null) {
      if (_isValidImage(cachedData)) {
        final bool expired = await cache.isTileExpired(provedor, estilo, z, x, y);
        if (!expired) {
          LocalTileProvider.cacheHits++;
          LocalTileProvider.logDiagnostic('[$provedor] CACHE HIT z=$z x=$x y=$y (size=${cachedData.length})');
          return await decode(await ui.ImmutableBuffer.fromUint8List(cachedData));
        }
      } else {
        // Remover dado corrompido do cache
        final db = await cache.database;
        await db.delete(
          'tiles',
          where: 'provedor = ? AND estilo = ? AND z = ? AND x = ? AND y = ?',
          whereArgs: [provedor, estilo, z, x, y],
        );
      }
    }
    LocalTileProvider.cacheMisses++;

    // 2. Verificar Circuit Breaker
    final cb = LocalTileProvider._circuitBreakers[provedor] ??= CircuitBreakerState();
    if (!cb.canAttempt()) {
      LocalTileProvider.logDiagnostic('[$provedor] CIRCUIT BREAKER OPEN (state=${cb.state}), fallback to cache or empty');
      if (cachedData != null && _isValidImage(cachedData)) {
        return await decode(await ui.ImmutableBuffer.fromUint8List(cachedData));
      }
      return await _emptyTile(decode);
    }

    // 3. Verificar Conectividade
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        LocalTileProvider.logDiagnostic('[$provedor] NO NETWORK, fallback to cache');
        if (cachedData != null && _isValidImage(cachedData)) {
          return await decode(await ui.ImmutableBuffer.fromUint8List(cachedData));
        }
        return await _emptyTile(decode);
      }
    } catch (_) {}

    final stopwatch = Stopwatch()..start();

    try {
      String url = options.urlTemplate!;
      options.additionalOptions.forEach((key, value) {
        url = url.replaceAll('{$key}', value);
      });
      url = url
          .replaceAll('{z}', z.toString())
          .replaceAll('{x}', x.toString())
          .replaceAll('{y}', y.toString());
      
      final uri = Uri.parse(url);
      final request = await LocalTileProvider._httpClient.getUrl(uri);
      
      // User-Agent adequado por provedor
      if (provedor == 'osm') {
        request.headers.set(HttpHeaders.userAgentHeader, 'caminhandojuntos (contato@caminhandojuntos.com)');
      } else {
        request.headers.set(HttpHeaders.userAgentHeader, 'caminhandojuntos');
      }
      
      final response = await request.close().timeout(const Duration(seconds: 10));
      final contentType = response.headers.contentType?.toString() ?? 'unknown';
      final bytes = await consolidateHttpClientResponseBytes(response);
      stopwatch.stop();

      final resultType = _classifyResponse(response.statusCode, contentType, bytes);

      switch (resultType) {
        case TileHttpResultType.success:
          cb.recordSuccess();
          LocalTileProvider.networkSuccesses++;
          LocalTileProvider.logDiagnostic('[$provedor] REDE SUCCESS z=$z x=$x y=$y status=${response.statusCode} size=${bytes.length} (${stopwatch.elapsedMilliseconds}ms)');
          
          // Gravar no cache (apenas se imagem válida)
          await cache.putTile(provedor, estilo, z, x, y, bytes);
          return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));

        case TileHttpResultType.authError:
          LocalTileProvider.authErrorsCount++;
          LocalTileProvider.logDiagnostic('[$provedor] AUTH ERROR (401/403) z=$z x=$x y=$y. Fallback imediato!');
          if (provedor == 'mapbox') {
            AppTileLayer.forceNetworkFallback(); // Força OSM se Mapbox falhar por auth
          }
          break;

        case TileHttpResultType.notFound:
          LocalTileProvider.notFoundErrorsCount++;
          LocalTileProvider.logDiagnostic('[$provedor] NOT FOUND (404) z=$z x=$x y=$y. URL template ou tile inexistente.');
          break;

        case TileHttpResultType.transientError:
          cb.recordFailure();
          LocalTileProvider.logDiagnostic('[$provedor] TRANSIENT ERROR status=${response.statusCode} z=$z x=$x y=$y (failures=${cb.consecutiveFailures})');
          break;
      }
    } catch (e) {
      stopwatch.stop();
      cb.recordFailure();
      LocalTileProvider.logDiagnostic('[$provedor] EXCEPTION z=$z x=$x y=$y: $e (failures=${cb.consecutiveFailures})');
    }

    if (cachedData != null && _isValidImage(cachedData)) {
      return await decode(await ui.ImmutableBuffer.fromUint8List(cachedData));
    }
    return await _emptyTile(decode);
  }

  TileHttpResultType _classifyResponse(int statusCode, String contentType, Uint8List bytes) {
    if (statusCode == 401 || statusCode == 403) {
      return TileHttpResultType.authError;
    }
    if (statusCode == 404) {
      return TileHttpResultType.notFound;
    }
    if (statusCode == 200 && _isValidImage(bytes)) {
      return TileHttpResultType.success;
    }
    return TileHttpResultType.transientError;
  }

  bool _isValidImage(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // PNG (\x89PNG)
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return true;
    }
    // JPEG (\xFF\xD8\xFF)
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    // WebP (RIFF....WEBP)
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return true;
    }
    // Fallback por magic bytes PNG/JPEG
    if (bytes[0] == 0x89 || (bytes[0] == 0xFF && bytes[1] == 0xD8)) {
      return true;
    }
    return false;
  }

  Future<ui.Codec> _emptyTile(ImageDecoderCallback decode) async {
    return await decode(await ui.ImmutableBuffer.fromUint8List(LocalTileProvider.kTransparentPng));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LocalTileImageProvider &&
          provedor == other.provedor &&
          estilo == other.estilo &&
          coordinates == other.coordinates;

  @override
  int get hashCode => provedor.hashCode ^ estilo.hashCode ^ coordinates.hashCode;
}
