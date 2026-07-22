<?php

class CORSConfig {
    private static array $allowedOrigins = [
        'http://localhost:3000',
        'http://localhost:5173',
        'http://localhost:5174',
        'http://localhost:8080',
        'http://localhost:4200',
        'http://127.0.0.1:3000',
        'http://127.0.0.1:5173',
        'http://127.0.0.1:5174',
        'http://127.0.0.1:8080',
        'http://127.0.0.1:4200',
    ];

    private static array $allowedMethods = [
        'GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'
    ];

    private static array $allowedHeaders = [
        'Content-Type',
        'Authorization',
        'X-Requested-With',
        'Accept',
        'Origin',
        'X-CSRF-Token',
        'X-API-Key',
    ];

    private static int $maxAge = 86400;

    public static function setHeaders(): void {
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '';

        $allowedOrigin = null;
        if (in_array($origin, self::$allowedOrigins)) {
            $allowedOrigin = $origin;
        } elseif (getenv('APP_ENV') === 'development' && !empty($origin)) {
            $allowedOrigin = $origin;
        }

        if ($allowedOrigin) {
            header("Access-Control-Allow-Origin: {$allowedOrigin}");
            header('Access-Control-Allow-Credentials: true');
        }

        header('Access-Control-Allow-Methods: ' . implode(', ', self::$allowedMethods));
        header('Access-Control-Allow-Headers: ' . implode(', ', self::$allowedHeaders));
        header("Access-Control-Max-Age: " . self::$maxAge);
        header('Access-Control-Expose-Headers: X-Pagination-Total, X-Pagination-Page, X-Pagination-Per-Page');

        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            http_response_code(204);
            exit;
        }
    }
}
