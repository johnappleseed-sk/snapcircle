import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/conversations_provider.dart';
import '../widgets/conversation_skeleton_tile.dart';
import '../widgets/conversation_tile.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationsProvider>().fetchConversations(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversationsProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final horizontalPadding = MediaQuery.sizeOf(context).width < 380
        ? AppSizes.paddingSmall
        : AppSizes.paddingMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchConversations(refresh: true),
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSizes.paddingMedium,
            horizontalPadding,
            AppSizes.paddingXL,
          ),
          itemCount: _itemCount(provider),
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSizes.paddingMedium),
          itemBuilder: (context, index) {
            if (provider.isLoading && provider.conversations.isEmpty) {
              return const Column(
                children: [
                  ConversationSkeletonTile(),
                  SizedBox(height: AppSizes.paddingMedium),
                  ConversationSkeletonTile(),
                  SizedBox(height: AppSizes.paddingMedium),
                  ConversationSkeletonTile(),
                ],
              );
            }

            if (provider.errorMessage != null &&
                provider.conversations.isEmpty) {
              return ErrorView(
                message: provider.errorMessage!,
                onRetry: () => provider.fetchConversations(refresh: true),
              );
            }

            if (provider.conversations.isEmpty) {
              return const EmptyView(
                icon: Icons.chat_bubble_outline,
                title: 'No conversations yet',
                subtitle: 'Start chatting from a user profile.',
              );
            }

            if (index == provider.conversations.length) {
              if (!provider.hasMore) {
                return const SizedBox.shrink();
              }

              return AppButton(
                label: 'Load more',
                variant: AppButtonVariant.outline,
                isLoading: provider.isLoadingMore,
                onPressed: provider.isLoadingMore
                    ? null
                    : provider.loadMoreConversations,
              );
            }

            final conversation = provider.conversations[index];
            return ConversationTile(
              conversation: conversation,
              currentUserId: currentUserId,
              onTap: () => context.push(
                '/messages/${conversation.id}',
                extra: conversation,
              ),
            );
          },
        ),
      ),
    );
  }

  int _itemCount(ConversationsProvider provider) {
    if (provider.conversations.isEmpty) {
      return 1;
    }

    return provider.conversations.length + 1;
  }
}
