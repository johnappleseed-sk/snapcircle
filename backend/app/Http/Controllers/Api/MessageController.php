<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMessageRequest;
use App\Http\Resources\MessageResource;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function index(Request $request, Conversation $conversation): JsonResponse
    {
        if (! $this->isParticipant($conversation, $request->user()->id)) {
            return ApiResponse::error('Unauthorized action', [], 403);
        }

        $perPage = min((int) $request->integer('per_page', 30), 50);
        $messages = $conversation->messages()
            ->with('sender')
            ->latest()
            ->paginate($perPage);

        return ApiResponse::paginated(
            'Messages fetched successfully',
            'messages',
            $messages,
            MessageResource::collection($messages->items())
        );
    }

    public function store(StoreMessageRequest $request, Conversation $conversation): JsonResponse
    {
        if (! $this->isParticipant($conversation, $request->user()->id)) {
            return ApiResponse::error('Unauthorized action', [], 403);
        }

        $message = $conversation->messages()->create([
            'sender_id' => $request->user()->id,
            'message' => trim((string) $request->input('message')),
        ]);
        $conversation->touch();
        $message->load('sender');

        return ApiResponse::success('Message sent successfully', [
            'message' => MessageResource::make($message),
        ], 201);
    }

    public function markAsRead(Request $request, Message $message): JsonResponse
    {
        $message->load('conversation');

        if (! $this->isParticipant($message->conversation, $request->user()->id)) {
            return ApiResponse::error('Unauthorized action', [], 403);
        }

        if ($message->sender_id !== $request->user()->id && $message->read_at === null) {
            $message->forceFill(['read_at' => now()])->save();
        }

        $message->load('sender');

        return ApiResponse::success('Message marked as read', [
            'message' => MessageResource::make($message),
        ]);
    }

    private function isParticipant(Conversation $conversation, int $userId): bool
    {
        return $conversation->users()
            ->where('users.id', $userId)
            ->exists();
    }
}
