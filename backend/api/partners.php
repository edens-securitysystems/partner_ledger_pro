<?php

class PartnersController {

    public function list(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $page = max(1, (int)($params['page'] ?? 1));
        $perPage = min(AppConfig::MAX_PAGE_SIZE, max(1, (int)($params['per_page'] ?? AppConfig::DEFAULT_PAGE_SIZE)));
        $offset = ($page - 1) * $perPage;

        $conditions = ["p.is_active = 1"];
        $queryParams = [];

        $businessId = $params['business_id'] ?? null;
        if ($businessId) {
            $conditions[] = "p.business_id = ?";
            $queryParams[] = (int)$businessId;
        }

        $partnerType = $params['partner_type'] ?? null;
        if ($partnerType) {
            $conditions[] = "p.partner_type = ?";
            $queryParams[] = $partnerType;
        }

        $search = $params['search'] ?? null;
        if ($search) {
            $conditions[] = "(p.name LIKE ? OR p.email LIKE ? OR p.phone LIKE ?)";
            $searchTerm = "%{$search}%";
            $queryParams[] = $searchTerm;
            $queryParams[] = $searchTerm;
            $queryParams[] = $searchTerm;
        }

        $where = implode(' AND ', $conditions);

        $db = Database::getInstance();

        $total = $db->fetchOne(
            "SELECT COUNT(*) as cnt FROM partners p WHERE {$where}",
            $queryParams
        )['cnt'];

        $partners = $db->fetchAll(
            "SELECT p.*, b.name as business_name
             FROM partners p
             LEFT JOIN businesses b ON p.business_id = b.id
             WHERE {$where}
             ORDER BY p.created_at DESC
             LIMIT {$perPage} OFFSET {$offset}",
            $queryParams
        );

        Response::paginated($partners, (int)$total, $page, $perPage);
    }

    public function create(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $errors = Validation::validate($input, [
            'business_id' => ['required', 'positive'],
            'name' => ['required', 'min' => 2, 'max' => 255],
            'partner_type' => ['required', 'in' => [['equity', 'silent', 'operating', 'managing']]],
            'profit_share_percentage' => ['numeric'],
            'investment_amount' => ['numeric'],
        ]);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $db = Database::getInstance();

        $business = $db->fetchOne(
            "SELECT id, owner_id FROM businesses WHERE id = ? AND is_active = 1",
            [(int)$input['business_id']]
        );

        if (!$business) {
            Response::notFound('Business not found');
            exit;
        }

        if ($business['owner_id'] != $userId) {
            $hasAccess = $db->fetchOne(
                "SELECT id FROM partners WHERE business_id = ? AND user_id = ? AND is_active = 1",
                [(int)$input['business_id'], $userId]
            );
            if (!$hasAccess) {
                Response::forbidden('You do not have access to this business');
                exit;
            }
        }

        $partnerId = $db->insert('partners', [
            'business_id' => (int)$input['business_id'],
            'user_id' => isset($input['user_id']) ? (int)$input['user_id'] : null,
            'name' => Validation::sanitize($input['name']),
            'email' => isset($input['email']) ? Validation::sanitize($input['email']) : null,
            'phone' => isset($input['phone']) ? Validation::sanitize($input['phone']) : null,
            'address' => isset($input['address']) ? Validation::sanitize($input['address']) : null,
            'partner_type' => $input['partner_type'],
            'profit_share_percentage' => (float)($input['profit_share_percentage'] ?? 0),
            'investment_amount' => (float)($input['investment_amount'] ?? 0),
            'balance' => (float)($input['investment_amount'] ?? 0),
            'credit_limit' => (float)($input['credit_limit'] ?? 0),
            'notes' => isset($input['notes']) ? Validation::sanitize($input['notes']) : null,
            'joined_at' => $input['joined_at'] ?? date('Y-m-d'),
        ]);

        $partner = $db->fetchOne(
            "SELECT p.*, b.name as business_name FROM partners p LEFT JOIN businesses b ON p.business_id = b.id WHERE p.id = ?",
            [$partnerId]
        );

        $db->insert('audit_log', [
            'user_id' => $userId,
            'action' => 'create',
            'entity_type' => 'partner',
            'entity_id' => (int)$partnerId,
            'new_values' => json_encode($partner),
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? null,
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? null,
        ]);

        Logger::info("Partner created", ['partner_id' => $partnerId, 'business_id' => $input['business_id']]);

        Response::created($partner, 'Partner created successfully');
    }

    public function read(): void {
        $userId = AuthMiddleware::getUserId();
        $partnerId = (int)($_GET['id'] ?? 0);

        if (!$partnerId) {
            $uri = $_SERVER['REQUEST_URI'];
            if (preg_match('/\/(\d+)$/', $uri, $matches)) {
                $partnerId = (int)$matches[1];
            }
        }

        if (!$partnerId) {
            Response::error('Partner ID is required', 400);
            exit;
        }

        $db = Database::getInstance();
        $partner = $db->fetchOne(
            "SELECT p.*, b.name as business_name, b.owner_id
             FROM partners p
             LEFT JOIN businesses b ON p.business_id = b.id
             WHERE p.id = ? AND p.is_active = 1",
            [$partnerId]
        );

        if (!$partner) {
            Response::notFound('Partner not found');
            exit;
        }

        $transactions = $db->fetchAll(
            "SELECT * FROM transactions WHERE partner_id = ? AND is_active = 1 ORDER BY transaction_date DESC LIMIT 10",
            [$partnerId]
        );

        $partner['recent_transactions'] = $transactions;

        Response::success($partner);
    }

