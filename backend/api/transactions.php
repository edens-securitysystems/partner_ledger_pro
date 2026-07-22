<?php

class TransactionsController {

    public function list(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $page = max(1, (int)($params['page'] ?? 1));
        $perPage = min(AppConfig::MAX_PAGE_SIZE, max(1, (int)($params['per_page'] ?? AppConfig::DEFAULT_PAGE_SIZE)));
        $offset = ($page - 1) * $perPage;

        $conditions = ["t.status != 'cancelled'"];
        $queryParams = [];

        if (isset($params['business_id'])) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$params['business_id'];
        }

        if (isset($params['partner_id'])) {
            $conditions[] = "t.partner_id = ?";
            $queryParams[] = (int)$params['partner_id'];
        }

        if (isset($params['transaction_type'])) {
            $conditions[] = "t.transaction_type = ?";
            $queryParams[] = $params['transaction_type'];
        }

        if (isset($params['category'])) {
            $conditions[] = "t.category = ?";
            $queryParams[] = $params['category'];
        }

        if (isset($params['status'])) {
            $conditions[] = "t.status = ?";
            $queryParams[] = $params['status'];
        }

        if (isset($params['date_from'])) {
            $conditions[] = "t.transaction_date >= ?";
            $queryParams[] = $params['date_from'];
        }

        if (isset($params['date_to'])) {
            $conditions[] = "t.transaction_date <= ?";
            $queryParams[] = $params['date_to'];
        }

        if (isset($params['min_amount'])) {
            $conditions[] = "t.amount >= ?";
            $queryParams[] = (float)$params['min_amount'];
        }

        if (isset($params['max_amount'])) {
            $conditions[] = "t.amount <= ?";
            $queryParams[] = (float)$params['max_amount'];
        }

        if (isset($params['payment_method'])) {
            $conditions[] = "t.payment_method = ?";
            $queryParams[] = $params['payment_method'];
        }

        $search = $params['search'] ?? null;
        if ($search) {
            $conditions[] = "(t.description LIKE ? OR t.reference_number LIKE ? OR t.category LIKE ?)";
            $searchTerm = "%{$search}%";
            $queryParams[] = $searchTerm;
            $queryParams[] = $searchTerm;
            $queryParams[] = $searchTerm;
        }

        $where = implode(' AND ', $conditions);

        $orderBy = $params['sort'] ?? 'transaction_date';
        $orderDir = strtoupper($params['order'] ?? 'DESC') === 'ASC' ? 'ASC' : 'DESC';
        $allowedSorts = ['transaction_date', 'amount', 'created_at', 'transaction_type', 'category'];
        if (!in_array($orderBy, $allowedSorts)) {
            $orderBy = 'transaction_date';
        }

        $db = Database::getInstance();

        $total = $db->fetchOne(
            "SELECT COUNT(*) as cnt FROM transactions t WHERE {$where}",
            $queryParams
        )['cnt'];

        $transactions = $db->fetchAll(
            "SELECT t.*, p.name as partner_name, b.name as business_name,
                    u.name as created_by_name
             FROM transactions t
             LEFT JOIN partners p ON t.partner_id = p.id
             LEFT JOIN businesses b ON t.business_id = b.id
             LEFT JOIN users u ON t.created_by = u.id
             WHERE {$where}
             ORDER BY t.{$orderBy} {$orderDir}
             LIMIT {$perPage} OFFSET {$offset}",
            $queryParams
        );

