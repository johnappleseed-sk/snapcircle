import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/conversation_repository.dart';
import '../models/conversation_model.dart';
import '../providers/conversations_provider.dart';
import '../providers/messages_provider.dart';
import '../widgets/message_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final int conversationId;
  final ConversationModel? initialConversation;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    this.initialConversation,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _conversationRepository = ConversationRepository();
  ConversationModel? _conversation;
  bool _isLoadingConversation = false;

  @override
  void initState() {
    super.initState();
    _conversation = widget.initialConversation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().fetchMessages(
        widget.conversationId,
        refresh: true,
      );
      if (_conversation == null) {
        _fetchConversation();
      }
    });
  }

  @override
  void dispose() {
    context.read<MessagesProvider>().clearConversation();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchConversation() async {
    setState(() => _isLoadingConversation = true);
    try {
      final conversation = await _conversationRepository.getConversation(
        widget.conversationId,
      );
      if (mounted) {
        setState(() => _conversation = conversation);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingConversation = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final sent = await context.read<MessagesProvider>().sendMessage(text);
    if (!mounted || sent == null) {
      return;
    }

    _messageController.clear();
    context.read<ConversationsProvider>().updateLatestMessage(
      widget.conversationId,
      sent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final otherUser = _conversation?.otherParticipant(currentUserId);
    final messagesProvider = context.watch<MessagesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AppAvatar(
              name: otherUser?.name ?? 'Chat',
              imageUrl: otherUser?.avatar,
              size: AppAvatarSize.small,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                otherUser?.name ??
                    (_isLoadingConversation ? 'Loading...' : 'Messages'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => messagesProvider.fetchMessages(
              widget.conversationId,
              refresh: true,
            ),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh messages',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => messagesProvider.fetchMessages(
                  widget.conversationId,
                  refresh: true,
                ),
                child: _MessagesBody(conversationId: widget.conversationId),
              ),
            ),
            _MessageComposer(
              controller: _messageController,
              isSending: messagesProvider.isSending,
              onSend: _sendMessage,
              errorMessage: messagesProvider.errorMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesBody extends StatelessWidget {
  final int conversationId;

  const _MessagesBody({required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessagesProvider>();

    if (provider.isLoading) {
      return const LoadingView(message: 'Loading messages...');
    }

    if (provider.errorMessage != null && provider.messages.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        children: [
          const SizedBox(height: 96),
          ErrorView(
            message: provider.errorMessage!,
            onRetry: () =>
                provider.fetchMessages(conversationId, refresh: true),
          ),
        ],
      );
    }

    if (provider.messages.isEmpty) {
      return const _ScrollableEmptyChat();
    }

    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingLarge,
      ),
      itemCount: provider.messages.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == provider.messages.length) {
          if (!provider.hasMore) {
            return const SizedBox.shrink();
          }

          return AppButton(
            label: 'Load older messages',
            variant: AppButtonVariant.outline,
            isLoading: provider.isLoadingMore,
            onPressed: provider.isLoadingMore
                ? null
                : provider.loadMoreMessages,
          );
        }

        return MessageBubble(message: provider.messages[index]);
      },
    );
  }
}

class _ScrollableEmptyChat extends StatelessWidget {
  const _ScrollableEmptyChat();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      children: const [
        SizedBox(height: 120),
        EmptyView(
          icon: Icons.chat_bubble_outline,
          title: 'No messages yet. Say hello!',
          subtitle: 'Send the first message to start this conversation.',
        ),
      ],
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final String? errorMessage;

  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSizes.paddingMedium,
          AppSizes.paddingSmall,
          AppSizes.paddingMedium,
          AppSizes.paddingSmall + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorMessage != null) ...[
              Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !isSending,
                    decoration: const InputDecoration(
                      hintText: 'Write a message...',
                      labelText: 'Message',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: isSending ? null : onSend,
                  icon: isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  tooltip: 'Send message',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
