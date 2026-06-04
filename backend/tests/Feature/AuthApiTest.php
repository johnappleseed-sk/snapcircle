<?php

namespace Tests\Feature;

use Tests\TestCase;

class AuthApiTest extends TestCase
{
    public function test_guest_cannot_access_authenticated_user_endpoint(): void
    {
        $this->getJson('/api/user')
            ->assertUnauthorized();
    }

    public function test_guest_cannot_logout(): void
    {
        $this->postJson('/api/logout')
            ->assertUnauthorized();
    }
}
