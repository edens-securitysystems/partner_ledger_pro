<?php

class Response {
    public static function success($data = null, string $message = 'Success', int $statusCode = 200): void {
        http_response_code($statusCode);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function error(string $message = 'Error', int $statusCode = 400, $errors = null): void {
        http_response_code($statusCode);
        header('Content-Type: application/json');
        $response = [
            'success' => false,
            'message' => $message,
        ];
        if ($errors !== null) {
            $response['errors'] = $errors;
        }
        echo json_encode($response, JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function paginated(array $data, int $total, int $page, int $perPage): void {
        $totalPages = (int)ceil($total / $perPage);

        header('X-Pagination-Total: ' . $total);
        header('X-Pagination-Page: ' . $page);
        header('X-Pagination-Per-Page: ' . $perPage);
        header('X-Pagination-Total-Pages: ' . $totalPages);

        http_response_code(200);
        header('Content-Type: application/json');
        echo json_encode([
            'success' => true,
            'message' => 'Success',
            'data' => $data,
            'pagination' => [
                'total' => $total,
                'page' => $page,
                'per_page' => $perPage,
                'total_pages' => $totalPages,
                'has_next' => $page < $totalPages,
                'has_prev' => $page > 1,
            ],
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function noContent(): void {
        http_response_code(204);
        exit;
    }

    public static function created($data = null, string $message = 'Created successfully'): void {
        self::success($data, $message, 201);
    }

    public static function unauthorized(string $message = 'Unauthorized'): void {
        self::error($message, 401);
    }

    public static function forbidden(string $message = 'Forbidden'): void {
        self::error($message, 403);
    }

    public static function notFound(string $message = 'Resource not found'): void {
        self::error($message, 404);
    }

    public static function validation(array $errors, string $message = 'Validation failed'): void {
        self::error($message, 422, $errors);
    }

    public static function tooManyRequests(string $message = 'Too many requests'): void {
        self::error($message, 429);
    }

    public static function json(array $data, int $statusCode = 200): void {
        http_response_code($statusCode);
        header('Content-Type: application/json');
        echo json_encode($data, JSON_UNESCAPED_UNICODE);
        exit;
    }
}
