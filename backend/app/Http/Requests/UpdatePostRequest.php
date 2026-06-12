<?php

namespace App\Http\Requests;

use Illuminate\Validation\Validator;

class UpdatePostRequest extends ApiFormRequest
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
            $post = $this->route('post');
            $content = $this->exists('content') ? $this->input('content') : $post?->content;
            $hasImage = $this->hasFile('image') || $this->hasFile('images') || (bool) $post?->image_path || (bool) $post?->media()->exists();

            if (! $content && ! $hasImage) {
                $validator->errors()->add('content', 'A post must include content or an image.');
            }
        });
    }
}
