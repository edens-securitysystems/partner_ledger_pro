<?php

class AuthMiddleware {
    public static function handle(): void {
        $token = JWT::getTokenFromHeader();

        if (!$token) {
            Response::unauthorized('Authentication required');
            exit;
        }

        $payload = JWT::validateToken($token);
        if (!$payload) {
            Response::unauthorized('Invalid or expired token');
            exit;
        }

        if (isset($payload['type']) && $payload['type'] === 'refresh') {
            Response::unauthorized('Access token required, not refresh token');
            exit;
        }

        $db = Database::getInstance();
        $user = $db->fetchOne(
            "SELECT id, email, name, phone, avatar, role, is_active FROM users WHERE id = ? AND is_active = 1",
            [(int)$payload['user_id']]
        );

        if (!$user) {
            Response::unauthorized('User not found or inactive');
            exit;
        }

        $_REQUEST['_user'] = $user;
        $_REQUEST['_user_id'] = $user['id'];
        $_SERVER['_user'] = $user;
        $_SERVER['_user_id'] = $user['id'];
    }

    public static function getUser(): ?array {
        return $_REQUEST['_user'] ?? null;
    }

    public static function getUserId(): ?int {
        return isset($_REQUEST['_user_id']) ? (int)$_REQUEST['_user_id'] : null;
    }

    public static function requireRole(string ...$roles): void {
        $user = self::getUser();
        if (!$user || !in_array($user['role'], $roles)) {
            Response::forbidden('Insufficient permissions');
            exit;
        }
    }
}
