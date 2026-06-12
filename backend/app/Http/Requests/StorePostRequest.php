<?php

namespace App\Http\Requests;

use Illuminate\Validation\Validator;

class StorePostRequest extends ApiFormRequest
{
    public const MAX_IMAGES = 10;

    /**
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'content' => ['nullable', 'string', 'max:5000'],
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
            'images' => ['nullable', 'array', 'max:'.self::MAX_IMAGES],
            'images.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            if ($this->filled('content') || $this->hasFile('image') || $this->hasFile('images')) {
                return;
            }

            $validator->errors()->add('content', 'A post must include content or at least one image.');
        });
    }
}
