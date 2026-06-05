<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConversationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'participants' => UserResource::collection($this->whenLoaded('users')),
            'latest_message' => $this->whenLoaded(
                'latestMessage',
                fn () => $this->latestMessage
                    ? MessageResource::make($this->latestMessage)
                    : null
            ),
            'unread_count' => $this->unread_count ?? $this->messages()
                ->where('sender_id', '!=', $request->user()->id)
                ->whereNull('read_at')
                ->count(),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
