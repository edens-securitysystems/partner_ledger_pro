<?php

class Logger {
    private static string $logDir = '';
    private static string $level = 'info';
    private static array $levels = [
        'debug' => 0,
        'info' => 1,
        'warning' => 2,
        'error' => 3,
        'critical' => 4,
    ];

    public static function init(): void {
        self::$logDir = AppConfig::LOG_DIR;
        self::$level = AppConfig::LOG_LEVEL;

        if (!is_dir(self::$logDir)) {
            mkdir(self::$logDir, 0755, true);
        }
    }

    public static function debug(string $message, array $context = []): void {
        self::log('debug', $message, $context);
    }

    public static function info(string $message, array $context = []): void {
        self::log('info', $message, $context);
    }

    public static function warning(string $message, array $context = []): void {
        self::log('warning', $message, $context);
    }

    public static function error(string $message, array $context = []): void {
        self::log('error', $message, $context);
    }

    public static function critical(string $message, array $context = []): void {
        self::log('critical', $message, $context);
    }

    private static function log(string $level, string $message, array $context = []): void {
        if ((self::$levels[$level] ?? 0) < (self::$levels[self::$level] ?? 0)) {
            return;
        }

        $timestamp = date('Y-m-d H:i:s');
        $userId = $_SESSION['user_id'] ?? 'system';
        $ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';

        $contextStr = '';
        if (!empty($context)) {
            $contextStr = ' ' . json_encode($context, JSON_UNESCAPED_UNICODE);
        }

        $logLine = "[{$timestamp}] [{$level}] [user:{$userId}] [ip:{$ip}] {$message}{$contextStr}" . PHP_EOL;

        $logFile = self::$logDir . date('Y-m-d') . '.log';
        file_put_contents($logFile, $logLine, FILE_APPEND | LOCK_EX);
    }

    public static function getLogFiles(): array {
        if (!is_dir(self::$logDir)) {
            return [];
        }

        $files = glob(self::$logDir . '*.log');
        return array_map('basename', $files);
    }

    public static function readLog(string $date, int $limit = 100, string $level = ''): array {
        $logFile = self::$logDir . $date . '.log';
        if (!file_exists($logFile)) {
            return [];
        }

        $lines = file($logFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        $lines = array_reverse($lines);

        if ($level) {
            $lines = array_filter($lines, fn($line) => stripos($line, "[{$level}]") !== false);
        }

        return array_slice($lines, 0, $limit);
    }
}

Logger::init();
