<?php

class DashboardController {

    public function summary(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();
        $businessId = $params['business_id'] ?? null;

        $db = Database::getInstance();

        $conditions = ["t.status = 'completed'"];
        $queryParams = [];

        if ($businessId) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$businessId;
        } else {
            $userBusinesses = $db->fetchAll(
                "SELECT id FROM businesses WHERE owner_id = ? AND is_active = 1",
                [$userId]
            );
            $partnerBusinesses = $db->fetchAll(
                "SELECT DISTINCT business_id FROM partners WHERE user_id = ? AND is_active = 1",
                [$userId]
            );

            $allBusinessIds = array_unique(array_merge(
                array_column($userBusinesses, 'id'),
                array_column($partnerBusinesses, 'business_id')
            ));

            if (empty($allBusinessIds)) {
                Response::success(self::emptyDashboard());
                exit;
            }

            $placeholders = implode(',', array_fill(0, count($allBusinessIds), '?'));
            $conditions[] = "t.business_id IN ({$placeholders})";
            $queryParams = array_merge($queryParams, $allBusinessIds);
        }

        $where = implode(' AND ', $conditions);

        $today = date('Y-m-d');
        $monthStart = date('Y-m-01');
        $yearStart = date('Y-01-01');

        $todayIncome = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'income' AND t.transaction_date = ?",
            array_merge($queryParams, [$today])
        )['total'] ?? 0);

        $todayExpenses = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'expense' AND t.transaction_date = ?",
            array_merge($queryParams, [$today])
        )['total'] ?? 0);

        $todayProfit = $todayIncome - $todayExpenses;

        $monthIncome = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'income' AND t.transaction_date >= ?",
            array_merge($queryParams, [$monthStart])
        )['total'] ?? 0);

        $monthExpenses = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'expense' AND t.transaction_date >= ?",
            array_merge($queryParams, [$monthStart])
        )['total'] ?? 0);

        $monthProfit = $monthIncome - $monthExpenses;

        $yearIncome = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'income' AND t.transaction_date >= ?",
            array_merge($queryParams, [$yearStart])
        )['total'] ?? 0);

        $yearExpenses = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'expense' AND t.transaction_date >= ?",
            array_merge($queryParams, [$yearStart])
        )['total'] ?? 0);

        $totalProfit = $yearIncome - $yearExpenses;

        $totalIncome = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'income'",
            $queryParams
        )['total'] ?? 0);

        $totalExpenses = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'expense'",
            $queryParams
        )['total'] ?? 0);

        $investments = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'investment'",
            $queryParams
        )['total'] ?? 0);

        $withdrawals = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'withdrawal'",
            $queryParams
        )['total'] ?? 0);

        $loanGiven = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'loan_given'",
            $queryParams
        )['total'] ?? 0);

        $loanReceived = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'loan_received'",
            $queryParams
        )['total'] ?? 0);

        $repayments = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(amount), 0) as total FROM transactions t
             WHERE {$where} AND t.transaction_type = 'repayment'",
            $queryParams
        )['total'] ?? 0);

        $outstanding = $loanGiven - $repayments;

        $cashIn = $totalIncome + $investments + $loanReceived;
        $cashOut = $totalExpenses + $withdrawals + $loanGiven + $repayments;
        $cashFlow = $cashIn - $cashOut;

        $credit = $totalIncome + $investments + $loanReceived;
        $debit = $totalExpenses + $withdrawals + $loanGiven;

        $recentActivity = $db->fetchAll(
            "SELECT t.*, p.name as partner_name, b.name as business_name
             FROM transactions t
             LEFT JOIN partners p ON t.partner_id = p.id
             LEFT JOIN businesses b ON t.business_id = b.id
             WHERE {$where}
             ORDER BY t.created_at DESC
             LIMIT 10",
            $queryParams
        );

        $monthlyTrend = $db->fetchAll(
            "SELECT
                DATE_FORMAT(t.transaction_date, '%Y-%m') as month,
                SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as income,
                SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as expenses,
                SUM(CASE WHEN t.transaction_type = 'investment' THEN t.amount ELSE 0 END) as investments
             FROM transactions t
             WHERE {$where} AND t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
             GROUP BY DATE_FORMAT(t.transaction_date, '%Y-%m')
             ORDER BY month ASC",
            $queryParams
        );

        Response::success([
            'today' => [
                'profit' => round($todayProfit, 2),
                'income' => round($todayIncome, 2),
                'expenses' => round($todayExpenses, 2),
            ],
            'month' => [
                'profit' => round($monthProfit, 2),
                'income' => round($monthIncome, 2),
                'expenses' => round($monthExpenses, 2),
            ],
            'total' => [
                'profit' => round($totalProfit, 2),
                'income' => round($totalIncome, 2),
                'expenses' => round($totalExpenses, 2),
            ],
            'investments' => round($investments, 2),
            'withdrawals' => round($withdrawals, 2),
            'outstanding' => round($outstanding, 2),
            'cash_flow' => round($cashFlow, 2),
            'credit' => round($credit, 2),
            'debit' => round($debit, 2),
            'recent_activity' => $recentActivity,
            'monthly_trend' => $monthlyTrend,
        ]);
    }

    private static function emptyDashboard(): array {
        return [
            'today' => ['profit' => 0, 'income' => 0, 'expenses' => 0],
            'month' => ['profit' => 0, 'income' => 0, 'expenses' => 0],
            'total' => ['profit' => 0, 'income' => 0, 'expenses' => 0],
            'investments' => 0,
            'withdrawals' => 0,
            'outstanding' => 0,
            'cash_flow' => 0,
            'credit' => 0,
            'debit' => 0,
            'recent_activity' => [],
            'monthly_trend' => [],
        ];
    }
}
