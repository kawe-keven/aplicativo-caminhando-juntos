# 🚶‍♂️ Caminhando Juntos (CaminhaJuntos)

> **Aplicativo de gamificação de exercícios físicos voltado para idosos, com foco em acessibilidade, rastreamento via GPS e recompensas.**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Java](https://img.shields.io/badge/Java-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)](https://www.oracle.com/java/)
[![License](https://img.shields.io/badge/License-MIT-blue.style=for-the-badge)](#licença)

---

## 📱 Sobre o Projeto

O **Caminhando Juntos** é um aplicativo mobile desenvolvido para incentivar a prática regular de caminhadas e exercícios físicos na terceira idade (público 60+, com foco no MVP a partir de 50 anos). 

O projeto combate o sedentarismo combinando **design com alta acessibilidade visual e motora** a um **sistema de gamificação**: os passos e distâncias percorridas são convertidos em moedas virtuais, que podem ser trocadas por vantagens e créditos em jogos parceiros (como *Candy Crush*).

### 🌟 Diferenciais & Acessibilidade
* **UI/UX adaptada:** Botões amplos, alto contraste, navegação simplificada e prevenção de cliques acidentais.
* **Incentivo e Gamificação:** Conquistas, acompanhamento do progresso e loja de recompensas.
* **Exercícios Guiados:** Atividades complementares adaptadas para a faixa etária.

---

## 🛠️ Stack Tecnológica

* **Front-end / Mobile:** [Flutter](https://flutter.dev/) (Dart)
* **Gerenciamento de Estado:** State Management nativo / Reactive patterns
* **Mapas & Geolocalização:** `geolocator` + `flutter_map` ([OpenStreetMap](https://www.openstreetmap.org/) — *100% gratuito e open-source*)
* **Persistência Local:** `shared_preferences`
* **APIs de Terceiros:** [Open-Meteo API](https://open-meteo.com/) (Clima/Temperatura em tempo real)
* **Back-end:** Java REST API (módulo externo e independente)

---

## 📸 Funcionalidades Integradas (MVP)

- [x] **Onboarding Acessível:** Fluxo de boas-vindas com validação e máscaras de dados (Nome, Telefone brasileiro, Seletor de Idade).
- [x] **Dashboard Principal:** Exibição da data local do dispositivo, previsão do tempo atualizada e métricas de passos/moedas.
- [x] **Rastreamento via GPS:** Diagnóstico e cálculo de distância percorrida em tempo real via algoritmo Haversine com filtros anti-spoofing.
- [x] **Persistência do Usuário:** Sessão mantida localmente para evitar múltiplos cadastros ao reabrir o app.
- [x] **Loja de Recompensas:** Interface de troca de moedas virtuais por benefícios em jogos parceiros.
- [x] **Otimizações de UI/Performance:** Cache inteligente de imagens (`cached_network_image`), transições fluidas e ícones customizados (`flutter_launcher_icons`).

---

## 🏗️ Arquitetura e Segurança

O aplicativo opera em uma estrutura **Client-Server**:
```text
 ┌─────────────────────────┐               ┌─────────────────────────┐
 │   Flutter Mobile App    │  HTTPS / REST │    Backend Server       │
 │      (Client-side)      ├───────────────►│         (Java)          │
 │  - Interface e Sensores │               │  - Regras de Negócio    │
 │  - Rastreamento por GPS │◄──────────────┤  - Validação de Moedas  │
 └─────────────────────────┘               └─────────────────────────┘