    public function update(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $partnerId = (int)($input['id'] ?? 0);
        unset($input['id']);

        if (!$partnerId) {
            Response::error('Partner ID is required', 400);
            exit;
        }

        $db = Database::getInstance();

        $existing = $db->fetchOne(
            "SELECT p.*, b.owner_id FROM partners p LEFT JOIN businesses b ON p.business_id = b.id WHERE p.id = ? AND p.is_active = 1",
            [$partnerId]
        );

        if (!$existing) {
            Response::notFound('Partner not found');
            exit;
        }

        if ($existing['owner_id'] != $userId) {
            $hasAccess = $db->fetchOne(
                "SELECT id FROM partners WHERE business_id = ? AND user_id = ? AND is_active = 1",
                [$existing['business_id'], $userId]
            );
            if (!$hasAccess) {
                Response::forbidden('You do not have access to update this partner');
                exit;
            }
        }

        $allowedFields = [
            'name', 'email', 'phone', 'address', 'partner_type',
            'profit_share_percentage', 'investment_amount', 'credit_limit',
            'notes', 'is_active', 'joined_at', 'user_id'
        ];

        $updateData = [];
        foreach ($allowedFields as $field) {
            if (isset($input[$field])) {
                $updateData[$field] = is_string($input[$field]) ? Validation::sanitize($input[$field]) : $input[$field];
            }
        }

        if (empty($updateData)) {
            Response::error('No data to update', 400);
            exit;
        }

        $oldValues = json_encode($existing);

        $db->update('partners', $updateData, 'id = ?', [$partnerId]);

        $partner = $db->fetchOne(
            "SELECT p.*, b.name as business_name FROM partners p LEFT JOIN businesses b ON p.business_id = b.id WHERE p.id = ?",
            [$partnerId]
        );

        $db->insert('audit_log', [
            'user_id' => $userId,
            'action' => 'update',
            'entity_type' => 'partner',
            'entity_id' => $partnerId,
            'old_values' => $oldValues,
            'new_values' => json_encode($partner),
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? null,
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? null,
        ]);

        Logger::info("Partner updated", ['partner_id' => $partnerId]);

        Response::success($partner, 'Partner updated successfully');
    }

    public function delete(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $partnerId = (int)($input['id'] ?? 0);
        if (!$partnerId) {
            $partnerId = (int)($_GET['id'] ?? 0);
        }

        if (!$partnerId) {
            Response::error('Partner ID is required', 400);
            exit;
        }

        $db = Database::getInstance();

        $existing = $db->fetchOne(
            "SELECT p.*, b.owner_id FROM partners p LEFT JOIN businesses b ON p.business_id = b.id WHERE p.id = ? AND p.is_active = 1",
            [$partnerId]
        );

        if (!$existing) {
            Response::notFound('Partner not found');
            exit;
        }

        if ($existing['owner_id'] != $userId) {
            Response::forbidden('Only the business owner can delete partners');
            exit;
        }

        $hasTransactions = $db->fetchOne(
            "SELECT COUNT(*) as cnt FROM transactions WHERE partner_id = ? AND status = 'completed'",
            [$partnerId]
        );

        if ($hasTransactions && $hasTransactions['cnt'] > 0) {
            $db->update('partners', ['is_active' => 0], 'id = ?', [$partnerId]);
        } else {
            $db->delete('ledger_entries', 'partner_id = ?', [$partnerId]);
            $db->delete('partners', 'id = ?', [$partnerId]);
        }

        $db->insert('audit_log', [
            'user_id' => $userId,
            'action' => 'delete',
            'entity_type' => 'partner',
            'entity_id' => $partnerId,
            'old_values' => json_encode($existing),
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? null,
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? null,
        ]);

        Logger::info("Partner deleted", ['partner_id' => $partnerId]);

        Response::success(null, 'Partner deleted successfully');
    }

    public function search(): void {
        $params = Validation::getQueryParams();
        $query = $params['q'] ?? $params['search'] ?? '';

        if (strlen($query) < 2) {
            Response::error('Search query must be at least 2 characters', 400);
            exit;
        }

        $db = Database::getInstance();
        $searchTerm = "%{$query}%";

        $businessId = $params['business_id'] ?? null;
        $conditions = "p.is_active = 1 AND (p.name LIKE ? OR p.email LIKE ? OR p.phone LIKE ?)";
        $queryParams = [$searchTerm, $searchTerm, $searchTerm];

        if ($businessId) {
            $conditions .= " AND p.business_id = ?";
            $queryParams[] = (int)$businessId;
        }

        $partners = $db->fetchAll(
            "SELECT p.*, b.name as business_name
             FROM partners p
             LEFT JOIN businesses b ON p.business_id = b.id
             WHERE {$conditions}
             ORDER BY p.name ASC
             LIMIT 50",
            $queryParams
        );

        Response::success($partners);
    }

    public function byBusiness(): void {
        $params = Validation::getQueryParams();
        $businessId = (int)($params['business_id'] ?? 0);

        if (!$businessId) {
            Response::error('business_id is required', 400);
            exit;
        }

        $db = Database::getInstance();
        $partners = $db->fetchAll(
            "SELECT p.*, b.name as business_name
             FROM partners p
             LEFT JOIN businesses b ON p.business_id = b.id
             WHERE p.business_id = ? AND p.is_active = 1
             ORDER BY p.name ASC",
            [$businessId]
        );

        Response::success($partners);
    }
}
