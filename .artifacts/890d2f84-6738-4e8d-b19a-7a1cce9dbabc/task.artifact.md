# Tarefas de Refatoração da Arquitetura de Map Tiles

- [ ] 1. Refatorar `MapTileCache` para suportar WAL, transações atômicas, chave composta por provedor e política LRU robusta.
- [ ] 2. Implementar classificação de erros HTTP (`TileHttpResultType`) e Circuit Breaker por provedor com estados `closed`/`open`/`halfOpen` e backoff exponencial.
- [ ] 3. Refatorar `LocalTileProvider` com tratamento de erros permanentes vs transitórios, User-Agent adequado para OSM e logs `[TileDiag]` estruturados.
- [ ] 4. Atualizar `AppTileLayer` e `MapboxConfig` para fallback imediato em caso de token inválido.
- [ ] 5. Criar testes unitários e de widget abrangentes (`tile_provider_test.dart`, `app_tile_layer_test.dart`).
- [ ] 6. Criar documentação técnica da arquitetura de tiles atualizada.
- [ ] 7. Verificar compilação, executar testes e validar em ambiente de execução.
