<?php

namespace App\Policies;

use App\Models\Conversation;
use App\Models\User;

class ConversationPolicy
{
    public function view(User $user, Conversation $conversation): bool
    {
        return $this->isParticipant($user, $conversation)
            && ! $this->hasBlockedRelationship($user, $conversation);
    }

    public function delete(User $user, Conversation $conversation): bool
    {
        return $this->isParticipant($user, $conversation);
    }

    public function sendMessage(User $user, Conversation $conversation): bool
    {
        return $this->isParticipant($user, $conversation)
            && ! $this->hasBlockedRelationship($user, $conversation);
    }

    private function isParticipant(User $user, Conversation $conversation): bool
    {
        return $conversation->users()
            ->where('users.id', $user->id)
            ->exists();
    }

    private function hasBlockedRelationship(User $user, Conversation $conversation): bool
    {
        $otherUsers = $conversation->users()
            ->where('users.id', '!=', $user->id)
            ->get();

        return $otherUsers->contains(
            fn (User $otherUser) => $user->isBlockingOrBlockedBy($otherUser)
        );
    }
}
