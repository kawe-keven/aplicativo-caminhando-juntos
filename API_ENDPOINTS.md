# Documento Técnico de Contrato de API — Aplicativo Caminhando Juntos

## 1. Visão Geral
- **Nome do Projeto:** Caminhando Juntos
- **Base URL:** `https://api.caminhandojuntos.com.br/v1` (configurável via `--dart-define=BACKEND_URL=...`)
- **Versionamento:** `/v1` na URL base
- **Formato de Requisição/Resposta:** `application/json`
- **Padrão de Datas:** Milissegundos desde a Epoch (Unix timestamp `_ms`) e strings ISO 8601 para logs/auditoria.
- **Convenção de Nomes:** `snake_case` nos payloads de sincronização/banco local e `camelCase` nas entidades gerais.

## 2. Autenticação e Autorização
- **Mecanismo:** Bearer Token JWT (`Authorization: Bearer <token>`).
- **Armazenamento no Cliente:** `FlutterSecureStorage` (`auth_token`).
- **Perfis de Usuário:**
  - `USUARIO_IDOSO`: Acesso completo ao rastreamento de caminhadas, resgate de recompensas, visualização de progresso e botão de emergência.
  - `CUIDADOR`: Acesso monitorado a progresso e alertas de emergência.
  - `ADMIN`: Gestão de recompensas e relatórios.

## 3. Padrões Globais
- **Códigos de Status HTTP:**
  - `200 OK`: Sucesso em operações de leitura/atualização.
  - `201 Created`: Recurso criado com sucesso.
  - `400 Bad Request`: Dados inválidos ou malformados.
  - `401 Unauthorized`: Token ausente ou inválido.
  - `403 Forbidden`: Acesso negado ao recurso.
  - `404 Not Found`: Recurso não encontrado.
  - `422 Unprocessable Entity`: Falha de validação de negócios.
  - `500 Internal Server Error`: Erro interno no servidor.
- **Tratamento de Sessão Expirada:** Respostas `401` ou `403` disparam `SessaoExpiradaException` no app, exigindo novo login.

## 4. Endpoints Agrupados por Módulo

### 4.1 Módulo de Autenticação / Usuário
#### `POST /api/v1/auth/login`
- **Status:** [SUGERIDO]
- **Descrição:** Autentica o usuário idoso/cuidador e retorna o token JWT e dados do perfil.
- **Autenticação:** Não necessária.
- **Request Body (JSON):**
  ```json
  {
    "phone": "(11) 98765-4321",
    "pin": "1234"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1...",
    "user": {
      "name": "Maria Silva",
      "age": 68,
      "isRegistered": true
    }
  }
  ```

#### `POST /api/v1/users/register`
- **Status:** [SUGERIDO]
- **Descrição:** Cadastra o perfil inicial do usuário e contatos de emergência.
- **Autenticação:** Sim (Bearer Token).
- **Request Body (JSON):**
  ```json
  {
    "name": "Maria Silva",
    "age": 68,
    "emergencyContacts": [
      {
        "name": "João Silva",
        "phone": "(11) 91234-5678"
      }
    ]
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "Usuário cadastrado com sucesso"
  }
  ```

### 4.2 Módulo de Caminhadas e Rastreamento (Offline-First)
#### `POST /api/caminhada/sync`
- **Status:** [EXISTENTE]
- **Descrição:** Sincroniza em lote os dados de uma caminhada concluída (incluindo rotas e coordenadas GPS coletadas offline pelo app). Utilizado pelo app client e pelo `SyncWorker` em background.
- **Autenticação:** Sim (`Authorization: Bearer <token>`).
- **Headers:** `Content-Type: application/json`
- **Request Body (JSON):**
  ```json
  {
    "id": "c1a2b3c4-5d6e-7f8a-9b0c-1d2e3f4a5b6c",
    "inicio_ms": 1720000000000,
    "fim_ms": 1720001800000,
    "tempo_ativo_ms": 1750000,
    "pontos": [
      {
        "lat": -23.5505,
        "lng": -46.6333,
        "precisao": 5.2,
        "suspeito": 0,
        "timestamp_ms": 1720000005000
      }
    ]
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "validated_distance_km": 1.5,
    "validated_coins": 15
  }
  ```
- **Erros Possíveis:** `400` (Payload inválido), `401`/`403` (Token expirado), `422` (Caminhada rejeitada por inconsistência de dados), `500` (Erro no servidor).

### 4.3 Módulo de Recompensas e Loja
#### `POST /api/rewards/redeem`
- **Status:** [EXISTENTE]
- **Descrição:** Resgata uma recompensa utilizando as moedas acumuladas pelo usuário.
- **Autenticação:** Sim (`Authorization: Bearer <token>`).
- **Request Body (JSON):**
  ```json
  {
    "reward_id": "rew_01",
    "cost": 50
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "coins": 150
  }
  ```
