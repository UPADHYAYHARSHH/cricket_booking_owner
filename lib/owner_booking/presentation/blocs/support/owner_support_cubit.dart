import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/data/models/owner_support_message_model.dart';
import 'package:turfpro_owner/owner_booking/data/repositories/owner_support_repository.dart';
import 'owner_support_state.dart';

class OwnerSupportCubit extends Cubit<OwnerSupportState> {
  final OwnerSupportRepository _repository;

  OwnerSupportCubit({OwnerSupportRepository? repository})
      : _repository = repository ?? OwnerSupportRepository(),
        super(OwnerSupportInitial());

  Future<void> initSupport() async {
    emit(OwnerSupportLoading());

    final ownerContext = await _repository.fetchOwnerContext();

    final ownerData = ownerContext?['owner'] as Map<String, dynamic>?;
    final ownerName = ownerData?['name']?.toString() ?? 'Partner';
    final totalGrounds = ownerContext?['totalGrounds'] ?? 0;

    String initialGreeting =
        'Welcome to TurfPro Partner Support, ' + ownerName + '! 👋 How can we help you manage your turf venues and payouts today?';

    List<String> initialQuickReplies = [
      'Payout Settlement Cycle',
      'How 45m Approval Works',
      'Block Slots for Rain/Maintenance',
      'Instant Booking vs Approval',
      'WhatsApp Partner Support',
    ];

    if (totalGrounds > 0) {
      initialGreeting =
          'Hello ' + ownerName + '! 👋 You currently have ' + totalGrounds.toString() + ' turf court(s) linked to your account. What can we assist you with regarding bookings, payouts, or court availability?';
    }

    final welcomeMessage = OwnerSupportMessageModel.bot(
      text: initialGreeting,
      quickReplies: initialQuickReplies,
      actions: [
        OwnerSupportAction(
          type: 'whatsapp_support',
          label: 'Direct WhatsApp Line',
          url: 'https://wa.me/919876543210?text=Hi%20TurfPro%20Partner%20Support',
        )
      ],
    );

    emit(OwnerSupportLoaded(
      messages: [welcomeMessage],
      ownerContext: ownerContext,
      currentQuickReplies: initialQuickReplies,
    ));
  }

  Future<void> sendMessage(String text, {String? bookingId}) async {
    final currentState = state;
    if (currentState is! OwnerSupportLoaded) return;
    if (text.trim().isEmpty) return;

    final userMessage = OwnerSupportMessageModel.user(text: text.trim());
    final updatedMessages = List<OwnerSupportMessageModel>.from(currentState.messages)
      ..add(userMessage);

    emit(currentState.copyWith(
      messages: updatedMessages,
      isSending: true,
      currentQuickReplies: [],
    ));

    final botReply = await _repository.sendChatMessage(
      message: text.trim(),
      bookingId: bookingId,
      conversationHistory: updatedMessages,
    );

    final finalMessages = List<OwnerSupportMessageModel>.from(updatedMessages)
      ..add(botReply);

    emit(currentState.copyWith(
      messages: finalMessages,
      isSending: false,
      currentQuickReplies: botReply.quickReplies,
    ));
  }
}
