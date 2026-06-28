<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SavedCollectionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $latestPost = $this->relationLoaded('posts') ? $this->posts->first() : null;

        return [
            'id' => $this->id,
            'name' => $this->name,
            'posts_count' => (int) ($this->posts_count ?? $this->posts()->count()),
            'latest_post' => $latestPost ? PostResource::make($latestPost) : null,
            'created_at' => optional($this->created_at)->toISOString(),
            'updated_at' => optional($this->updated_at)->toISOString(),
        ];
    }
}
