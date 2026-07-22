<?php

class NotificationsController {

    public function list(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $page = max(1, (int)($params['page'] ?? 1));
        $perPage = min(AppConfig::MAX_PAGE_SIZE, max(1, (int)($params['per_page'] ?? AppConfig::DEFAULT_PAGE_SIZE)));
        $offset = ($page - 1) * $perPage;

        $conditions = ["n.user_id = ?"];
        $queryParams = [$userId];

        if (isset($params['type'])) {
            $conditions[] = "n.type = ?";
            $queryParams[] = $params['type'];
        }

        if (isset($params['is_read'])) {
            $conditions[] = "n.is_read = ?";
            $queryParams[] = (int)$params['is_read'];
        }

        $where = implode(' AND ', $conditions);
        $db = Database::getInstance();

        $total = $db->fetchOne(
            "SELECT COUNT(*) as cnt FROM notifications n WHERE {$where}",
            $queryParams
        )['cnt'];

        $notifications = $db->fetchAll(
            "SELECT n.* FROM notifications n
             WHERE {$where}
             ORDER BY n.created_at DESC
             LIMIT {$perPage} OFFSET {$offset}",
            $queryParams
        );

        $unreadCount = $db->fetchOne(
            "SELECT COUNT(*) as cnt FROM notifications WHERE user_id = ? AND is_read = 0",
            [$userId]
        )['cnt'];

        header('X-Notifications-Unread: ' . $unreadCount);

        Response::paginated($notifications, (int)$total, $page, $perPage);
    }

    public function markRead(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $notificationId = (int)($input['id'] ?? 0);
        if (!$notificationId) {
            $notificationId = (int)($_GET['id'] ?? 0);
        }

        if (!$notificationId) {
            Response::error('Notification ID is required', 400);
            exit;
        }

        $db = Database::getInstance();

        $notification = $db->fetchOne(
            "SELECT id FROM notifications WHERE id = ? AND user_id = ?",
            [$notificationId, $userId]
        );

        if (!$notification) {
            Response::notFound('Notification not found');
            exit;
        }

        $db->execute(
            "UPDATE notifications SET is_read = 1, read_at = NOW() WHERE id = ? AND user_id = ?",
            [$notificationId, $userId]
        );

        Response::success(null, 'Notification marked as read');
    }

    public function markAllRead(): void {
        $userId = AuthMiddleware::getUserId();

        $db = Database::getInstance();
        $db->execute(
            "UPDATE notifications SET is_read = 1, read_at = NOW() WHERE user_id = ? AND is_read = 0",
            [$userId]
        );

        Response::success(null, 'All notifications marked as read');
    }

    public function unreadCount(): void {
        $userId = AuthMiddleware::getUserId();

        $db = Database::getInstance();
        $count = $db->fetchOne(
            "SELECT COUNT(*) as cnt FROM notifications WHERE user_id = ? AND is_read = 0",
            [$userId]
        )['cnt'];

        Response::success(['unread_count' => (int)$count]);
    }
}
