<?php

namespace App\Support;

use Illuminate\Http\Request;

class Pagination
{
    public static function perPage(Request $request, ?string $defaultKey = null): int
    {
        $default = (int) config(
            $defaultKey ? "snapcircle.pagination.{$defaultKey}" : 'snapcircle.pagination.default_per_page',
            10
        );
        $max = (int) config('snapcircle.pagination.max_per_page', 50);

        return min(max((int) $request->integer('per_page', $default), 1), $max);
    }
}
