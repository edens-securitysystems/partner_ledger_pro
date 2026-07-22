<?php

class JWT {
    private static string $secret = '';
    private static int $expiry = 3600;
    private static int $refreshExpiry = 604800;
    private static string $algo = 'sha256';

    public static function init(): void {
        self::$secret = getenv('JWT_SECRET') ?: 'partner-ledger-pro-secret-key-change-in-production';
        self::$expiry = (int)(getenv('JWT_EXPIRY') ?: 3600);
        self::$refreshExpiry = (int)(getenv('JWT_REFRESH_EXPIRY') ?: 604800);
    }

    public static function generateToken(array $payload): string {
        $header = self::base64UrlEncode(json_encode([
            'typ' => 'JWT',
            'alg' => 'HS256'
        ]));

        $payload['iat'] = time();
        $payload['exp'] = time() + self::$expiry;
        $payload['jti'] = bin2hex(random_bytes(16));

        $payloadEncoded = self::base64UrlEncode(json_encode($payload));
        $signature = self::sign("{$header}.{$payloadEncoded}");

        return "{$header}.{$payloadEncoded}.{$signature}";
    }

    public static function generateRefreshToken(array $payload): string {
        $header = self::base64UrlEncode(json_encode([
            'typ' => 'JWT',
            'alg' => 'HS256'
        ]));

        $payload['type'] = 'refresh';
        $payload['iat'] = time();
        $payload['exp'] = time() + self::$refreshExpiry;
        $payload['jti'] = bin2hex(random_bytes(16));

        $payloadEncoded = self::base64UrlEncode(json_encode($payload));
        $signature = self::sign("{$header}.{$payloadEncoded}");

        return "{$header}.{$payloadEncoded}.{$signature}";
    }

    public static function validateToken(string $token): ?array {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }

        [$header, $payload, $signature] = $parts;

        $expectedSignature = self::sign("{$header}.{$payload}");
        if (!hash_equals($expectedSignature, $signature)) {
            return null;
        }

        $data = json_decode(self::base64UrlDecode($payload), true);
        if (!$data || !isset($data['exp'])) {
            return null;
        }

        if ($data['exp'] < time()) {
            return null;
        }

        return $data;
    }

    public static function refreshToken(string $refreshToken): ?array {
        $data = self::validateToken($refreshToken);
        if (!$data || ($data['type'] ?? '') !== 'refresh') {
            return null;
        }

        unset($data['exp'], $data['iat'], $data['jti'], $data['type']);

        return [
            'token' => self::generateToken($data),
            'refresh_token' => self::generateRefreshToken($data),
        ];
    }

    public static function getUserIdFromToken(string $token): ?int {
        $data = self::validateToken($token);
        if (!$data || !isset($data['user_id'])) {
            return null;
        }
        return (int)$data['user_id'];
    }

    public static function getTokenFromHeader(): ?string {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

        if (preg_match('/Bearer\s+(.+)$/i', $authHeader, $matches)) {
            return $matches[1];
        }

        return null;
    }

    private static function sign(string $data): string {
        $hmac = hash_hmac(self::$algo, $data, self::$secret, true);
        return self::base64UrlEncode($hmac);
    }

    private static function base64UrlEncode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64UrlDecode(string $data): string {
        return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', (4 - strlen($data) % 4) % 4));
    }
}

JWT::init();
