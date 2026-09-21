import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:caminhandojuntos/services/map_tile_cache.dart';
import 'package:caminhandojuntos/widgets/app_tile_layer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class LocalTileProvider extends TileProvider {
  final String estilo;
  final MapTileCache _cache = MapTileCache();
  
  // PNG 1x1 transparente válido
  static final Uint8List kTransparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
  );

  // Circuit breaker
  static int _failureCount = 0;
  static DateTime? _breakerOpenUntil;
  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 6)
    ..autoUncompress = true; 
  static const int _maxConcurrent = 6;
  static int _activeRequests = 0;
  
  static DateTime _lastLogTime = DateTime.fromMillisecondsSinceEpoch(0);
  static int diagCount = 0;
  static int consecutiveFailures = 0;

  LocalTileProvider({required this.estilo});

  static void logDiagnostic(String msg) {
    if (kDebugMode) {
      final now = DateTime.now();
      if (now.difference(_lastLogTime).inSeconds >= 10 || diagCount < 10) {
        debugPrint('[TileDiag] $msg');
        _lastLogTime = now;
      }
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _LocalTileImageProvider(
      coordinates: coordinates,
      options: options,
      estilo: estilo,
      cache: _cache,
    );
  }
}

class _LocalTileImageProvider extends ImageProvider<_LocalTileImageProvider> {
  final TileCoordinates coordinates;
  final TileLayer options;
  final String estilo;
  final MapTileCache cache;

  _LocalTileImageProvider({
    required this.coordinates,
    required this.options,
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
      debugLabel: 'LocalTileImageProvider(${coordinates.x}, ${coordinates.y}, ${coordinates.z})',
    );
  }

  Future<ui.Codec> _loadAsync(_LocalTileImageProvider key, ImageDecoderCallback decode) async {
    final Uint8List? cachedData = await cache.getTile(estilo, coordinates.z.toInt(), coordinates.x.toInt(), coordinates.y.toInt());
    
    if (cachedData != null) {
      if (_isValidImage(cachedData)) {
        final bool expired = await cache.isTileExpired(estilo, coordinates.z.toInt(), coordinates.x.toInt(), coordinates.y.toInt());
        if (!expired) {
          if (LocalTileProvider.diagCount < 10) {
            LocalTileProvider.logDiagnostic('Tile [${LocalTileProvider.diagCount}]: CACHE, Size: ${cachedData.length}, Magic: ${cachedData.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
            LocalTileProvider.diagCount++;
          }
          LocalTileProvider.consecutiveFailures = 0;
          return await decode(await ui.ImmutableBuffer.fromUint8List(cachedData));
        }
      } else {
        await cache.database.then((db) => db.delete(
          'tiles',
          where: 'estilo = ? AND z = ? AND x = ? AND y = ?',
          whereArgs: [estilo, coordinates.z.toInt(), coordinates.x.toInt(), coordinates.y.toInt()],
        ));
      }
    }

    if (LocalTileProvider._breakerOpenUntil != null && DateTime.now().isBefore(LocalTileProvider._breakerOpenUntil!)) {
      if (LocalTileProvider.diagCount < 10) {
        LocalTileProvider.logDiagnostic('Tile [${LocalTileProvider.diagCount}]: BREAKER OPEN, Fallback');
        LocalTileProvider.diagCount++;
      }
      if (cachedData != null && _isValidImage(cachedData)) {
        return await decode(await ui.ImmutableBuffer.fromUint8List(cachedData));
      }
      return await _emptyTile(decode);
    }

    try {
      if (LocalTileProvider._activeRequests >= LocalTileProvider._maxConcurrent) {
         if (LocalTileProvider.diagCount < 10) {
            LocalTileProvider.logDiagnostic('Tile [${LocalTileProvider.diagCount}]: CONCURRENT LIMIT, Fallback');
            LocalTileProvider.diagCount++;
         }
         if (cachedData != null && _isValidImage(cachedData)) {
           return await decode(await ui.ImmutableBuffer.fromUint8List(cachedData));
         }
         return await _emptyTile(decode);
      }

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        if (LocalTileProvider.diagCount < 10) {
            LocalTileProvider.logDiagnostic('Tile [${LocalTileProvider.diagCount}]: NO NETWORK, Fallback');
            LocalTileProvider.diagCount++;
        }
        if (cachedData != null && _isValidImage(cachedData)) {
          return await decode(await ui.ImmutableBuffer.fromUint8List(cachedData));
        }
        return await _emptyTile(decode);
      }

      LocalTileProvider._activeRequests++;
      
      String url = options.urlTemplate!;
      options.additionalOptions.forEach((key, value) {
        url = url.replaceAll('{$key}', value);
      });
      url = url
          .replaceAll('{z}', coordinates.z.toInt().toString())
          .replaceAll('{x}', coordinates.x.toInt().toString())
          .replaceAll('{y}', coordinates.y.toInt().toString());
      
      final uri = Uri.parse(url);
      final request = await LocalTileProvider._httpClient.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'caminhandojuntos');
      
      final response = await request.close().timeout(const Duration(seconds: 6));

      final contentType = response.headers.contentType?.toString() ?? 'unknown';
      final bytes = await consolidateHttpClientResponseBytes(response);
      final magicHex = bytes.length >= 4 ? bytes.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ') : 'short';

      if (LocalTileProvider.diagCount < 10) {
          LocalTileProvider.logDiagnostic('Tile [${LocalTileProvider.diagCount}]: REDE, Status: ${response.statusCode}, Type: $contentType, Size: ${bytes.length}, Magic: $magicHex');
          LocalTileProvider.diagCount++;
      }

      if (response.statusCode == 200 && contentType.startsWith('image/') && _isValidImage(bytes)) {
        LocalTileProvider._failureCount = 0;
        LocalTileProvider._breakerOpenUntil = null;
        LocalTileProvider.consecutiveFailures = 0;
        
        cache.putTile(estilo, coordinates.z.toInt(), coordinates.x.toInt(), coordinates.y.toInt(), bytes);
        
        return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
      } else {
        throw Exception('Invalid data: HTTP ${response.statusCode}, Type: $contentType');
      }
    } catch (e) {
      if (LocalTileProvider.diagCount < 10) {
          LocalTileProvider.logDiagnostic('Tile [${LocalTileProvider.diagCount}]: ERRO, $e');
          LocalTileProvider.diagCount++;
      }
      
      LocalTileProvider._failureCount++;
      LocalTileProvider.consecutiveFailures++;
      
      if (LocalTileProvider.consecutiveFailures >= 10) {
        final connectivity = await Connectivity().checkConnectivity();
        if (!connectivity.contains(ConnectivityResult.none)) {
           AppTileLayer.forceNetworkFallback();
        }
      }

      if (LocalTileProvider._failureCount >= 3) {
        LocalTileProvider._breakerOpenUntil = DateTime.now().add(const Duration(seconds: 30));
      }
      
      if (cachedData != null && _isValidImage(cachedData)) {
        return await decode(await ui.ImmutableBuffer.fromUint8List(cachedData));
      }
    } finally {
      LocalTileProvider._activeRequests--;
    }

    return await _emptyTile(decode);
  }

  bool _isValidImage(Uint8List bytes) {
    if (bytes.length < 4) return false;
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return true;
    }
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
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
          estilo == other.estilo &&
          coordinates == other.coordinates;

  @override
  int get hashCode => estilo.hashCode ^ coordinates.hashCode;
}
