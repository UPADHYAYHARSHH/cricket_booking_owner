import 'package:turfpro_owner/owner_booking/data/models/owner_support_message_model.dart';

abstract class OwnerSupportState {}

class OwnerSupportInitial extends OwnerSupportState {}

class OwnerSupportLoading extends OwnerSupportState {}

class OwnerSupportLoaded extends OwnerSupportState {
  final List<OwnerSupportMessageModel> messages;
  final Map<String, dynamic>? ownerContext;
  final bool isSending;
  final List<String> currentQuickReplies;

  OwnerSupportLoaded({
    required this.messages,
    this.ownerContext,
    this.isSending = false,
    this.currentQuickReplies = const [],
  });

  OwnerSupportLoaded copyWith({
    List<OwnerSupportMessageModel>? messages,
    Map<String, dynamic>? ownerContext,
    bool? isSending,
    List<String>? currentQuickReplies,
  }) {
    return OwnerSupportLoaded(
      messages: messages ?? this.messages,
      ownerContext: ownerContext ?? this.ownerContext,
      isSending: isSending ?? this.isSending,
      currentQuickReplies: currentQuickReplies ?? this.currentQuickReplies,
    );
  }
}

class OwnerSupportError extends OwnerSupportState {
  final String message;

  OwnerSupportError(this.message);
}
