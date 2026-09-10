class OwnerSupportAction {
  final String type;
  final String label;
  final String? url;
  final String? bookingId;

  OwnerSupportAction({
    required this.type,
    required this.label,
    this.url,
    this.bookingId,
  });

  factory OwnerSupportAction.fromJson(Map<String, dynamic> json) {
    return OwnerSupportAction(
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      url: json['url']?.toString(),
      bookingId: json['booking_id']?.toString(),
    );
  }
}

class OwnerSupportMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> quickReplies;
  final List<OwnerSupportAction> actions;

  OwnerSupportMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickReplies = const [],
    this.actions = const [],
  });

  factory OwnerSupportMessageModel.bot({
    required String text,
    List<String> quickReplies = const [],
    List<OwnerSupportAction> actions = const [],
  }) {
    return OwnerSupportMessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      quickReplies: quickReplies,
      actions: actions,
    );
  }

  factory OwnerSupportMessageModel.user({required String text}) {
    return OwnerSupportMessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }
}
