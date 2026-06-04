<?php

namespace App\Http\Requests;

use Illuminate\Validation\Validator;

class UpdatePostRequest extends ApiFormRequest
{
    /**
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'content' => ['nullable', 'string', 'max:5000'],
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $post = $this->route('post');
            $content = $this->exists('content') ? $this->input('content') : $post?->content;
            $hasImage = $this->hasFile('image') || (bool) $post?->image_path;

            if (! $content && ! $hasImage) {
                $validator->errors()->add('content', 'A post must include content or an image.');
            }
        });
    }
}
