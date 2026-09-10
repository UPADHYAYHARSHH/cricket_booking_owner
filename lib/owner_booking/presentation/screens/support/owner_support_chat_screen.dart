import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/support/owner_support_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/support/owner_support_state.dart';
import 'package:turfpro_owner/owner_booking/data/models/owner_support_message_model.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/bookings/bookings_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/payouts/payouts_screen.dart';

class OwnerSupportChatScreen extends StatefulWidget {
  final String? initialQuery;

  const OwnerSupportChatScreen({
    super.key,
    this.initialQuery,
  });

  @override
  State<OwnerSupportChatScreen> createState() => _OwnerSupportChatScreenState();
}

class _OwnerSupportChatScreenState extends State<OwnerSupportChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
        context.read<OwnerSupportCubit>().sendMessage(widget.initialQuery!);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleAction(OwnerSupportAction action) {
    if (action.type == 'whatsapp_support' && action.url != null) {
      _launchUrl(action.url!);
    } else if (action.type == 'view_bookings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BookingsScreen()),
      );
    } else if (action.type == 'view_payouts') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PayoutsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryLightGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                size: 20,
                color: AppColors.primaryDarkGreen,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TurfPro Partner AI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Online • Instant Partner Support',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.chat_rounded,
              color: Color(0xFF25D366),
              size: 22,
            ),
            tooltip: 'WhatsApp Partner Support',
            onPressed: () => _launchUrl(
              'https://wa.me/919876543210?text=Hi%20TurfPro%20Partner%20Desk',
            ),
          ),
        ],
      ),
      body: BlocConsumer<OwnerSupportCubit, OwnerSupportState>(
        listener: (context, state) {
          if (state is OwnerSupportLoaded) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          if (state is OwnerSupportLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryDarkGreen),
              ),
            );
          }

          if (state is OwnerSupportLoaded) {
            return Column(
              children: [
                // Chat message stream
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: state.messages.length + (state.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length && state.isSending) {
                        return _buildTypingIndicator(isDark);
                      }
                      final msg = state.messages[index];
                      return _buildMessageBubble(context, msg, isDark);
                    },
                  ),
                ),

                // Quick reply chips
                if (state.currentQuickReplies.isNotEmpty)
                  _buildQuickRepliesBar(context, state.currentQuickReplies, isDark),

                // Bottom text input bar
                _buildInputBar(context, isDark, state.isSending),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    OwnerSupportMessageModel message,
    bool isDark,
  ) {
    final isUser = message.isUser;
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryDarkGreen
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: isUser
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            ),

            // Embedded Action Buttons
            if (!isUser && message.actions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: message.actions.map((act) {
                  return ActionChip(
                    avatar: act.type == 'whatsapp_support'
                        ? const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 16)
                        : const Icon(Icons.touch_app_rounded, color: AppColors.primaryDarkGreen, size: 16),
                    label: Text(
                      act.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                    backgroundColor: AppColors.primaryLightGreen.withValues(alpha: 0.15),
                    side: BorderSide(
                      color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
                    ),
                    onPressed: () => _handleAction(act),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryDarkGreen),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Partner AI is typing...',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRepliesBar(BuildContext context, List<String> quickReplies, bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final qr = quickReplies[index];
          return ActionChip(
            label: Text(
              qr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDarkGreen,
              ),
            ),
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            side: BorderSide(
              color: AppColors.primaryDarkGreen.withValues(alpha: 0.35),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () {
              context.read<OwnerSupportCubit>().sendMessage(qr);
            },
          );
        },
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark, bool isSending) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgDark : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _textController,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  enabled: !isSending,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask about payouts, slots, timer...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty && !isSending) {
                      context.read<OwnerSupportCubit>().sendMessage(val.trim());
                      _textController.clear();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primaryDarkGreen,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: isSending
                    ? null
                    : () {
                        final txt = _textController.text.trim();
                        if (txt.isNotEmpty) {
                          context.read<OwnerSupportCubit>().sendMessage(txt);
                          _textController.clear();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
