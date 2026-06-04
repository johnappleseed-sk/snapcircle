<?php

use App\Support\ApiResponse;
use Illuminate\Support\Facades\Route;

Route::get('/health', fn () => ApiResponse::success([
    'status' => 'ok',
    'app' => 'SnapCircle API',
]));
