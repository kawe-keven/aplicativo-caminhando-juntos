# 🚶‍♂️ CaminhaJuntos - Saúde e Gamificação para a Melhor Idade

O **CaminhaJuntos** é um aplicativo mobile desenvolvido com **Flutter** focado em incentivar a atividade física para idosos. Através de um sistema de recompensas (moedas virtuais) ganhas por passos reais, o app transforma a caminhada diária em uma experiência social, segura e gratificante.

---

## 🚀 Principais Funcionalidades

-   **Rastreamento em Tempo Real:** Monitoramento de passos, distância e tempo usando GPS de alta precisão.
-   **Mapas Gratuitos e Offline:** Integração com OpenStreetMap para exibição do percurso sem custos de API.
-   **Loja de Recompensas:** Troca de moedas acumuladas por itens em jogos parceiros ou benefícios reais.
-   **Acessibilidade Nativa:** Suporte total para aumento de fontes, alto contraste e comandos de voz (TTS).
-   **Segurança em Primeiro Lugar:** Botão de emergência (SOS) configurável com contatos familiares de confiança.
-   **Cadastro Inteligente:** Fluxo simplificado e persistência de dados local para início rápido.

---

## 🛠️ Tecnologias Utilizadas

-   **Framework:** [Flutter](https://flutter.dev) (v3.44+)
-   **Gerenciamento de Estado:** [Riverpod](https://riverpod.dev)
-   **Navegação:** [GoRouter](https://pub.dev/packages/go_router) (com StatefulShellRoute)
-   **Persistência:** [Shared Preferences](https://pub.dev/packages/shared_preferences)
-   **Geolocalização:** [Geolocator](https://pub.dev/packages/geolocator)
-   **Mapas:** [Flutter Map](https://pub.dev/packages/flutter_map) + OpenStreetMap
-   **Cache de Imagens:** [Cached Network Image](https://pub.dev/packages/cached_network_image)
-   **Backend (Integração):** Estrutura preparada para integração com Backend Java/Spring Boot (API REST).

---

## 🏗️ Arquitetura do Projeto

O projeto segue os princípios de **Clean Architecture** e **SOLID**, garantindo manutenibilidade e escalabilidade:

```text
lib/
 ├── config/      # Configurações de API e ambiente
 ├── models/      # Modelos de dados e entidades
 ├── providers/   # Lógica de negócio e estado (Riverpod)
 ├── routes/      # Definição de rotas e navegação
 ├── screens/     # Widgets de tela (UI principal)
 ├── services/    # Serviços de rede e persistência
 ├── theme/       # Estilização global e cores
 └── widgets/     # Componentes reutilizáveis
```

---

## 📦 Como Executar o Projeto

### Pré-requisitos
-   Flutter SDK instalado e configurado.
-   Um emulador Android/iOS ou dispositivo físico conectado.

### Passo a Passo
1.  Clone o repositório:
    ```bash
    git clone https://github.com/kawe-keven/aplicativo-caminhando-juntos.git
    ```
2.  Entre na pasta do projeto:
    ```bash
    cd aplicativo-caminhando-juntos
    ```
3.  Instale as dependências:
    ```bash
    flutter pub get
    ```
4.  Execute o aplicativo:
    ```bash
    flutter run
    ```

---

## 🛡️ Segurança e Integridade

O aplicativo foi desenvolvido seguindo rigorosas auditorias de segurança:
-   **Cálculo Server-Side:** A lógica de geração de moedas é validada pelo backend para evitar fraudes.
-   **Proteção de UI:** Botões com travas de estado para evitar requisições duplicadas.
-   **Tratamento de Erros:** Erros técnicos de backend são mascarados para o usuário final, exibindo apenas mensagens amigáveis.

---

## 👥 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir uma **Issue** ou enviar um **Pull Request**.

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

*Desenvolvido com ❤️ por [Kawê Keven](https://github.com/kawe-keven)*
