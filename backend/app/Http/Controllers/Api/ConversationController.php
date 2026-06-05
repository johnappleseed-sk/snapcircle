<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\StartConversationRequest;
use App\Http\Resources\ConversationResource;
use App\Models\Conversation;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ConversationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $perPage = Pagination::perPage($request);

        $conversations = Conversation::query()
            ->whereHas('users', fn ($query) => $query->where('users.id', $request->user()->id))
            ->with(['users.setting', 'latestMessage.sender.setting'])
            ->withCount([
                'messages as unread_count' => fn ($query) => $query
                    ->where('sender_id', '!=', $request->user()->id)
                    ->whereNull('read_at'),
            ])
            ->latest('updated_at')
            ->paginate($perPage);

        return ApiResponse::paginated(
            'Conversations fetched successfully',
            'conversations',
            $conversations,
            ConversationResource::collection($conversations->items())
        );
    }

    public function store(StartConversationRequest $request): JsonResponse
    {
        $authUserId = $request->user()->id;
        $otherUserId = (int) $request->integer('user_id');

        $conversation = $this->findOneToOneConversation($authUserId, $otherUserId);
        if ($conversation === null) {
            $conversation = DB::transaction(function () use ($authUserId, $otherUserId): Conversation {
                $conversation = Conversation::query()->create();
                $conversation->users()->attach([$authUserId, $otherUserId]);

                return $conversation;
            });
        }

        $conversation->load(['users.setting', 'latestMessage.sender.setting']);
        $conversation->loadCount([
            'messages as unread_count' => fn ($query) => $query
                ->where('sender_id', '!=', $authUserId)
                ->whereNull('read_at'),
        ]);

        return ApiResponse::success('Conversation ready', [
            'conversation' => ConversationResource::make($conversation),
        ], 201);
    }

    public function show(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $conversation->load(['users.setting', 'latestMessage.sender.setting']);
        $conversation->loadCount([
            'messages as unread_count' => fn ($query) => $query
                ->where('sender_id', '!=', $request->user()->id)
                ->whereNull('read_at'),
        ]);

        return ApiResponse::success('Conversation fetched successfully', [
            'conversation' => ConversationResource::make($conversation),
        ]);
    }

    public function destroy(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('delete', $conversation);

        return ApiResponse::success('Conversation delete is not implemented for the MVP', [
            'conversation_id' => $conversation->id,
        ]);
    }

    private function findOneToOneConversation(int $authUserId, int $otherUserId): ?Conversation
    {
        $conversationId = DB::table('conversation_user')
            ->select('conversation_id')
            ->whereIn('user_id', [$authUserId, $otherUserId])
            ->groupBy('conversation_id')
            ->havingRaw('count(distinct user_id) = 2')
            ->value('conversation_id');

        if ($conversationId === null) {
            return null;
        }

        $conversation = Conversation::query()
            ->whereKey($conversationId)
            ->withCount('users')
            ->first();

        if ($conversation?->users_count !== 2) {
            return null;
        }

        return $conversation;
    }

}
