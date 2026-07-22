<?php

class AuthController {

    public function login(): void {
        $input = Validation::getInput();

        $errors = Validation::validate($input, [
            'email' => ['required', 'email'],
            'password' => ['required', 'min' => 6],
        ]);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $db = Database::getInstance();
        $user = $db->fetchOne(
            "SELECT id, email, password, name, phone, avatar, role, is_active FROM users WHERE email = ?",
            [$input['email']]
        );

        if (!$user || !password_verify($input['password'], $user['password'])) {
            Logger::info("Failed login attempt for email: {$input['email']}");
            Response::unauthorized('Invalid email or password');
            exit;
        }

        if (!$user['is_active']) {
            Response::unauthorized('Account is deactivated');
            exit;
        }

        $db->execute("UPDATE users SET last_login_at = NOW() WHERE id = ?", [$user['id']]);

        unset($user['password'], $user['is_active']);

        $token = JWT::generateToken([
            'user_id' => $user['id'],
            'email' => $user['email'],
            'role' => $user['role'],
        ]);

        $refreshToken = JWT::generateRefreshToken([
            'user_id' => $user['id'],
            'email' => $user['email'],
            'role' => $user['role'],
        ]);

        Logger::info("User logged in successfully", ['user_id' => $user['id']]);

        $expiresAt = date('c', strtotime('+1 hour'));

        Response::success([
            'user' => $user,
            'token' => $token,
            'refreshToken' => $refreshToken,
            'expiresAt' => $expiresAt,
        ], 'Login successful');
    }

    public function register(): void {
        $input = Validation::getInput();

        $errors = Validation::validate($input, [
            'name' => ['required', 'min' => 2, 'max' => 255],
            'email' => ['required', 'email'],
            'password' => ['required', 'min' => 8, 'max' => 255],
        ]);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $db = Database::getInstance();
        $existing = $db->fetchOne("SELECT id FROM users WHERE email = ?", [$input['email']]);
        if ($existing) {
            Response::error('Email already registered', 409);
            exit;
        }

        $hashedPassword = password_hash($input['password'], PASSWORD_BCRYPT, ['cost' => 12]);

        $userId = $db->insert('users', [
            'email' => $input['email'],
            'password' => $hashedPassword,
            'name' => Validation::sanitize($input['name']),
            'phone' => !empty($input['phone']) ? Validation::sanitize($input['phone']) : null,
            'role' => 'viewer',
            'is_active' => 1,
        ]);

        if (!$userId) {
            Response::error('Registration failed', 500);
            exit;
        }

        $defaultSettings = [
            ['theme', 'light', 'string'],
            ['currency', AppConfig::CURRENCY_CODE, 'string'],
            ['language', 'en', 'string'],
            ['notifications_enabled', '1', 'boolean'],
            ['email_notifications', '1', 'boolean'],
        ];

        foreach ($defaultSettings as [$key, $value, $type]) {
            $db->insert('settings', [
                'user_id' => $userId,
                'setting_key' => $key,
                'setting_value' => $value,
                'setting_type' => $type,
            ]);
        }

        $user = $db->fetchOne(
            "SELECT id, email, name, phone, avatar, role, created_at FROM users WHERE id = ?",
            [$userId]
        );

        $token = JWT::generateToken([
            'user_id' => (int)$userId,
            'email' => $user['email'],
            'role' => $user['role'],
        ]);

        $refreshToken = JWT::generateRefreshToken([
            'user_id' => (int)$userId,
            'email' => $user['email'],
            'role' => $user['role'],
        ]);

        Logger::info("New user registered", ['user_id' => $userId, 'email' => $input['email']]);

        $expiresAt = date('c', strtotime('+1 hour'));

        Response::created([
            'user' => $user,
            'token' => $token,
            'refreshToken' => $refreshToken,
            'expiresAt' => $expiresAt,
        ], 'Registration successful');
    }

    public function logout(): void {
        $userId = AuthMiddleware::getUserId();
        if ($userId) {
            Logger::info("User logged out", ['user_id' => $userId]);
        }
        Response::success(null, 'Logged out successfully');
    }

