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
  bool _canSendMessage = false;

  @override
  void initState() {
    super.initState();
    _conversation = widget.initialConversation;
    _messageController.addListener(_handleComposerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().fetchMessages(
        widget.conversationId,
        refresh: true,
      );
      _fetchConversation();
    });
  }

  @override
  void dispose() {
    context.read<MessagesProvider>().clearConversation();
    _messageController.removeListener(_handleComposerChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _handleComposerChanged() {
    final canSend = _messageController.text.trim().isNotEmpty;
    if (canSend == _canSendMessage) {
      return;
    }

    setState(() => _canSendMessage = canSend);
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
        centerTitle: false,
        title: Row(
          children: [
            AppAvatar(
              name: otherUser?.name ?? 'Chat',
              imageUrl: otherUser?.avatar,
              size: AppAvatarSize.small,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser?.name ??
                        (_isLoadingConversation ? 'Loading...' : 'Messages'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Online now',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _fetchConversation();
              if (context.mounted) {
                await messagesProvider.fetchMessages(
                  widget.conversationId,
                  refresh: true,
                );
              }
            },
            icon: const Icon(Icons.refresh_rounded),
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
              canSend: _canSendMessage,
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
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSizes.paddingMedium,
        horizontalPadding,
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
  final bool canSend;
  final VoidCallback onSend;
  final String? errorMessage;

  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.canSend,
    required this.onSend,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppSizes.paddingSmall,
          horizontalPadding,
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
                Container(
                  height: 48,
                  width: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !isSending,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      labelText: 'Message',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMedium,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSmall),
                SizedBox.square(
                  dimension: 48,
                  child: IconButton.filled(
                    onPressed: isSending || !canSend ? null : onSend,
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
