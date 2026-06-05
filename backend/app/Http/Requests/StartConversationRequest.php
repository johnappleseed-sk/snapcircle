<?php

namespace App\Http\Requests;

use Illuminate\Validation\Rule;

class StartConversationRequest extends ApiFormRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'user_id' => [
                'required',
                'integer',
                'exists:users,id',
                Rule::notIn([$this->user()?->id]),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'user_id.not_in' => 'You cannot start a conversation with yourself.',
        ];
    }
}
