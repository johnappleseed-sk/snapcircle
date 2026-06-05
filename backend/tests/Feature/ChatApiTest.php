<?php

namespace Tests\Feature;

use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ChatApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_start_conversation_with_another_user(): void
    {
        [$user, $other] = [User::factory()->create(), User::factory()->create()];

        Sanctum::actingAs($user);

        $this->postJson('/api/conversations', ['user_id' => $other->id])
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.conversation.participants.0.id', $user->id)
            ->assertJsonPath('data.conversation.participants.1.id', $other->id);

        $this->assertDatabaseCount('conversations', 1);
        $this->assertDatabaseCount('conversation_user', 2);
    }

    public function test_user_cannot_start_conversation_with_themselves(): void
    {
        $user = User::factory()->create();

        Sanctum::actingAs($user);

        $this->postJson('/api/conversations', ['user_id' => $user->id])
            ->assertUnprocessable();
    }

    public function test_starting_same_conversation_twice_returns_existing_conversation(): void
    {
        [$user, $other] = [User::factory()->create(), User::factory()->create()];

        Sanctum::actingAs($user);

        $firstId = $this->postJson('/api/conversations', ['user_id' => $other->id])
            ->assertCreated()
            ->json('data.conversation.id');

        $secondId = $this->postJson('/api/conversations', ['user_id' => $other->id])
            ->assertCreated()
            ->json('data.conversation.id');

        $this->assertSame($firstId, $secondId);
        $this->assertDatabaseCount('conversations', 1);
    }

    public function test_authenticated_user_can_list_own_conversations(): void
    {
        [$user, $other] = [User::factory()->create(), User::factory()->create()];
        $conversation = $this->conversationFor($user, $other);

        Sanctum::actingAs($user);

        $this->getJson('/api/conversations')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.conversations.0.id', $conversation->id);
    }

    public function test_user_cannot_view_conversation_they_are_not_part_of(): void
    {
        [$user, $other, $outsider] = [
            User::factory()->create(),
            User::factory()->create(),
            User::factory()->create(),
        ];
        $conversation = $this->conversationFor($user, $other);

        Sanctum::actingAs($outsider);

        $this->getJson("/api/conversations/{$conversation->id}")
            ->assertForbidden();
    }

    public function test_participant_can_send_message(): void
    {
        [$user, $other] = [User::factory()->create(), User::factory()->create()];
        $conversation = $this->conversationFor($user, $other);

        Sanctum::actingAs($user);

        $this->postJson("/api/conversations/{$conversation->id}/messages", [
            'message' => 'Hello!',
        ])
            ->assertCreated()
            ->assertJsonPath('data.message.message', 'Hello!')
            ->assertJsonPath('data.message.sender.id', $user->id);

        $this->assertDatabaseHas('messages', [
            'conversation_id' => $conversation->id,
            'sender_id' => $user->id,
            'message' => 'Hello!',
        ]);
    }

    public function test_non_participant_cannot_send_message(): void
    {
        [$user, $other, $outsider] = [
            User::factory()->create(),
            User::factory()->create(),
            User::factory()->create(),
        ];
        $conversation = $this->conversationFor($user, $other);

        Sanctum::actingAs($outsider);

        $this->postJson("/api/conversations/{$conversation->id}/messages", [
            'message' => 'Nope',
        ])->assertForbidden();
    }

    public function test_participant_can_list_messages(): void
    {
        [$user, $other] = [User::factory()->create(), User::factory()->create()];
        $conversation = $this->conversationFor($user, $other);
        $message = Message::query()->create([
            'conversation_id' => $conversation->id,
            'sender_id' => $other->id,
            'message' => 'Listed message',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/conversations/{$conversation->id}/messages")
            ->assertOk()
            ->assertJsonPath('data.messages.0.id', $message->id)
            ->assertJsonPath('data.messages.0.message', 'Listed message');
    }

    public function test_user_can_mark_message_as_read(): void
    {
        [$user, $other] = [User::factory()->create(), User::factory()->create()];
        $conversation = $this->conversationFor($user, $other);
        $message = Message::query()->create([
            'conversation_id' => $conversation->id,
            'sender_id' => $other->id,
            'message' => 'Please read',
        ]);

        Sanctum::actingAs($user);

        $this->putJson("/api/messages/{$message->id}/read")
            ->assertOk()
            ->assertJsonPath('data.message.is_read', true);

        $this->assertNotNull($message->fresh()->read_at);
    }

    public function test_guests_cannot_access_chat_endpoints(): void
    {
        [$user, $other] = [User::factory()->create(), User::factory()->create()];
        $conversation = $this->conversationFor($user, $other);
        $message = Message::query()->create([
            'conversation_id' => $conversation->id,
            'sender_id' => $user->id,
            'message' => 'Guest check',
        ]);

        $this->getJson('/api/conversations')->assertUnauthorized();
        $this->postJson('/api/conversations', ['user_id' => $other->id])->assertUnauthorized();
        $this->getJson("/api/conversations/{$conversation->id}")->assertUnauthorized();
        $this->getJson("/api/conversations/{$conversation->id}/messages")->assertUnauthorized();
        $this->postJson("/api/conversations/{$conversation->id}/messages", [
            'message' => 'Hello',
        ])->assertUnauthorized();
        $this->putJson("/api/messages/{$message->id}/read")->assertUnauthorized();
    }

    private function conversationFor(User $user, User $other): Conversation
    {
        $conversation = Conversation::query()->create();
        $conversation->users()->attach([$user->id, $other->id]);

        return $conversation;
    }
}
