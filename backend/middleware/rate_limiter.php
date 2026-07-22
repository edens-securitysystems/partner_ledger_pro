<?php

class RateLimiter {
    private static string $storagePath = '';

    public static function init(): void {
        self::$storagePath = __DIR__ . '/../logs/rate_limits/';
        if (!is_dir(self::$storagePath)) {
            mkdir(self::$storagePath, 0755, true);
        }
    }

    public static function check(string $key, int $maxRequests = null, int $windowSeconds = null): bool {
        $maxRequests = $maxRequests ?? AppConfig::RATE_LIMIT_MAX_REQUESTS;
        $windowSeconds = $windowSeconds ?? AppConfig::RATE_LIMIT_WINDOW;

        $identifier = self::getIdentifier($key);
        $filePath = self::$storagePath . md5($identifier) . '.json';

        $now = time();
        $data = self::readData($filePath);

        $data['requests'] = array_filter($data['requests'] ?? [], fn($ts) => $ts > ($now - $windowSeconds));
        $data['requests'] = array_values($data['requests'] ?? []);

        if (count($data['requests']) >= $maxRequests) {
            $retryAfter = $data['requests'][0] + $windowSeconds - $now;
            header("X-RateLimit-Limit: {$maxRequests}");
            header("X-RateLimit-Remaining: 0");
            header("X-RateLimit-Reset: " . ($now + $retryAfter));
            header("Retry-After: {$retryAfter}");
            return false;
        }

        $data['requests'][] = $now;
        self::writeData($filePath, $data);

        $remaining = $maxRequests - count($data['requests']);
        header("X-RateLimit-Limit: {$maxRequests}");
        header("X-RateLimit-Remaining: {$remaining}");
        header("X-RateLimit-Reset: " . ($now + $windowSeconds));

        return true;
    }

    public static function handle(): void {
        $userId = AuthMiddleware::getUserId();
        $ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';

        $key = $userId ? "user:{$userId}" : "ip:{$ip}";

        $route = $_SERVER['REQUEST_URI'] ?? '';
        $isAuthRoute = strpos($route, '/auth/') !== false;

        $maxRequests = $isAuthRoute ? AppConfig::RATE_LIMIT_AUTH_MAX : AppConfig::RATE_LIMIT_MAX_REQUESTS;

        if (!self::check($key, $maxRequests)) {
            Response::tooManyRequests('Rate limit exceeded. Please try again later.');
            exit;
        }
    }

    private static function getIdentifier(string $key): string {
        return $key;
    }

    private static function readData(string $filePath): array {
        if (!file_exists($filePath)) {
            return ['requests' => []];
        }

        $content = file_get_contents($filePath);
        if ($content === false) {
            return ['requests' => []];
        }

        $data = json_decode($content, true);
        return is_array($data) ? $data : ['requests' => []];
    }

    private static function writeData(string $filePath, array $data): void {
        file_put_contents($filePath, json_encode($data), LOCK_EX);
    }

    public static function cleanup(int $maxAge = 3600): void {
        $files = glob(self::$storagePath . '*.json');
        $now = time();

        foreach ($files as $file) {
            if (filemtime($file) < ($now - $maxAge)) {
                unlink($file);
            }
        }
    }
}

RateLimiter::init();
