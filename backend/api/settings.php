<?php

class SettingsController {

    private static array $defaults = [
        'theme' => ['value' => 'light', 'type' => 'string'],
        'currency' => ['value' => AppConfig::CURRENCY_CODE, 'type' => 'string'],
        'currency_symbol' => ['value' => AppConfig::CURRENCY_SYMBOL, 'type' => 'string'],
        'language' => ['value' => 'en', 'type' => 'string'],
        'date_format' => ['value' => 'Y-m-d', 'type' => 'string'],
        'time_format' => ['value' => '24h', 'type' => 'string'],
        'notifications_enabled' => ['value' => '1', 'type' => 'boolean'],
        'email_notifications' => ['value' => '1', 'type' => 'boolean'],
        'push_notifications' => ['value' => '1', 'type' => 'boolean'],
        'transaction_notifications' => ['value' => '1', 'type' => 'boolean'],
        'profit_alert_threshold' => ['value' => '0', 'type' => 'float'],
        'default_business_id' => ['value' => '', 'type' => 'integer'],
        'items_per_page' => ['value' => '20', 'type' => 'integer'],
        'default_partner_view' => ['value' => 'list', 'type' => 'string'],
        'dashboard_layout' => ['value' => 'default', 'type' => 'string'],
    ];

    public function get(): void {
        $userId = AuthMiddleware::getUserId();
        $db = Database::getInstance();

        $settings = $db->fetchAll(
            "SELECT setting_key, setting_value, setting_type FROM settings WHERE user_id = ?",
            [$userId]
        );

        $settingsMap = [];
        foreach ($settings as $setting) {
            $settingsMap[$setting['setting_key']] = self::castValue($setting['setting_value'], $setting['setting_type']);
        }

        $result = [];
        foreach (self::$defaults as $key => $default) {
            $result[$key] = $settingsMap[$key] ?? $default['value'];
        }

        Response::success($result);
    }

    public function update(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        if (empty($input)) {
            Response::error('No settings to update', 400);
            exit;
        }

        $db = Database::getInstance();
        $updated = [];

        foreach ($input as $key => $value) {
            if (!isset(self::$defaults[$key])) {
                continue;
            }

            $default = self::$defaults[$key];
            $type = $default['type'];

            $validatedValue = self::validateSetting($key, $value, $type);
            if ($validatedValue === null) {
                continue;
            }

            $existing = $db->fetchOne(
                "SELECT id FROM settings WHERE user_id = ? AND setting_key = ?",
                [$userId, $key]
            );

            $stringValue = self::toStringValue($validatedValue, $type);

            if ($existing) {
                $db->update('settings', [
                    'setting_value' => $stringValue,
                    'setting_type' => $type,
                ], 'id = ?', [$existing['id']]);
            } else {
                $db->insert('settings', [
                    'user_id' => $userId,
                    'setting_key' => $key,
                    'setting_value' => $stringValue,
                    'setting_type' => $type,
                ]);
            }

            $updated[$key] = $validatedValue;
        }

        Logger::info("Settings updated", ['user_id' => $userId, 'keys' => array_keys($updated)]);

        Response::success($updated, 'Settings updated successfully');
    }

    private static function validateSetting(string $key, $value, string $type) {
        switch ($key) {
            case 'theme':
                if (!in_array($value, ['light', 'dark', 'auto'])) {
                    return null;
                }
                return $value;

            case 'currency':
                if (!preg_match('/^[A-Z]{3}$/', $value)) {
                    return null;
                }
                return $value;

            case 'language':
                if (!preg_match('/^[a-z]{2}(-[a-z]{2})?$/i', $value)) {
                    return null;
                }
                return $value;

            case 'date_format':
                $validFormats = ['Y-m-d', 'd/m/Y', 'm/d/Y', 'd-m-Y', 'd.m.Y'];
                if (!in_array($value, $validFormats)) {
                    return null;
                }
                return $value;

            case 'time_format':
                if (!in_array($value, ['12h', '24h'])) {
                    return null;
                }
                return $value;

            case 'notifications_enabled':
            case 'email_notifications':
            case 'push_notifications':
            case 'transaction_notifications':
                return $value ? '1' : '0';

            case 'profit_alert_threshold':
                $num = (float)$value;
                return $num >= 0 ? $num : null;

            case 'default_business_id':
                return (int)$value;

            case 'items_per_page':
                $num = (int)$value;
                return ($num >= 5 && $num <= 100) ? $num : null;

            case 'default_partner_view':
                if (!in_array($value, ['list', 'grid', 'table'])) {
                    return null;
                }
                return $value;

            case 'dashboard_layout':
                if (!in_array($value, ['default', 'compact', 'detailed'])) {
                    return null;
                }
                return $value;

            default:
                return $value;
        }
    }

    private static function castValue($value, string $type) {
        switch ($type) {
            case 'integer':
                return (int)$value;
            case 'float':
                return (float)$value;
            case 'boolean':
                return (bool)$value;
            case 'json':
                return json_decode($value, true);
            default:
                return (string)$value;
        }
    }

    private static function toStringValue($value, string $type): string {
        if ($type === 'json') {
            return is_array($value) ? json_encode($value) : (string)$value;
        }
        if ($type === 'boolean') {
            return $value ? '1' : '0';
        }
        return (string)$value;
    }
}
