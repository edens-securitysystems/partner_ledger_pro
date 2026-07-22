<?php

class LedgerController {

    public function getPartnerLedger(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $partnerId = (int)($params['partner_id'] ?? 0);
        $businessId = (int)($params['business_id'] ?? 0);

        if (!$partnerId) {
            Response::error('partner_id is required', 400);
            exit;
        }

        $page = max(1, (int)($params['page'] ?? 1));
        $perPage = min(AppConfig::MAX_PAGE_SIZE, max(1, (int)($params['per_page'] ?? AppConfig::DEFAULT_PAGE_SIZE)));
        $offset = ($page - 1) * $perPage;

        $dateFrom = $params['date_from'] ?? null;
        $dateTo = $params['date_to'] ?? null;

        $db = Database::getInstance();

        $partner = $db->fetchOne(
            "SELECT p.*, b.name as business_name
             FROM partners p
             LEFT JOIN businesses b ON p.business_id = b.id
             WHERE p.id = ? AND p.is_active = 1",
            [$partnerId]
        );

        if (!$partner) {
            Response::notFound('Partner not found');
            exit;
        }

        $conditions = ["le.partner_id = ?"];
        $queryParams = [$partnerId];

        if ($businessId) {
            $conditions[] = "le.business_id = ?";
            $queryParams[] = $businessId;
        }

        if ($dateFrom) {
            $conditions[] = "le.entry_date >= ?";
            $queryParams[] = $dateFrom;
        }

        if ($dateTo) {
            $conditions[] = "le.entry_date <= ?";
            $queryParams[] = $dateTo;
        }

        $where = implode(' AND ', $conditions);

        $total = $db->fetchOne(
            "SELECT COUNT(*) as cnt FROM ledger_entries le WHERE {$where}",
            $queryParams
        )['cnt'];

        $entries = $db->fetchAll(
            "SELECT le.*, t.transaction_type, t.category, t.payment_method,
                    u.name as created_by_name
             FROM ledger_entries le
             LEFT JOIN transactions t ON le.transaction_id = t.id
             LEFT JOIN users u ON le.created_by = u.id
             WHERE {$where}
             ORDER BY le.entry_date DESC, le.id DESC
             LIMIT {$perPage} OFFSET {$offset}",
            $queryParams
        );

        $totalCredits = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(le.amount), 0) as total
             FROM ledger_entries le
             WHERE {$where} AND le.entry_type = 'credit'",
            $queryParams
        )['total'] ?? 0);

        $totalDebits = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(le.amount), 0) as total
             FROM ledger_entries le
             WHERE {$where} AND le.entry_type = 'debit'",
            $queryParams
        )['total'] ?? 0);

        $currentBalance = $partner['balance'];

        Response::paginated([
            'partner' => [
                'id' => $partner['id'],
                'name' => $partner['name'],
                'business_name' => $partner['business_name'],
                'current_balance' => round($currentBalance, 2),
                'credit_limit' => round((float)$partner['credit_limit'], 2),
            ],
            'summary' => [
                'total_credits' => round($totalCredits, 2),
                'total_debits' => round($totalDebits, 2),
                'net_balance' => round($totalCredits - $totalDebits, 2),
            ],
            'entries' => $entries,
        ], (int)$total, $page, $perPage);
    }

    public function addEntry(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $errors = Validation::validate($input, [
            'partner_id' => ['required', 'positive'],
            'entry_type' => ['required', 'in' => [['credit', 'debit']]],
            'amount' => ['required', 'positive'],
            'entry_date' => ['required', 'date'],
        ]);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        $db = Database::getInstance();

        $partner = $db->fetchOne(
            "SELECT p.*, b.owner_id
             FROM partners p
             LEFT JOIN businesses b ON p.business_id = b.id
             WHERE p.id = ? AND p.is_active = 1",
            [(int)$input['partner_id']]
        );

        if (!$partner) {
            Response::notFound('Partner not found');
            exit;
        }

        $amount = (float)$input['amount'];
        $entryType = $input['entry_type'];

        $lastEntry = $db->fetchOne(
            "SELECT running_balance FROM ledger_entries
             WHERE partner_id = ?
             ORDER BY entry_date DESC, id DESC
             LIMIT 1",
            [(int)$input['partner_id']]
        );

        $previousBalance = (float)($lastEntry['running_balance'] ?? $partner['balance']);

        if ($entryType === 'credit') {
            $newBalance = $previousBalance + $amount;
        } else {
            $newBalance = $previousBalance - $amount;
        }

        $entryId = $db->insert('ledger_entries', [
            'business_id' => (int)$input['business_id'] ?? $partner['business_id'],
            'partner_id' => (int)$input['partner_id'],
            'transaction_id' => isset($input['transaction_id']) ? (int)$input['transaction_id'] : null,
            'entry_type' => $entryType,
            'amount' => $amount,
            'description' => isset($input['description']) ? Validation::sanitize($input['description']) : null,
            'reference' => isset($input['reference']) ? Validation::sanitize($input['reference']) : null,
            'running_balance' => $newBalance,
            'entry_date' => $input['entry_date'],
            'created_by' => $userId,
        ]);

        $db->update('partners', ['balance' => $newBalance], 'id = ?', [(int)$input['partner_id']]);

        $db->insert('audit_log', [
            'user_id' => $userId,
            'action' => 'create',
            'entity_type' => 'ledger_entry',
            'entity_id' => (int)$entryId,
            'new_values' => json_encode([
                'entry_type' => $entryType,
                'amount' => $amount,
                'running_balance' => $newBalance,
            ]),
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? null,
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? null,
        ]);

        Logger::info("Ledger entry added", [
            'entry_id' => $entryId,
            'partner_id' => $input['partner_id'],
            'type' => $entryType,
            'amount' => $amount,
        ]);

        $entry = $db->fetchOne(
            "SELECT le.*, t.transaction_type, t.category
             FROM ledger_entries le
             LEFT JOIN transactions t ON le.transaction_id = t.id
             WHERE le.id = ?",
            [$entryId]
        );

        Response::created([
            'entry' => $entry,
            'previous_balance' => round($previousBalance, 2),
            'new_balance' => round($newBalance, 2),
        ], 'Ledger entry added successfully');
    }
}