- **Regra de Negócio Crítica (Backend):** O servidor deve validar o saldo atual de moedas do usuário de forma autoritativa antes de debitar e retornar o novo saldo para evitar fraudes ou duplicações no cliente.

#### `GET /api/v1/rewards`
- **Status:** [SUGERIDO]
- **Descrição:** Lista as recompensas disponíveis para resgate na loja.
- **Autenticação:** Sim.
- **Response (200 OK):**
  ```json
  {
    "rewards": [
      {
        "id": "rew_01",
        "title": "Desconto em Farmácia",
        "description": "10% de desconto em medicamentos",
        "cost": 50,
        "imageUrl": "https://..."
      }
    ]
  }
  ```

### 4.4 Módulo de Progresso e Conquistas
#### `GET /api/v1/user/progress`
- **Status:** [SUGERIDO]
- **Descrição:** Obtém o progresso consolidado do usuário (passos, distância, moedas, calorias).
- **Autenticação:** Sim.
- **Response (200 OK):**
  ```json
  {
    "steps": 3500,
    "goalSteps": 5000,
    "coins": 120,
    "distanceKm": 2.4,
    "durationMinutes": 35,
    "calories": 140
  }
  ```

#### `GET /api/v1/achievements`
- **Status:** [SUGERIDO]
- **Descrição:** Lista as conquistas desbloqueadas e disponíveis pelo usuário.
- **Autenticação:** Sim.
- **Response (200 OK):**
  ```json
  {
    "achievements": [
      {
        "id": "ach_01",
        "title": "Primeiros Passos",
        "description": "Complete sua primeira caminhada",
        "isUnlocked": true,
        "unlockedAt": 1720000000000
      }
    ]
  }
  ```

---

## 5. Modelos de Dados (Schemas)

### `UserModel`
- `name` (String, Obrigatório)
- `age` (Integer, Obrigatório, min: 1, max: 120)
- `emergencyContacts` (List<EmergencyContact>, Opcional)
- `isRegistered` (Boolean, Obrigatório)

### `EmergencyContact`
- `name` (String, Obrigatório)
- `phone` (String, Obrigatório)

### `CoordinateModel` (Ponto GPS)
- `latitude` (Double, Obrigatório)
- `longitude` (Double, Obrigatório)
- `timestamp` (DateTime / ms, Obrigatório)
- `accuracy` (Double, Obrigatório)
- `isSuspect` (Boolean, Obrigatório)

### `UserProgress`
- `steps` (Integer)
- `goalSteps` (Integer)
- `coins` (Integer)
- `distanceKm` (Double)
- `durationMinutes` (Integer)
- `calories` (Integer)

---

## 6. Regras de Negócio Relevantes para o Backend
1. **Validação de Moedas (Redeem):** O backend é a fonte da verdade para o saldo de moedas (`coins`). O cliente envia o `reward_id` e o `cost`, mas o backend deve recalcular/verificar se o usuário possui saldo suficiente antes de efetivar o débito.
2. **Filtragem de GPS Suspeito:** O cliente marca pontos com `accuracy > 15` como suspeitos (`isSuspect = 1`). O backend pode optar por ignorar esses pontos ao recalcular a distância oficial da caminhada.
3. **Auto-finalização e Sincronização Offline:** Caminhadas iniciadas offline são armazenadas localmente em SQLite e sincronizadas em lote (`/api/caminhada/sync`) via `Workmanager` em background quando a conectividade é restabelecida.

---

## 7. Uploads, Notificações Push e Integrações Externas
- **Clima (Open-Meteo):** O app consome diretamente a API pública `https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true` para exibir a temperatura atual.
- **Background Sync:** Utiliza `Workmanager` para disparar tarefas periódicas de sincronização offline para o endpoint `/api/caminhada/sync`.
- **Notificações Push:** [SUGERIDO] O backend deve integrar FCM (Firebase Cloud Messaging) para enviar alertas de lembrete de caminhada e avisos de emergência para cuidadores.

---

## 8. Pontos em Aberto
- Qual será o mecanismo oficial de autenticação por SMS/Telefone ou OAuth2 implementado no backend Java?
- Como o backend calcula oficialmente as calorias e os passos a partir das coordenadas GPS brutas enviadas no sync?

---

## 9. Tabela Resumo

| Método | Caminho | Descrição | Status |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/v1/auth/login` | Autenticação de usuário | [SUGERIDO] |
| `POST` | `/api/v1/users/register` | Cadastro de perfil e contatos | [SUGERIDO] |
| `POST` | `/api/caminhada/sync` | Sincronização em lote de caminhadas | [EXISTENTE] |
| `POST` | `/api/rewards/redeem` | Resgate de recompensas na loja | [EXISTENTE] |
| `GET` | `/api/v1/rewards` | Listagem de recompensas | [SUGERIDO] |
| `GET` | `/api/v1/user/progress` | Consulta de progresso do usuário | [SUGERIDO] |
| `GET` | `/api/v1/achievements` | Listagem de conquistas | [SUGERIDO] |
