# Auditoria de Segurança e Integração Backend

Este documento detalha os riscos de segurança identificados na integração entre o aplicativo Flutter e o backend Java, além das correções aplicadas para garantir a integridade dos dados e prevenir fraudes.

## 1. Autenticação e Sessão (Escopo 1 - Somente Análise)

### O que foi encontrado
Atualmente, o aplicativo não possui campos de autenticação (token JWT ou similares) no `UserModel`. O estado de login é controlado apenas pela flag booleana `isRegistered`.

### Nível de Risco: CRÍTICO
A ausência de autenticação baseada em tokens permite que qualquer usuário com acesso ao dispositivo (ou via inspeção de tráfego se as rotas forem descobertas) possa manipular o estado do aplicativo.

### Recomendações Futuras de Login
- **Armazenamento Seguro:** Migrar o armazenamento de dados sensíveis e tokens de `shared_preferences` para `flutter_secure_storage` para proteger contra leitura direta em dispositivos com root/jailbreak.
- **Implementação de JWT:** O backend Java deve fornecer um token JWT com tempo de expiração curto e um Refresh Token.
- **Headers de Autorização:** Todas as requisições devem incluir o header `Authorization: Bearer <token>`.

---

## 2. Validação de Regras de Negócio (Escopo 2)

### O que foi encontrado
O aplicativo está calculando o ganho de moedas (`coinsEarned`) e o saldo (`coins`) inteiramente no lado do cliente (`tracking_provider.dart` e `dashboard_provider.dart`).

### Nível de Risco: ALTO
Como as moedas são trocadas por benefícios reais, um usuário mal-intencionado pode alterar o código Dart ou interceptar a memória para "ganhar" moedas infinitas sem caminhar.

### Correções Aplicadas
- Refatoração da lógica para que o app envie apenas os dados brutos (distância e tempo) ao "finalizar" a caminhada, aguardando a confirmação do saldo final vinda do backend (simulado via serviço por enquanto).

---

## 3. Comunicação de Rede (Escopo 3)

### O que foi encontrado
O app utiliza o pacote `http`. Não há uma URL base definida centralmente.

### Nível de Risco: MÉDIO
Risco de ataques Man-in-the-Middle (MITM) se a comunicação for feita via HTTP puro.

### Correções Aplicadas
- Criação do `BaseApiService` que força o uso de HTTPS e centraliza o tratamento de erros.

---

## 4. Chaves de API e Endpoints (Escopo 5)

### O que foi encontrado
URLs e chaves (como a da API de clima) estão espalhadas pelo código.

### Nível de Risco: BAIXO
Dificulta a manutenção e a troca de ambientes (Dev/Prod).

### Correções Aplicadas
- Centralização das configurações no `lib/config/api_config.dart`.

---

## 5. Rate Limiting e Prevenção de Abuso (Escopo 6)

### O que foi encontrado
Os botões de resgate de prêmio não possuem proteção contra múltiplos cliques rápidos.

### Nível de Risco: BAIXO
Múltiplos cliques podem gerar múltiplas requisições de débito de saldo se o backend não tiver idempotência.

### Correções Aplicadas
- Implementação de um estado de "loading" no `dashboardProvider` para desabilitar o botão durante a operação.

---

# Proposta de Mudanças

### [Componente] Segurança e Configuração

#### [NEW] [api_config.dart](file:///C:/Users/keven/StudioProjects/caminhandojuntos/lib/config/api_config.dart)
Criação de classe de configuração centralizada.

#### [NEW] [base_api_service.dart](file:///C:/Users/keven/StudioProjects/caminhandojuntos/lib/services/base_api_service.dart)
Serviço base para chamadas HTTPS seguras.

#### [MODIFY] [dashboard_provider.dart](file:///C:/Users/keven/StudioProjects/caminhandojuntos/lib/providers/dashboard_provider.dart)
Adição de proteção contra múltiplos cliques e remoção de cálculos sensíveis.

#### [MODIFY] [tracking_provider.dart](file:///C:/Users/keven/StudioProjects/caminhandojuntos/lib/providers/tracking_provider.dart)
Remoção do cálculo de moedas no lado do cliente.

## Plano de Verificação

### Testes Manuais
- Verificar se o botão de resgate fica desabilitado após o primeiro clique.
- Confirmar se todas as chamadas de rede (ex: clima) continuam funcionando via HTTPS.
- Simular falha de rede e verificar se a mensagem de erro é amigável (sem stack trace Java).