        Response::paginated($transactions, (int)$total, $page, $perPage);
    }

    public function create(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $errors = Validation::validate($input, [
            'business_id' => ['required', 'positive'],
            'transaction_type' => ['required', 'in' => [AppConfig::TRANSACTION_TYPES]],
            'amount' => ['required', 'positive'],
            'transaction_date' => ['required', 'date'],
        ]);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $db = Database::getInstance();

        $business = $db->fetchOne(
            "SELECT id FROM businesses WHERE id = ? AND is_active = 1",
            [(int)$input['business_id']]
        );

        if (!$business) {
            Response::notFound('Business not found');
            exit;
        }

        if (isset($input['partner_id']) && $input['partner_id']) {
            $partner = $db->fetchOne(
                "SELECT id FROM partners WHERE id = ? AND business_id = ? AND is_active = 1",
                [(int)$input['partner_id'], (int)$input['business_id']]
            );
            if (!$partner) {
                Response::notFound('Partner not found in this business');
                exit;
            }
        }

        $transactionId = $db->insert('transactions', [
            'business_id' => (int)$input['business_id'],
            'partner_id' => isset($input['partner_id']) && $input['partner_id'] ? (int)$input['partner_id'] : null,
            'transaction_type' => $input['transaction_type'],
            'category' => isset($input['category']) ? Validation::sanitize($input['category']) : null,
            'amount' => (float)$input['amount'],
            'description' => isset($input['description']) ? Validation::sanitize($input['description']) : null,
            'reference_number' => isset($input['reference_number']) ? Validation::sanitize($input['reference_number']) : null,
            'payment_method' => isset($input['payment_method']) ? Validation::sanitize($input['payment_method']) : null,
            'transaction_date' => $input['transaction_date'],
            'is_recurring' => !empty($input['is_recurring']) ? 1 : 0,
            'recurring_interval' => $input['recurring_interval'] ?? null,
            'status' => $input['status'] ?? 'completed',
            'created_by' => $userId,
        ]);

        if ($input['transaction_type'] === 'income') {
            $balanceChange = (float)$input['amount'];
        } elseif ($input['transaction_type'] === 'expense') {
            $balanceChange = -(float)$input['amount'];
        } elseif ($input['transaction_type'] === 'investment') {
            $balanceChange = (float)$input['amount'];
        } elseif ($input['transaction_type'] === 'withdrawal') {
            $balanceChange = -(float)$input['amount'];
        } else {
            $balanceChange = 0;
        }

        $lastBalance = $db->fetchOne(
            "SELECT balance_after FROM transactions WHERE business_id = ? AND status = 'completed' ORDER BY id DESC LIMIT 1",
            [(int)$input['business_id']]
        );
        $newBalance = ((float)($lastBalance['balance_after'] ?? 0)) + $balanceChange;

        $db->update('transactions', ['balance_after' => $newBalance], 'id = ?', [$transactionId]);

        if (isset($input['partner_id']) && $input['partner_id'] && $balanceChange != 0) {
            $partnerBalance = $db->fetchOne("SELECT balance FROM partners WHERE id = ?", [(int)$input['partner_id']]);
            $newPartnerBalance = ((float)($partnerBalance['balance'] ?? 0)) + $balanceChange;

            $db->update('partners', ['balance' => $newPartnerBalance], 'id = ?', [(int)$input['partner_id']]);

            $lastLedger = $db->fetchOne(
                "SELECT running_balance FROM ledger_entries WHERE partner_id = ? ORDER BY id DESC LIMIT 1",
                [(int)$input['partner_id']]
            );
            $runningBalance = ((float)($lastLedger['running_balance'] ?? 0)) + $balanceChange;

            $db->insert('ledger_entries', [
                'business_id' => (int)$input['business_id'],
                'partner_id' => (int)$input['partner_id'],
                'transaction_id' => $transactionId,
                'entry_type' => $balanceChange > 0 ? 'credit' : 'debit',
                'amount' => abs($balanceChange),
                'description' => $input['description'] ?? ucfirst($input['transaction_type']),
                'reference' => $input['reference_number'] ?? null,
                'running_balance' => $runningBalance,
                'entry_date' => $input['transaction_date'],
                'created_by' => $userId,
            ]);
        }

        $transaction = $db->fetchOne(
            "SELECT t.*, p.name as partner_name, b.name as business_name
             FROM transactions t
             LEFT JOIN partners p ON t.partner_id = p.id
             LEFT JOIN businesses b ON t.business_id = b.id
             WHERE t.id = ?",
            [$transactionId]
        );

        $db->insert('audit_log', [
            'user_id' => $userId,
            'action' => 'create',
            'entity_type' => 'transaction',
            'entity_id' => (int)$transactionId,
            'new_values' => json_encode($transaction),
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? null,
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? null,
        ]);

        Logger::info("Transaction created", [
            'transaction_id' => $transactionId,
            'type' => $input['transaction_type'],
            'amount' => $input['amount'],
        ]);

        Response::created($transaction, 'Transaction created successfully');
    }

    public function read(): void {
        $userId = AuthMiddleware::getUserId();
        $transactionId = (int)($_GET['id'] ?? 0);

        if (!$transactionId) {
            Response::error('Transaction ID is required', 400);
            exit;
        }

        $db = Database::getInstance();
        $transaction = $db->fetchOne(
            "SELECT t.*, p.name as partner_name, b.name as business_name,
                    u.name as created_by_name
             FROM transactions t
             LEFT JOIN partners p ON t.partner_id = p.id
             LEFT JOIN businesses b ON t.business_id = b.id
             LEFT JOIN users u ON t.created_by = u.id
             WHERE t.id = ?",
            [$transactionId]
        );

        if (!$transaction) {
            Response::notFound('Transaction not found');
            exit;
        }

        Response::success($transaction);
    }

    public function update(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $transactionId = (int)($input['id'] ?? 0);
        unset($input['id']);

        if (!$transactionId) {
            Response::error('Transaction ID is required', 400);
            exit;
        }

        $db = Database::getInstance();

        $existing = $db->fetchOne("SELECT * FROM transactions WHERE id = ? AND status != 'cancelled'", [$transactionId]);
        if (!$existing) {
            Response::notFound('Transaction not found');
            exit;
        }

        $allowedFields = [
            'transaction_type', 'category', 'amount', 'description',
            'reference_number', 'payment_method', 'transaction_date',
            'partner_id', 'status', 'is_recurring', 'recurring_interval',
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
        $db->update('transactions', $updateData, 'id = ?', [$transactionId]);

        $transaction = $db->fetchOne(
            "SELECT t.*, p.name as partner_name, b.name as business_name
             FROM transactions t
             LEFT JOIN partners p ON t.partner_id = p.id
             LEFT JOIN businesses b ON t.business_id = b.id
             WHERE t.id = ?",
            [$transactionId]
        );

        $db->insert('audit_log', [
            'user_id' => $userId,
            'action' => 'update',
            'entity_type' => 'transaction',
            'entity_id' => $transactionId,
            'old_values' => $oldValues,
            'new_values' => json_encode($transaction),
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? null,
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? null,
        ]);

        Logger::info("Transaction updated", ['transaction_id' => $transactionId]);

        Response::success($transaction, 'Transaction updated successfully');
    }

    public function delete(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $transactionId = (int)($input['id'] ?? 0);
        if (!$transactionId) {
            $transactionId = (int)($_GET['id'] ?? 0);
        }

        if (!$transactionId) {
            Response::error('Transaction ID is required', 400);
            exit;
        }

        $db = Database::getInstance();

        $existing = $db->fetchOne("SELECT * FROM transactions WHERE id = ? AND status != 'cancelled'", [$transactionId]);
        if (!$existing) {
            Response::notFound('Transaction not found');
            exit;
        }

        $db->update('transactions', ['status' => 'cancelled'], 'id = ?', [$transactionId]);

        $db->insert('audit_log', [
            'user_id' => $userId,
            'action' => 'delete',
            'entity_type' => 'transaction',
            'entity_id' => $transactionId,
            'old_values' => json_encode($existing),
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? null,
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? null,
        ]);

        Logger::info("Transaction deleted", ['transaction_id' => $transactionId]);

        Response::success(null, 'Transaction deleted successfully');
    }
}
