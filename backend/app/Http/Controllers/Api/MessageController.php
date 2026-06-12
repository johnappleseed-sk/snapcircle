<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMessageRequest;
use App\Http\Resources\MessageResource;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use App\Services\NotificationService;
use App\Support\Pagination;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function __construct(private readonly NotificationService $notifications)
    {
    }

    public function index(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $perPage = Pagination::perPage($request, 'messages_per_page');
        $messages = $conversation->messages()
            ->with('sender.setting')
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
        $this->authorize('sendMessage', $conversation);

        $message = $conversation->messages()->create([
            'sender_id' => $request->user()->id,
            'message' => trim((string) $request->input('message')),
        ]);
        $conversation->touch();
        $message->load('sender.setting');
        $conversation->loadMissing('users.setting');

        $conversation->users
            ->where('id', '!=', $request->user()->id)
            ->each(fn (User $recipient) => $this->notifications->createMessageSentNotification(
                $request->user(),
                $recipient,
                $message
            ));

        return ApiResponse::success('Message sent successfully', [
            'message' => MessageResource::make($message),
        ], 201);
    }

    public function markAsRead(Request $request, Message $message): JsonResponse
    {
        $message->load('conversation');

        $this->authorize('view', $message->conversation);

        if ($message->sender_id !== $request->user()->id && $message->read_at === null) {
            $message->forceFill(['read_at' => now()])->save();
        }

        $message->load('sender.setting');

        return ApiResponse::success('Message marked as read', [
            'message' => MessageResource::make($message),
        ]);
    }

}