    public function refreshToken(): void {
        $input = Validation::getInput();

        $errors = Validation::validate($input, [
            'refresh_token' => ['required'],
        ]);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $tokens = JWT::refreshToken($input['refresh_token']);
        if (!$tokens) {
            Response::unauthorized('Invalid or expired refresh token');
            exit;
        }

        Response::success($tokens, 'Token refreshed successfully');
    }

    public function forgotPassword(): void {
        $input = Validation::getInput();

        $errors = Validation::validate($input, [
            'email' => ['required', 'email'],
        ]);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $db = Database::getInstance();
        $user = $db->fetchOne("SELECT id, email FROM users WHERE email = ?", [$input['email']]);

        if ($user) {
            $resetToken = bin2hex(random_bytes(32));
            $expires = date('Y-m-d H:i:s', time() + 3600);

            $db->execute(
                "UPDATE users SET password_reset_token = ?, password_reset_expires_at = ? WHERE id = ?",
                [$resetToken, $expires, $user['id']]
            );

            Logger::info("Password reset requested", ['user_id' => $user['id']]);
        }

        Response::success(null, 'If the email exists, a password reset link has been sent');
    }

    public function resetPassword(): void {
        $input = Validation::getInput();

        $errors = Validation::validate($input, [
            'token' => ['required'],
            'password' => ['required', 'min' => 8, 'max' => 255],
        ]);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $db = Database::getInstance();
        $user = $db->fetchOne(
            "SELECT id FROM users WHERE password_reset_token = ? AND password_reset_expires_at > NOW()",
            [$input['token']]
        );

        if (!$user) {
            Response::error('Invalid or expired reset token', 400);
            exit;
        }

        $hashedPassword = password_hash($input['password'], PASSWORD_BCRYPT, ['cost' => 12]);

        $db->execute(
            "UPDATE users SET password = ?, password_reset_token = NULL, password_reset_expires_at = NULL WHERE id = ?",
            [$hashedPassword, $user['id']]
        );

        Logger::info("Password reset completed", ['user_id' => $user['id']]);

        Response::success(null, 'Password reset successful');
    }

    public function changePassword(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $errors = Validation::validate($input, [
            'current_password' => ['required'],
            'new_password' => ['required', 'min' => 8, 'max' => 255],
        ]);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $db = Database::getInstance();
        $user = $db->fetchOne("SELECT password FROM users WHERE id = ?", [$userId]);

        if (!$user || !password_verify($input['current_password'], $user['password'])) {
            Response::error('Current password is incorrect', 400);
            exit;
        }

        if ($input['current_password'] === $input['new_password']) {
            Response::error('New password must be different from current password', 400);
            exit;
        }

        $hashedPassword = password_hash($input['new_password'], PASSWORD_BCRYPT, ['cost' => 12]);
        $db->execute("UPDATE users SET password = ? WHERE id = ?", [$hashedPassword, $userId]);

        Logger::info("Password changed", ['user_id' => $userId]);

        Response::success(null, 'Password changed successfully');
    }

    public function updateProfile(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $errors = Validation::validate($input, [
            'name' => ['required', 'min' => 2, 'max' => 255],
            'email' => ['required', 'email'],
        ]);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $db = Database::getInstance();

        $existing = $db->fetchOne(
            "SELECT id FROM users WHERE email = ? AND id != ?",
            [$input['email'], $userId]
        );

        if ($existing) {
            Response::error('Email already in use', 409);
            exit;
        }

        $updateData = [
            'name' => Validation::sanitize($input['name']),
            'email' => $input['email'],
        ];

        if (isset($input['phone'])) {
            $updateData['phone'] = Validation::sanitize($input['phone']);
        }

        $db->update('users', $updateData, 'id = ?', [$userId]);

        $user = $db->fetchOne(
            "SELECT id, email, name, phone, avatar, role, created_at, updated_at FROM users WHERE id = ?",
            [$userId]
        );

        Logger::info("Profile updated", ['user_id' => $userId]);

        Response::success($user, 'Profile updated successfully');
    }

    public function profile(): void {
        $userId = AuthMiddleware::getUserId();

        $db = Database::getInstance();
        $user = $db->fetchOne(
            "SELECT id, email, name, phone, avatar, role, is_active, last_login_at, created_at, updated_at FROM users WHERE id = ?",
            [$userId]
        );

        if (!$user) {
            Response::notFound('User not found');
            exit;
        }

        Response::success($user);
    }
}
