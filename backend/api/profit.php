<?php

class ProfitController {

    public function calculate(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $businessId = $params['business_id'] ?? null;
        $dateFrom = $params['date_from'] ?? date('Y-m-01');
        $dateTo = $params['date_to'] ?? date('Y-m-d');
        $method = $params['method'] ?? 'percentage';

        $db = Database::getInstance();

        $conditions = ["t.status = 'completed'"];
        $queryParams = [];

        if ($businessId) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$businessId;
        }

        $conditions[] = "t.transaction_date >= ?";
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = $dateFrom;
        $queryParams[] = $dateTo;

        $where = implode(' AND ', $conditions);

        $totalIncome = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total
             FROM transactions t
             WHERE {$where} AND t.transaction_type = 'income'",
            $queryParams
        )['total'] ?? 0);

        $totalExpenses = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total
             FROM transactions t
             WHERE {$where} AND t.transaction_type = 'expense'",
            $queryParams
        )['total'] ?? 0);

        $netProfit = $totalIncome - $totalExpenses;

        $partnerConditions = $conditions;
        $partnerQueryParams = $queryParams;

        if ($businessId) {
            $partnerConditions[] = "t.partner_id IS NOT NULL";
        }

        $partnerWhere = implode(' AND ', $partnerConditions);

        $partnerContributions = $db->fetchAll(
            "SELECT
                t.partner_id,
                p.name as partner_name,
                p.profit_share_percentage,
                p.partner_type,
                SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as income,
                SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as expenses
             FROM transactions t
             LEFT JOIN partners p ON t.partner_id = p.id
             WHERE {$partnerWhere}
             GROUP BY t.partner_id, p.name, p.profit_share_percentage, p.partner_type",
            $partnerQueryParams
        );

        $distributions = [];
        $totalDistributed = 0;

        switch ($method) {
            case 'percentage':
                foreach ($partnerContributions as $partner) {
                    $share = (float)$partner['profit_share_percentage'];
                    $partnerProfit = round($netProfit * ($share / 100), 2);
                    $partnerProfit = max(0, $partnerProfit);
                    $totalDistributed += $partnerProfit;

                    $distributions[] = [
                        'partner_id' => (int)$partner['partner_id'],
                        'partner_name' => $partner['partner_name'],
                        'profit_share_percentage' => $share,
                        'contribution_income' => round((float)$partner['income'], 2),
                        'contribution_expenses' => round((float)$partner['expenses'], 2),
                        'net_contribution' => round((float)$partner['income'] - (float)$partner['expenses'], 2),
                        'profit_share' => $partnerProfit,
                        'method' => 'percentage',
                    ];
                }
                break;

            case 'equal':
                $activePartners = array_filter($partnerContributions, fn($p) => (float)$p['profit_share_percentage'] > 0 || $p['partner_type'] !== 'silent');
                $partnerCount = count($activePartners);
                if ($partnerCount > 0) {
                    $perPartner = round($netProfit / $partnerCount, 2);
                    foreach ($activePartners as $partner) {
                        $partnerProfit = max(0, $perPartner);
                        $totalDistributed += $partnerProfit;
                        $distributions[] = [
                            'partner_id' => (int)$partner['partner_id'],
                            'partner_name' => $partner['partner_name'],
                            'profit_share_percentage' => round(100 / $partnerCount, 2),
                            'contribution_income' => round((float)$partner['income'], 2),
                            'contribution_expenses' => round((float)$partner['expenses'], 2),
                            'net_contribution' => round((float)$partner['income'] - (float)$partner['expenses'], 2),
                            'profit_share' => $partnerProfit,
                            'method' => 'equal',
                        ];
                    }
                }
                break;

            case 'manual':
                foreach ($partnerContributions as $partner) {
                    $contributed = (float)$partner['income'] - (float)$partner['expenses'];
                    $totalContributions = array_sum(array_map(fn($p) => abs((float)$p['income'] - (float)$p['expenses']), $partnerContributions));
                    $ratio = $totalContributions > 0 ? abs($contributed) / $totalContributions : 0;
                    $partnerProfit = round($netProfit * $ratio, 2);
                    $partnerProfit = max(0, $partnerProfit);
                    $totalDistributed += $partnerProfit;

                    $distributions[] = [
                        'partner_id' => (int)$partner['partner_id'],
                        'partner_name' => $partner['partner_name'],
                        'profit_share_percentage' => round($ratio * 100, 2),
                        'contribution_income' => round((float)$partner['income'], 2),
                        'contribution_expenses' => round((float)$partner['expenses'], 2),
                        'net_contribution' => round($contributed, 2),
                        'profit_share' => $partnerProfit,
                        'method' => 'contribution_based',
                    ];
                }
                break;

            case 'custom':
                foreach ($partnerContributions as $partner) {
                    $share = (float)$partner['profit_share_percentage'];
                    $partnerProfit = round($netProfit * ($share / 100), 2);
                    $partnerProfit = max(0, $partnerProfit);
                    $totalDistributed += $partnerProfit;

                    $distributions[] = [
                        'partner_id' => (int)$partner['partner_id'],
                        'partner_name' => $partner['partner_name'],
                        'profit_share_percentage' => $share,
                        'contribution_income' => round((float)$partner['income'], 2),
                        'contribution_expenses' => round((float)$partner['expenses'], 2),
                        'net_contribution' => round((float)$partner['income'] - (float)$partner['expenses'], 2),
                        'profit_share' => $partnerProfit,
                        'method' => 'custom',
                    ];
                }
                break;
        }

        Response::success([
            'period' => ['from' => $dateFrom, 'to' => $dateTo],
            'summary' => [
                'total_income' => round($totalIncome, 2),
                'total_expenses' => round($totalExpenses, 2),
                'net_profit' => round($netProfit, 2),
                'total_distributed' => round($totalDistributed, 2),
                'undistributed' => round($netProfit - $totalDistributed, 2),
            ],
            'method' => $method,
            'distributions' => $distributions,
        ]);
    }

    public function distribute(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $errors = Validation::validate($input, [
            'business_id' => ['required', 'positive'],
            'period_from' => ['required', 'date'],
            'period_to' => ['required', 'date'],
            'method' => ['required', 'in' => [AppConfig::PROFIT_DISTRIBUTION_METHODS]],
        ]);

        if (!empty($errors)) {
            Response::validation($errors);
            exit;
        }

        if (strtotime($input['period_from']) > strtotime($input['period_to'])) {
            Response::error('Period start date must be before end date', 400);
            exit;
        }

        $db = Database::getInstance();

        $existing = $db->fetchOne(
            "SELECT id FROM profit_distributions
             WHERE business_id = ? AND period_from = ? AND period_to = ? AND status = 'completed'",
            [(int)$input['business_id'], $input['period_from'], $input['period_to']]
        );

        if ($existing) {
            Response::error('Profit has already been distributed for this period', 409);
            exit;
        }

        $business = $db->fetchOne(
            "SELECT id, name FROM businesses WHERE id = ? AND is_active = 1",
            [(int)$input['business_id']]
        );

        if (!$business) {
            Response::notFound('Business not found');
            exit;
        }

        $_GET['business_id'] = $input['business_id'];
        $_GET['date_from'] = $input['period_from'];
        $_GET['date_to'] = $input['period_to'];
        $_GET['method'] = $input['method'];

        $conditions = ["t.status = 'completed'"];
        $queryParams = [
            (int)$input['business_id'],
            $input['period_from'],
            $input['period_to'],
        ];

        $conditions[] = "t.business_id = ?";
        $conditions[] = "t.transaction_date >= ?";
        $conditions[] = "t.transaction_date <= ?";
        $where = implode(' AND ', $conditions);

        $totalIncome = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total FROM transactions t WHERE {$where} AND t.transaction_type = 'income'",
            $queryParams
        )['total'] ?? 0);

        $totalExpenses = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total FROM transactions t WHERE {$where} AND t.transaction_type = 'expense'",
            $queryParams
        )['total'] ?? 0);

        $netProfit = $totalIncome - $totalExpenses;

        $partnerConditions = ["t.status = 'completed'", "t.business_id = ?", "t.partner_id IS NOT NULL",
            "t.transaction_date >= ?", "t.transaction_date <= ?"];
        $partnerQueryParams = $queryParams;

        $partnerWhere = implode(' AND ', $partnerConditions);

        $partnerContributions = $db->fetchAll(
            "SELECT t.partner_id, p.name as partner_name, p.profit_share_percentage,
                    SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as income,
                    SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as expenses
             FROM transactions t
             LEFT JOIN partners p ON t.partner_id = p.id
             WHERE {$partnerWhere}
             GROUP BY t.partner_id, p.name, p.profit_share_percentage",
            $partnerQueryParams
        );

        $distributions = [];
        $method = $input['method'];

        foreach ($partnerContributions as $partner) {
            $share = (float)$partner['profit_share_percentage'];
            $partnerProfit = round($netProfit * ($share / 100), 2);
            $partnerProfit = max(0, $partnerProfit);

            $distributions[] = [
                'partner_id' => (int)$partner['partner_id'],
                'partner_name' => $partner['partner_name'],
                'share_percentage' => $share,
                'amount' => $partnerProfit,
            ];
        }

        $distributionData = [
            'business_id' => (int)$input['business_id'],
            'period_from' => $input['period_from'],
            'period_to' => $input['period_to'],
            'total_income' => $totalIncome,
            'total_expenses' => $totalExpenses,
            'net_profit' => $netProfit,
            'distribution_method' => $method,
            'distributions' => json_encode($distributions),
            'status' => 'completed',
            'distributed_by' => $userId,
            'distributed_at' => date('Y-m-d H:i:s'),
        ];

        if (!$db->fetchOne("SHOW TABLES LIKE 'profit_distributions'", [])) {
            $db->query("CREATE TABLE IF NOT EXISTS profit_distributions (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                business_id INT UNSIGNED NOT NULL,
                period_from DATE NOT NULL,
                period_to DATE NOT NULL,
                total_income DECIMAL(15,2) NOT NULL,
                total_expenses DECIMAL(15,2) NOT NULL,
                net_profit DECIMAL(15,2) NOT NULL,
                distribution_method VARCHAR(50) NOT NULL,
                distributions JSON NOT NULL,
                status VARCHAR(50) NOT NULL DEFAULT 'completed',
                distributed_by INT UNSIGNED DEFAULT NULL,
                distributed_at TIMESTAMP NULL DEFAULT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                INDEX idx_profit_distributions_business (business_id),
                INDEX idx_profit_distributions_period (period_from, period_to)
            ) ENGINE=InnoDB");
        }

        $distId = $db->insert('profit_distributions', $distributionData);

        foreach ($distributions as $dist) {
            if ($dist['amount'] > 0) {
                $partnerBalance = $db->fetchOne("SELECT balance FROM partners WHERE id = ?", [$dist['partner_id']]);
                $newBalance = ((float)($partnerBalance['balance'] ?? 0)) + $dist['amount'];
                $db->update('partners', ['balance' => $newBalance], 'id = ?', [$dist['partner_id']]);

                $lastLedger = $db->fetchOne(
                    "SELECT running_balance FROM ledger_entries WHERE partner_id = ? ORDER BY id DESC LIMIT 1",
                    [$dist['partner_id']]
                );
                $runningBalance = ((float)($lastLedger['running_balance'] ?? 0)) + $dist['amount'];

                $db->insert('ledger_entries', [
                    'business_id' => (int)$input['business_id'],
                    'partner_id' => $dist['partner_id'],
                    'entry_type' => 'credit',
                    'amount' => $dist['amount'],
                    'description' => "Profit distribution for {$input['period_from']} to {$input['period_to']}",
                    'reference' => "PD-{$distId}",
                    'running_balance' => $runningBalance,
                    'entry_date' => date('Y-m-d'),
                    'created_by' => $userId,
                ]);

                $db->insert('transactions', [
                    'business_id' => (int)$input['business_id'],
                    'partner_id' => $dist['partner_id'],
                    'transaction_type' => 'income',
                    'category' => 'Profit Distribution',
                    'amount' => $dist['amount'],
                    'description' => "Profit share: {$dist['partner_name']} ({$dist['share_percentage']}%)",
                    'transaction_date' => date('Y-m-d'),
                    'status' => 'completed',
                    'created_by' => $userId,
                ]);
            }
        }

        $db->insert('audit_log', [
            'user_id' => $userId,
            'action' => 'distribute_profit',
            'entity_type' => 'profit_distribution',
            'entity_id' => (int)$distId,
            'new_values' => json_encode($distributionData),
            'ip_address' => $_SERVER['REMOTE_ADDR'] ?? null,
            'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? null,
        ]);

        Logger::info("Profit distributed", [
            'distribution_id' => $distId,
            'business_id' => $input['business_id'],
            'net_profit' => $netProfit,
            'method' => $method,
        ]);

        Response::created([
            'distribution_id' => (int)$distId,
            'period' => ['from' => $input['period_from'], 'to' => $input['period_to']],
            'net_profit' => round($netProfit, 2),
            'distributions' => $distributions,
        ], 'Profit distributed successfully');
    }

    public function report(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $businessId = $params['business_id'] ?? null;
        $year = $params['year'] ?? date('Y');

        $db = Database::getInstance();

        $conditions = ["t.status = 'completed'"];
        $queryParams = [];

        if ($businessId) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$businessId;
        }

        $conditions[] = "t.transaction_date >= ?";
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = "{$year}-01-01";
        $queryParams[] = "{$year}-12-31";

        $where = implode(' AND ', $conditions);

        $monthlyData = $db->fetchAll(
            "SELECT
                DATE_FORMAT(t.transaction_date, '%Y-%m') as month,
                SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as income,
                SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as expenses
             FROM transactions t
             WHERE {$where}
             GROUP BY DATE_FORMAT(t.transaction_date, '%Y-%m')
             ORDER BY month ASC",
            $queryParams
        );

        $report = [];
        $cumulativeProfit = 0;

        foreach ($monthlyData as $month) {
            $income = (float)$month['income'];
            $expenses = (float)$month['expenses'];
            $profit = $income - $expenses;
            $cumulativeProfit += $profit;

            $report[] = [
                'month' => $month['month'],
                'income' => round($income, 2),
                'expenses' => round($expenses, 2),
                'net_profit' => round($profit, 2),
                'cumulative_profit' => round($cumulativeProfit, 2),
                'profit_margin' => $income > 0 ? round(($profit / $income) * 100, 2) : 0,
            ];
        }

        $totalIncome = array_sum(array_column($report, 'income'));
        $totalExpenses = array_sum(array_column($report, 'expenses'));

        Response::success([
            'year' => (int)$year,
            'annual_summary' => [
                'total_income' => round($totalIncome, 2),
                'total_expenses' => round($totalExpenses, 2),
                'net_profit' => round($totalIncome - $totalExpenses, 2),
                'avg_monthly_profit' => round(($totalIncome - $totalExpenses) / 12, 2),
                'avg_profit_margin' => $totalIncome > 0
                    ? round((($totalIncome - $totalExpenses) / $totalIncome) * 100, 2)
                    : 0,
            ],
            'monthly_breakdown' => $report,
        ]);
    }
}
