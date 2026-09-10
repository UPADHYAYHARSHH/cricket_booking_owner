import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/owner_support_message_model.dart';

class OwnerSupportRepository {
  final SupabaseClient _supabase;

  OwnerSupportRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Fetches owner details and summary of venues/grounds
  Future<Map<String, dynamic>?> fetchOwnerContext() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final ownerRes = await _supabase
          .from('owner_details')
          .select()
          .eq('id', uid)
          .maybeSingle();

      final groundsRes = await _supabase
          .from('grounds')
          .select('id, name, is_available, location_id')
          .eq('owner_id', uid);

      final List<dynamic> grounds = groundsRes;

      return {
        'owner': ownerRes,
        'grounds': grounds,
        'totalGrounds': grounds.length,
        'activeGrounds': grounds.where((g) => g['is_available'] != false).length,
      };
    } catch (e) {
      debugPrint('[OwnerSupportRepository] Error fetching owner context: $e');
      return null;
    }
  }

  /// Sends a message to the support-chat-bot edge function
  Future<OwnerSupportMessageModel> sendChatMessage({
    required String message,
    String? bookingId,
    List<OwnerSupportMessageModel> conversationHistory = const [],
    String role = 'owner',
  }) async {
    final uid = currentUserId ?? 'guest_owner';

    final historyList = conversationHistory.map((m) {
      return {
        'role': m.isUser ? 'user' : 'model',
        'text': m.text,
      };
    }).toList();

    try {
      final res = await _supabase.functions.invoke(
        'support-chat-bot',
        body: {
          'user_id': uid,
          'role': role,
          'message': message,
          'booking_id': bookingId,
          'conversation_history': historyList,
        },
      );

      if (res.status == 200 && res.data != null) {
        dynamic data = res.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }

        final replyText = data['reply']?.toString() ??
            "I'm here to help with your booking and payment questions!";

        final List<String> quickReplies = [];
        if (data['quick_replies'] is List) {
          for (final qr in data['quick_replies']) {
            if (qr != null) quickReplies.add(qr.toString());
          }
        }

        final List<OwnerSupportAction> actions = [];
        if (data['actions'] is List) {
          for (final act in data['actions']) {
            if (act is Map) {
              actions.add(OwnerSupportAction.fromJson(Map<String, dynamic>.from(act)));
            }
          }
        }

        return OwnerSupportMessageModel.bot(
          text: replyText,
          quickReplies: quickReplies,
          actions: actions,
        );
      }
    } catch (e) {
      debugPrint('[OwnerSupportRepository] Edge function call failed: $e');
    }

    // Client fallback if edge function call fails
    return OwnerSupportMessageModel.bot(
      text:
          "I'm having trouble connecting to the network right now. You can reach our partner relations team directly on WhatsApp or try again shortly!",
      quickReplies: ["WhatsApp Partner Support", "Payout Schedule", "Slot Blocking Help"],
      actions: [
        OwnerSupportAction(
          type: "whatsapp_support",
          label: "WhatsApp Partner Support",
          url: "https://wa.me/919876543210?text=Hi%20TurfPro%20Partner%20Support",
        )
      ],
    );
  }
}
