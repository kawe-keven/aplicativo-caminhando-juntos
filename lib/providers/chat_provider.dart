import 'package:caminhandojuntos/models/chat_message.dart';
import 'package:caminhandojuntos/services/chat_api_client.dart';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  const ChatState({
    required this.messages,
    this.isLoading = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatApiClient _apiClient = ChatApiClient();

  ChatNotifier() : super(ChatState(messages: [
    ChatMessage(
      id: 'welcome_msg',
      text: 'Olá! Sou o seu assistente virtual de IA do Caminhando Juntos. Como posso ajudar você hoje com suas caminhadas, rotas ou orientações?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]));

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      errorMessage: null,
    );

    try {
      final history = state.messages.sublist(0, state.messages.length - 1).map((m) => m.toJson()).toList();
      
      final response = await _apiClient.sendMessage(text.trim(), history: history);
      
      final replyText = response['reply'] ?? response['response'] ?? response['message'] ?? 'Desculpe, não consegui processar a resposta.';

      final botMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: replyText.toString(),
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, botMessage],
        isLoading: false,
      );
    } catch (e) {
      AppLogger.e('Erro ao enviar mensagem para o chatbot', e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível conectar com o assistente. Verifique sua conexão.',
      );
    }
  }

  void clearChat() {
    state = ChatState(messages: [
      ChatMessage(
        id: 'welcome_msg',
        text: 'Conversa reiniciada. Como posso ajudar você agora?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ]);
  }
}
