<?php

class Validation {
    public static function required(array $data, array $fields): array {
        $errors = [];
        foreach ($fields as $field) {
            if (!isset($data[$field]) || (is_string($data[$field]) && trim($data[$field]) === '')) {
                $errors[$field] = "{$field} is required";
            }
        }
        return $errors;
    }

    public static function email(string $email): bool {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }

    public static function minLength(string $value, int $min): bool {
        return strlen($value) >= $min;
    }

    public static function maxLength(string $value, int $max): bool {
        return strlen($value) <= $max;
    }

    public static function numeric($value): bool {
        return is_numeric($value);
    }

    public static function positiveNumber($value): bool {
        return is_numeric($value) && $value > 0;
    }

    public static function nonNegative($value): bool {
        return is_numeric($value) && $value >= 0;
    }

    public static function inArray($value, array $allowed): bool {
        return in_array($value, $allowed, true);
    }

    public static function dateFormat(string $value, string $format = 'Y-m-d'): bool {
        $d = DateTime::createFromFormat($format, $value);
        return $d && $d->format($format) === $value;
    }

    public static function phone(string $phone): bool {
        return preg_match('/^\+?[0-9\s\-\(\)]{7,20}$/', $phone) === 1;
    }

    public static function url(string $url): bool {
        return filter_var($url, FILTER_VALIDATE_URL) !== false;
    }

    public static function sanitize(string $value): string {
        return htmlspecialchars(trim($value), ENT_QUOTES, 'UTF-8');
    }

    public static function sanitizeArray(array $data): array {
        $clean = [];
        foreach ($data as $key => $value) {
            if (is_string($value)) {
                $clean[$key] = self::sanitize($value);
            } elseif (is_array($value)) {
                $clean[$key] = self::sanitizeArray($value);
            } else {
                $clean[$key] = $value;
            }
        }
        return $clean;
    }

    public static function getInput(): array {
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';

        if (strpos($contentType, 'application/json') !== false) {
            $raw = file_get_contents('php://input');
            $data = json_decode($raw, true);
            return is_array($data) ? $data : [];
        }

        if (strpos($contentType, 'multipart/form-data') !== false || strpos($contentType, 'application/x-www-form-urlencoded') !== false) {
            return $_POST;
        }

        $raw = file_get_contents('php://input');
        $data = json_decode($raw, true);
        if (is_array($data)) {
            return $data;
        }

        return array_merge($_GET, $_POST);
    }

    public static function getQueryParams(): array {
        $params = $_GET;
        unset($params['route']);
        return $params;
    }

    public static function validate(array $data, array $rules): array {
        $errors = [];

        foreach ($rules as $field => $fieldRules) {
            $value = $data[$field] ?? null;

            foreach ($fieldRules as $rule) {
                if (is_string($rule)) {
                    $ruleName = $rule;
                    $ruleParams = [];
                } elseif (is_array($rule)) {
                    $ruleName = $rule[0];
                    $ruleParams = array_slice($rule, 1);
                } else {
                    continue;
                }

                switch ($ruleName) {
                    case 'required':
                        if ($value === null || $value === '') {
                            $errors[$field][] = "{$field} is required";
                        }
                        break;
                    case 'email':
                        if ($value !== null && $value !== '' && !self::email((string)$value)) {
                            $errors[$field][] = "{$field} must be a valid email";
                        }
                        break;
                    case 'min':
                        if ($value !== null && is_string($value) && !self::minLength($value, (int)$ruleParams[0])) {
                            $errors[$field][] = "{$field} must be at least {$ruleParams[0]} characters";
                        }
                        break;
                    case 'max':
                        if ($value !== null && is_string($value) && !self::maxLength($value, (int)$ruleParams[0])) {
                            $errors[$field][] = "{$field} must not exceed {$ruleParams[0]} characters";
                        }
                        break;
                    case 'numeric':
                        if ($value !== null && $value !== '' && !self::numeric($value)) {
                            $errors[$field][] = "{$field} must be a number";
                        }
                        break;
                    case 'positive':
                        if ($value !== null && $value !== '' && !self::positiveNumber($value)) {
                            $errors[$field][] = "{$field} must be a positive number";
                        }
                        break;
                    case 'in':
                        if ($value !== null && $value !== '' && !self::inArray($value, $ruleParams[0])) {
                            $errors[$field][] = "{$field} must be one of: " . implode(', ', $ruleParams[0]);
                        }
                        break;
                    case 'date':
                        if ($value !== null && $value !== '' && !self::dateFormat((string)$value)) {
                            $errors[$field][] = "{$field} must be a valid date (Y-m-d)";
                        }
                        break;
                    case 'phone':
                        if ($value !== null && $value !== '' && !self::phone((string)$value)) {
                            $errors[$field][] = "{$field} must be a valid phone number";
                        }
                        break;
                    case 'url':
                        if ($value !== null && $value !== '' && !self::url((string)$value)) {
                            $errors[$field][] = "{$field} must be a valid URL";
                        }
                        break;
                }

                if (isset($errors[$field])) {
                    break;
                }
            }
        }

        return $errors;
    }
}
