<?php

class AppConfig {
    public const APP_NAME = 'Partner Ledger Pro';
    public const APP_VERSION = '1.0.0';
    public const APP_ENV = 'development';
    public const APP_DEBUG = true;

    public const API_PREFIX = '/api/v1';
    public const MAX_PAGE_SIZE = 100;
    public const DEFAULT_PAGE_SIZE = 20;

    public const UPLOAD_MAX_SIZE = 10 * 1024 * 1024;
    public const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    public const ALLOWED_ATTACHMENT_TYPES = [
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'text/csv',
    ];
    public const UPLOAD_DIR_IMAGES = __DIR__ . '/../uploads/images/';
    public const UPLOAD_DIR_ATTACHMENTS = __DIR__ . '/../uploads/attachments/';

    public const RATE_LIMIT_WINDOW = 900;
    public const RATE_LIMIT_MAX_REQUESTS = 100;
    public const RATE_LIMIT_AUTH_MAX = 10;

    public const LOG_DIR = __DIR__ . '/../logs/';
    public const LOG_LEVEL = 'info';

    public const CURRENCY_SYMBOL = '$';
    public const CURRENCY_CODE = 'USD';

    public const TRANSACTION_TYPES = [
        'income',
        'expense',
        'investment',
        'withdrawal',
        'transfer',
        'loan_given',
        'loan_received',
        'repayment',
    ];

    public const PROFIT_DISTRIBUTION_METHODS = [
        'percentage',
        'equal',
        'manual',
        'custom',
    ];

    public static function isDevelopment(): bool {
        return self::APP_ENV === 'development';
    }

    public static function isProduction(): bool {
        return self::APP_ENV === 'production';
    }

    public static function get(string $key, $default = null) {
        $constant = strtoupper($key);
        if (defined("self::{$constant}")) {
            return constant("self::{$constant}");
        }
        return getenv($key) ?: $default;
    }
}
