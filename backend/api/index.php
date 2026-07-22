<?php

require_once __DIR__ . '/config/app.php';
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/config/jwt.php';
require_once __DIR__ . '/config/cors.php';

require_once __DIR__ . '/helpers/response.php';
require_once __DIR__ . '/helpers/logger.php';

require_once __DIR__ . '/middleware/auth.php';
require_once __DIR__ . '/middleware/rate_limiter.php';
require_once __DIR__ . '/middleware/validation.php';
require_once __DIR__ . '/middleware/cors.php';

CORSMiddleware::handle();

register_shutdown_function(function () {
    $error = error_get_last();
    if ($error && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR])) {
        Logger::error("Fatal error: {$error['message']} in {$error['file']}:{$error['line']}");
        Response::error('Internal server error', 500);
    }
});

set_error_handler(function ($errno, $errstr, $errfile, $errline) {
    Logger::warning("PHP error: {$errstr} in {$errfile}:{$errline}");
    return false;
});

set_exception_handler(function (Throwable $e) {
    Logger::error("Uncaught exception: {$e->getMessage()} in {$e->getFile()}:{$e->getLine()}");
    if (AppConfig::isDevelopment()) {
        Response::error($e->getMessage(), 500, [
            'file' => $e->getFile(),
            'line' => $e->getLine(),
            'trace' => $e->getTraceAsString(),
        ]);
    } else {
        Response::error('Internal server error', 500);
    }
});

$uri = $_SERVER['REQUEST_URI'];
$uri = parse_url($uri, PHP_URL_PATH);
$uri = rtrim($uri, '/');

$apiPrefix = '/api/v1';
if (strpos($uri, $apiPrefix) === 0) {
    $uri = substr($uri, strlen($apiPrefix));
}
$uri = '/' . ltrim($uri, '/');

$method = $_SERVER['REQUEST_METHOD'];

$routes = [
    'POST' => [
        '/auth/login' => ['file' => 'auth.php', 'action' => 'login'],
        '/auth/register' => ['file' => 'auth.php', 'action' => 'register'],
        '/auth/logout' => ['file' => 'auth.php', 'action' => 'logout'],
        '/auth/refresh-token' => ['file' => 'auth.php', 'action' => 'refreshToken'],
        '/auth/forgot-password' => ['file' => 'auth.php', 'action' => 'forgotPassword'],
        '/auth/reset-password' => ['file' => 'auth.php', 'action' => 'resetPassword'],
        '/auth/change-password' => ['file' => 'auth.php', 'action' => 'changePassword'],
        '/auth/update-profile' => ['file' => 'auth.php', 'action' => 'updateProfile'],
        '/partners' => ['file' => 'partners.php', 'action' => 'create'],
        '/transactions' => ['file' => 'transactions.php', 'action' => 'create'],
        '/ledger/entries' => ['file' => 'ledger.php', 'action' => 'addEntry'],
        '/notifications/mark-all-read' => ['file' => 'notifications.php', 'action' => 'markAllRead'],
        '/upload/image' => ['file' => 'upload.php', 'action' => 'uploadImage'],
        '/upload/attachment' => ['file' => 'upload.php', 'action' => 'uploadAttachment'],
        '/reports/export' => ['file' => 'reports.php', 'action' => 'export'],
    ],
    'GET' => [
        '/auth/profile' => ['file' => 'auth.php', 'action' => 'profile'],
        '/partners' => ['file' => 'partners.php', 'action' => 'list'],
        '/partners/search' => ['file' => 'partners.php', 'action' => 'search'],
        '/partners/by-business' => ['file' => 'partners.php', 'action' => 'byBusiness'],
        '/transactions' => ['file' => 'transactions.php', 'action' => 'list'],
        '/dashboard' => ['file' => 'dashboard.php', 'action' => 'summary'],
        '/reports/monthly' => ['file' => 'reports.php', 'action' => 'monthly'],
        '/reports/yearly' => ['file' => 'reports.php', 'action' => 'yearly'],
        '/reports/partner-wise' => ['file' => 'reports.php', 'action' => 'partnerWise'],
        '/reports/business-wise' => ['file' => 'reports.php', 'action' => 'businessWise'],
        '/reports/cash-flow' => ['file' => 'reports.php', 'action' => 'cashFlow'],
        '/reports/profit-loss' => ['file' => 'reports.php', 'action' => 'profitLoss'],
        '/reports/balance-sheet' => ['file' => 'reports.php', 'action' => 'balanceSheet'],
        '/profit/calculate' => ['file' => 'profit.php', 'action' => 'calculate'],
        '/profit/report' => ['file' => 'profit.php', 'action' => 'report'],
        '/notifications' => ['file' => 'notifications.php', 'action' => 'list'],
        '/notifications/unread-count' => ['file' => 'notifications.php', 'action' => 'unreadCount'],
        '/settings' => ['file' => 'settings.php', 'action' => 'get'],
        '/ledger' => ['file' => 'ledger.php', 'action' => 'getPartnerLedger'],
    ],
    'PUT' => [
        '/partners' => ['file' => 'partners.php', 'action' => 'update'],
        '/transactions' => ['file' => 'transactions.php', 'action' => 'update'],
        '/settings' => ['file' => 'settings.php', 'action' => 'update'],
        '/profit/distribute' => ['file' => 'profit.php', 'action' => 'distribute'],
    ],
    'DELETE' => [
        '/partners' => ['file' => 'partners.php', 'action' => 'delete'],
        '/transactions' => ['file' => 'transactions.php', 'action' => 'delete'],
    ],
];

$publicRoutes = [
    '/auth/login',
    '/auth/register',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/auth/refresh-token',
];

if ($uri === '/' || $uri === '') {
    Response::success([
        'app' => AppConfig::APP_NAME,
        'version' => AppConfig::APP_VERSION,
        'status' => 'running',
    ]);
    exit;
}

if ($uri === '/health') {
    Response::success(['status' => 'healthy', 'timestamp' => date('c')]);
    exit;
}

$matched = false;
foreach (($routes[$method] ?? []) as $route => $handler) {
    $pattern = preg_replace('/\{(\w+)\}/', '(?P<$1>[^/]+)', $route);
    $pattern = '#^' . $pattern . '$#';

    if (preg_match($pattern, $uri, $matches)) {
        $matched = true;

        $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);

        if (!in_array($route, $publicRoutes)) {
            AuthMiddleware::handle();
        }

        $handlerFile = __DIR__ . '/api/' . $handler['file'];
        if (!file_exists($handlerFile)) {
            Logger::error("Handler file not found: {$handlerFile}");
            Response::error('Endpoint not found', 404);
            exit;
        }

        require_once $handlerFile;

        $className = basename($handler['file'], '.php');
        $className = ucfirst($className) . 'Controller';

        if (class_exists($className)) {
            $controller = new $className();
            $action = $handler['action'];

            if (!method_exists($controller, $action)) {
                Logger::error("Method {$action} not found in {$className}");
                Response::error('Method not allowed', 405);
                exit;
            }

            call_user_func_array([$controller, $action], $params);
        } else {
            if (function_exists($handler['action'])) {
                call_user_func_array($handler['action'], $params);
            } else {
                Logger::error("Handler class/function not found: {$className} / {$handler['action']}");
                Response::error('Endpoint not found', 404);
            }
        }

        $matched = true;
        break;
    }
}

if (!$matched) {
    Response::error('Endpoint not found', 404);
}
