import 'dart:convert';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final List<MediaRef>? mediaRefs;

  ChatMessage({
    required this.role,
    required this.content,
    this.mediaRefs,
  });

  Map<String, String> toHistoryMap() {
    return {'role': role, 'content': content};
  }
}

class MediaRef {
  final String title;
  final String id;
  final String type; // 'ANIME' or 'MANGA'
  final String? cover;
  final String service; // 'anilist' or 'mal'

  MediaRef({
    required this.title,
    required this.id,
    required this.type,
    this.cover,
    required this.service,
  });

  factory MediaRef.fromJson(Map<String, dynamic> json) {
    return MediaRef(
      title: json['title'] as String? ?? '',
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'ANIME',
      cover: json['cover'] as String?,
      service: json['service'] as String? ?? 'anilist',
    );
  }
}

class AiAdvisorService extends GetxController {
  static const String baseUrl = 'http://217.60.25.118:3002';
  static const String apiKey = 'xK9mP2vL7nQ4wR8';

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;

  String? _getPlatform() {
    final serviceType = serviceHandler.serviceType.value;
    switch (serviceType) {
      case ServicesType.anilist:
        return 'anilist';
      case ServicesType.mal:
        return 'mal';
      default:
        return null;
    }
  }

  String? _getToken() {
    final serviceType = serviceHandler.serviceType.value;
    if (serviceType == ServicesType.anilist) {
      return AuthKeys.authToken.get<String?>();
    } else if (serviceType == ServicesType.mal) {
      return AuthKeys.malAuthToken.get<String?>();
    }
    return null;
  }

  List<Map<String, String>> _buildConversationHistory() {
    return messages.map((msg) => msg.toHistoryMap()).toList();
  }

  Future<void> sendMessage(String question) async {
    final platform = _getPlatform();
    final token = _getToken();

    if (platform == null || token == null) {
      Logger.i('AI Advisor: No platform or token available');
      return;
    }

    // Add user message to chat
    messages.add(ChatMessage(role: 'user', content: question));

    isLoading.value = true;

    try {
      final conversationHistory = _buildConversationHistory();
      // Send history excluding the user message just added (backend treats question separately)
      final historyToSend = conversationHistory.length > 1
          ? conversationHistory.sublist(0, conversationHistory.length - 1)
          : <Map<String, String>>[];

      final response = await http.post(
        Uri.parse('$baseUrl/api/advise'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': apiKey,
        },
        body: jsonEncode({
          'platform': platform,
          'token': token,
          'question': question,
          'conversation_history': historyToSend,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final answer = data['answer'] as String? ?? 'No response received.';
        final mediaRefsRaw = data['media_refs'] as List<dynamic>? ?? [];

        final mediaRefs = mediaRefsRaw
            .map((ref) => MediaRef.fromJson(ref as Map<String, dynamic>))
            .toList();

        messages.add(ChatMessage(
          role: 'assistant',
          content: answer,
          mediaRefs: mediaRefs,
        ));
      } else {
        Logger.i('AI Advisor API error: ${response.statusCode} ${response.body}');
        messages.add(ChatMessage(
          role: 'assistant',
          content:
              'Sorry, something went wrong. Please try again. (Error ${response.statusCode})',
        ));
      }
    } catch (e) {
      Logger.i('AI Advisor error: $e');
      messages.add(ChatMessage(
        role: 'assistant',
        content:
            'Failed to get a response. Please check your connection and try again.',
      ));
    } finally {
      isLoading.value = false;
    }
  }

  void clearChat() {
    messages.clear();
  }
}
