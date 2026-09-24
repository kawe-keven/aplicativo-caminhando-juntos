# Refatoração da Arquitetura de Map Tiles e Resiliência de Rede

Este plano detalha a refatoração completa do sistema de tiles de mapa do aplicativo (`flutter_map`), visando eliminar telas em branco, melhorar a resiliência de rede, implementar um circuit breaker inteligente por provedor, otimizar o cache SQLite com WAL e LRU, e adicionar observabilidade estruturada (`[TileDiag]`).

## User Review Required

> [!IMPORTANT]
> - A introdução do **Circuit Breaker por Provedor** garante que falhas em tiles individuais ou erros permanentes (como 401/403/404) não bloqueiem o mapa inteiro.
> - O cache SQLite utilizará **WAL (Write-Ahead Logging)** para máxima performance de concorrência e transações atômicas.
> - O fallback para **OpenStreetMap (OSM)** exigirá um `User-Agent` estruturado conforme exigido pelas políticas de uso do OSM.

## Open Questions

- Nenhuma dúvida pendente. O escopo e os requisitos estão claros e alinhados com as melhores práticas de engenharia Flutter.

## Proposed Changes

### Componente de Configuração e Segredos
#### [MODIFY] [mapbox_config.dart](file:///C:/Users/keven/StudioProjects/aplicativo-caminhando-juntos/lib/config/mapbox_config.dart)
- Adicionar validação robusta de formato do token Mapbox (`pk.`).
- Expor parâmetros de configuração de TTL e limites de cache.

### Componente de Cache Local (`MapTileCache`)
#### [MODIFY] [map_tile_cache.dart](file:///C:/Users/keven/StudioProjects/aplicativo-caminhando-juntos/lib/services/map_tile_cache.dart)
- Ativar WAL (`PRAGMA journal_mode=WAL`) e síncrono otimizado.
- Chave de cache composta: `provedor` + `estilo` + `z` + `x` + `y`.
- Transações atômicas para gravação de tiles.
- Política LRU refinada com limite de tamanho (`kMaxCacheSize = 60 MB`).
- Verificação de integridade e tratamento automático de corrupção de banco.
- Garantir que tiles transparentes (erros/placeholders) **não** sejam cacheados.

### Componente de Rede, Circuit Breaker e Classificação de Erros (`LocalTileProvider`)
#### [MODIFY] [local_tile_provider.dart](file:///C:/Users/keven/StudioProjects/aplicativo-caminhando-juntos/lib/services/local_tile_provider.dart)
- Criar enum `TileHttpResultType` (`success`, `authError`, `notFound`, `transientError`).
- Refatorar tratamento de erros HTTP para não abrir Circuit Breaker em erros permanentes (401, 403, 404).
- Implementar **Circuit Breaker por Provedor** (`mapbox`, `osm`) com estados (`closed`, `open`, `halfOpen`) e backoff exponencial + jitter.
- Configurar User-Agent formal para OSM (`caminhandojuntos (contato@caminhandojuntos.com)`).
- Adicionar métricas internas e logs `[TileDiag]` estruturados (hit/miss, provedor, status, duração, estado do circuito).

### Componente de Camada do Mapa (`AppTileLayer`)
#### [MODIFY] [app_tile_layer.dart](file:///C:/Users/keven/StudioProjects/aplicativo-caminhando-juntos/lib/widgets/app_tile_layer.dart)
- Integrar verificação prévia do token Mapbox; se inválido, chavear instantaneamente para OSM.
- Passar identificador de provedor (`mapbox` ou `osm`) para o `LocalTileProvider`.

### Testes e Documentação
#### [NEW] [tile_provider_test.dart](file:///C:/Users/keven/StudioProjects/aplicativo-caminhando-juntos/test/tile_provider_test.dart)
- Testes unitários para classificação de erros HTTP.
- Testes para o Circuit Breaker (estados, half-open, backoff).
- Testes para o cache SQLite (hit, miss, expiração, LRU, corrupção).
#### [NEW] [app_tile_layer_test.dart](file:///C:/Users/keven/StudioProjects/aplicativo-caminhando-juntos/test/app_tile_layer_test.dart)
- Widget tests para `AppTileLayer` com token válido e inválido.
#### [NEW] [tile_architecture.md](file:///C:/Users/keven/StudioProjects/aplicativo-caminhando-juntos/.artifacts/890d2f84-6738-4e8d-b19a-7a1cce9dbabc/tile_architecture.md)
- Documentação atualizada da arquitetura de tiles, flags, TTLs e fluxo de fallback.

## Verification Plan

### Automated Tests
- Executar testes unitários e de widget via comando Flutter:
  ```bash
  flutter test test/tile_provider_test.dart test/app_tile_layer_test.dart
  ```

### Manual Verification
- Compilar e rodar o aplicativo no emulador/dispositivo.
- Verificar logs `[TileDiag]` no console de debug para validar hit/miss, status HTTP e comportamento do Circuit Breaker.
- Testar comportamento offline e com token inválido.
