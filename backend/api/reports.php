<?php

class ReportsController {

    private static function getBusinessCondition(array $params, int $userId): array {
        $conditions = ["t.status = 'completed'"];
        $queryParams = [];

        if (isset($params['business_id'])) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$params['business_id'];
        }

        return [implode(' AND ', $conditions), $queryParams];
    }

    public function monthly(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $month = $params['month'] ?? date('Y-m');
        $monthStart = $month . '-01';
        $monthEnd = date('Y-m-t', strtotime($monthStart));

        [$where, $queryParams] = self::getBusinessCondition($params, $userId);
        $conditions = [$where];
        $conditions[] = "t.transaction_date >= ?";
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = $monthStart;
        $queryParams[] = $monthEnd;

        $finalWhere = implode(' AND ', $conditions);
        $db = Database::getInstance();

        $summary = $db->fetchOne(
            "SELECT
                SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as total_income,
                SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as total_expenses,
                SUM(CASE WHEN t.transaction_type = 'investment' THEN t.amount ELSE 0 END) as total_investments,
                SUM(CASE WHEN t.transaction_type = 'withdrawal' THEN t.amount ELSE 0 END) as total_withdrawals,
                COUNT(*) as transaction_count
             FROM transactions t
             WHERE {$finalWhere}",
            $queryParams
        );

        $totalIncome = (float)($summary['total_income'] ?? 0);
        $totalExpenses = (float)($summary['total_expenses'] ?? 0);
        $netProfit = $totalIncome - $totalExpenses;

        $byCategory = $db->fetchAll(
            "SELECT t.category, t.transaction_type, SUM(t.amount) as total, COUNT(*) as count
             FROM transactions t
             WHERE {$finalWhere} AND t.category IS NOT NULL
             GROUP BY t.category, t.transaction_type
             ORDER BY total DESC",
            $queryParams
        );

        $dailyBreakdown = $db->fetchAll(
            "SELECT
                t.transaction_date as date,
                SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as income,
                SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as expenses
             FROM transactions t
             WHERE {$finalWhere}
             GROUP BY t.transaction_date
             ORDER BY t.transaction_date ASC",
            $queryParams
        );

        Response::success([
            'period' => $month,
            'summary' => [
                'total_income' => round($totalIncome, 2),
                'total_expenses' => round($totalExpenses, 2),
                'net_profit' => round($netProfit, 2),
                'total_investments' => round((float)($summary['total_investments'] ?? 0), 2),
                'total_withdrawals' => round((float)($summary['total_withdrawals'] ?? 0), 2),
                'transaction_count' => (int)($summary['transaction_count'] ?? 0),
            ],
            'by_category' => $byCategory,
            'daily_breakdown' => $dailyBreakdown,
        ]);
    }

    public function yearly(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $year = $params['year'] ?? date('Y');
        $yearStart = $year . '-01-01';
        $yearEnd = $year . '-12-31';

        [$where, $queryParams] = self::getBusinessCondition($params, $userId);
        $conditions = [$where];
        $conditions[] = "t.transaction_date >= ?";
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = $yearStart;
        $queryParams[] = $yearEnd;

        $finalWhere = implode(' AND ', $conditions);
        $db = Database::getInstance();

        $summary = $db->fetchOne(
            "SELECT
                SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as total_income,
                SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as total_expenses,
                SUM(CASE WHEN t.transaction_type = 'investment' THEN t.amount ELSE 0 END) as total_investments,
                SUM(CASE WHEN t.transaction_type = 'withdrawal' THEN t.amount ELSE 0 END) as total_withdrawals,
                COUNT(*) as transaction_count
             FROM transactions t
             WHERE {$finalWhere}",
            $queryParams
        );

        $totalIncome = (float)($summary['total_income'] ?? 0);
        $totalExpenses = (float)($summary['total_expenses'] ?? 0);

        $monthlyBreakdown = $db->fetchAll(
            "SELECT
                DATE_FORMAT(t.transaction_date, '%Y-%m') as month,
                SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as income,
                SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as expenses,
                SUM(CASE WHEN t.transaction_type = 'investment' THEN t.amount ELSE 0 END) as investments,
                COUNT(*) as count
             FROM transactions t
             WHERE {$finalWhere}
             GROUP BY DATE_FORMAT(t.transaction_date, '%Y-%m')
             ORDER BY month ASC",
            $queryParams
        );

        Response::success([
            'period' => $year,
            'summary' => [
                'total_income' => round($totalIncome, 2),
                'total_expenses' => round($totalExpenses, 2),
                'net_profit' => round($totalIncome - $totalExpenses, 2),
                'total_investments' => round((float)($summary['total_investments'] ?? 0), 2),
                'total_withdrawals' => round((float)($summary['total_withdrawals'] ?? 0), 2),
                'transaction_count' => (int)($summary['transaction_count'] ?? 0),
            ],
            'monthly_breakdown' => $monthlyBreakdown,
        ]);
    }

    public function partnerWise(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $conditions = ["t.status = 'completed'", "t.partner_id IS NOT NULL"];
        $queryParams = [];

        if (isset($params['business_id'])) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$params['business_id'];
        }

        if (isset($params['date_from'])) {
            $conditions[] = "t.transaction_date >= ?";
            $queryParams[] = $params['date_from'];
        }

        if (isset($params['date_to'])) {
            $conditions[] = "t.transaction_date <= ?";
            $queryParams[] = $params['date_to'];
        }

        $where = implode(' AND ', $conditions);
        $db = Database::getInstance();

        $partnerData = $db->fetchAll(
            "SELECT
                t.partner_id,
                p.name as partner_name,
                p.partner_type,
                p.profit_share_percentage,
                SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as total_income,
                SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as total_expenses,
                SUM(CASE WHEN t.transaction_type = 'investment' THEN t.amount ELSE 0 END) as total_investments,
                SUM(CASE WHEN t.transaction_type = 'withdrawal' THEN t.amount ELSE 0 END) as total_withdrawals,
                COUNT(*) as transaction_count
             FROM transactions t
             LEFT JOIN partners p ON t.partner_id = p.id
             WHERE {$where}
             GROUP BY t.partner_id, p.name, p.partner_type, p.profit_share_percentage
             ORDER BY (total_income - total_expenses) DESC",
            $queryParams
        );

        foreach ($partnerData as &$partner) {
            $partner['net_profit'] = round((float)$partner['total_income'] - (float)$partner['total_expenses'], 2);
            $partner['total_income'] = round((float)$partner['total_income'], 2);
            $partner['total_expenses'] = round((float)$partner['total_expenses'], 2);
            $partner['total_investments'] = round((float)$partner['total_investments'], 2);
            $partner['total_withdrawals'] = round((float)$partner['total_withdrawals'], 2);
        }
        unset($partner);

        Response::success(['partners' => $partnerData]);
    }

    public function businessWise(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $conditions = ["t.status = 'completed'"];
        $queryParams = [];

        if (isset($params['date_from'])) {
            $conditions[] = "t.transaction_date >= ?";
            $queryParams[] = $params['date_from'];
        }

        if (isset($params['date_to'])) {
            $conditions[] = "t.transaction_date <= ?";
            $queryParams[] = $params['date_to'];
        }

        $db = Database::getInstance();

        $businesses = $db->fetchAll(
            "SELECT id FROM businesses WHERE owner_id = ? AND is_active = 1",
            [$userId]
        );

        if (!empty($businesses)) {
            $bizIds = array_column($businesses, 'id');
            $placeholders = implode(',', array_fill(0, count($bizIds), '?'));
            $conditions[] = "t.business_id IN ({$placeholders})";
            $queryParams = array_merge($queryParams, $bizIds);
        }

        $where = implode(' AND ', $conditions);

        $businessData = $db->fetchAll(
            "SELECT
                t.business_id,
                b.name as business_name,
                b.type as business_type,
                SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as total_income,
                SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as total_expenses,
                SUM(CASE WHEN t.transaction_type = 'investment' THEN t.amount ELSE 0 END) as total_investments,
                SUM(CASE WHEN t.transaction_type = 'withdrawal' THEN t.amount ELSE 0 END) as total_withdrawals,
                COUNT(*) as transaction_count,
                (SELECT COUNT(*) FROM partners WHERE business_id = t.business_id AND is_active = 1) as partner_count
             FROM transactions t
             LEFT JOIN businesses b ON t.business_id = b.id
             WHERE {$where}
             GROUP BY t.business_id, b.name, b.type
             ORDER BY (total_income - total_expenses) DESC",
            $queryParams
        );

        foreach ($businessData as &$biz) {
            $biz['net_profit'] = round((float)$biz['total_income'] - (float)$biz['total_expenses'], 2);
            $biz['total_income'] = round((float)$biz['total_income'], 2);
            $biz['total_expenses'] = round((float)$biz['total_expenses'], 2);
            $biz['total_investments'] = round((float)$biz['total_investments'], 2);
            $biz['total_withdrawals'] = round((float)$biz['total_withdrawals'], 2);
        }
        unset($biz);

        Response::success(['businesses' => $businessData]);
    }

    public function cashFlow(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $dateFrom = $params['date_from'] ?? date('Y-m-d', strtotime('-12 months'));
        $dateTo = $params['date_to'] ?? date('Y-m-d');

        [$where, $queryParams] = self::getBusinessCondition($params, $userId);
        $conditions = [$where];
        $conditions[] = "t.transaction_date >= ?";
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = $dateFrom;
        $queryParams[] = $dateTo;

        $finalWhere = implode(' AND ', $conditions);
        $db = Database::getInstance();

        $cashInflow = $db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total
             FROM transactions t
             WHERE {$finalWhere} AND t.transaction_type IN ('income', 'investment', 'loan_received')",
            $queryParams
        )['total'];

        $cashOutflow = $db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total
             FROM transactions t
             WHERE {$finalWhere} AND t.transaction_type IN ('expense', 'withdrawal', 'loan_given', 'repayment')",
            $queryParams
        )['total'];

        $monthlyFlow = $db->fetchAll(
            "SELECT
                DATE_FORMAT(t.transaction_date, '%Y-%m') as month,
                SUM(CASE WHEN t.transaction_type IN ('income', 'investment', 'loan_received')
                    THEN t.amount ELSE 0 END) as inflow,
                SUM(CASE WHEN t.transaction_type IN ('expense', 'withdrawal', 'loan_given', 'repayment')
                    THEN t.amount ELSE 0 END) as outflow
             FROM transactions t
             WHERE {$finalWhere}
             GROUP BY DATE_FORMAT(t.transaction_date, '%Y-%m')
             ORDER BY month ASC",
            $queryParams
        );

        $cumulative = 0;
        foreach ($monthlyFlow as &$month) {
            $month['inflow'] = round((float)$month['inflow'], 2);
            $month['outflow'] = round((float)$month['outflow'], 2);
            $month['net'] = round($month['inflow'] - $month['outflow'], 2);
            $cumulative += $month['net'];
            $month['cumulative'] = round($cumulative, 2);
        }
        unset($month);

        Response::success([
            'period' => ['from' => $dateFrom, 'to' => $dateTo],
            'total_inflow' => round((float)$cashInflow, 2),
            'total_outflow' => round((float)$cashOutflow, 2),
            'net_cash_flow' => round((float)$cashInflow - (float)$cashOutflow, 2),
            'monthly_breakdown' => $monthlyFlow,
        ]);
    }

    public function profitLoss(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $dateFrom = $params['date_from'] ?? date('Y-01-01');
        $dateTo = $params['date_to'] ?? date('Y-m-d');

        [$where, $queryParams] = self::getBusinessCondition($params, $userId);
        $conditions = [$where];
        $conditions[] = "t.transaction_date >= ?";
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = $dateFrom;
        $queryParams[] = $dateTo;

        $finalWhere = implode(' AND ', $conditions);
        $db = Database::getInstance();

        $incomeByCategory = $db->fetchAll(
            "SELECT t.category, SUM(t.amount) as total
             FROM transactions t
             WHERE {$finalWhere} AND t.transaction_type = 'income'
             GROUP BY t.category
             ORDER BY total DESC",
            $queryParams
        );

        $expenseByCategory = $db->fetchAll(
            "SELECT t.category, SUM(t.amount) as total
             FROM transactions t
             WHERE {$finalWhere} AND t.transaction_type = 'expense'
             GROUP BY t.category
             ORDER BY total DESC",
            $queryParams
        );

        $totalIncome = array_sum(array_column($incomeByCategory, 'total'));
        $totalExpenses = array_sum(array_column($expenseByCategory, 'total'));

        Response::success([
            'period' => ['from' => $dateFrom, 'to' => $dateTo],
            'income' => [
                'categories' => $incomeByCategory,
                'total' => round($totalIncome, 2),
            ],
            'expenses' => [
                'categories' => $expenseByCategory,
                'total' => round($totalExpenses, 2),
            ],
            'net_profit' => round($totalIncome - $totalExpenses, 2),
            'profit_margin' => $totalIncome > 0
                ? round((($totalIncome - $totalExpenses) / $totalIncome) * 100, 2)
                : 0,
        ]);
    }

    public function balanceSheet(): void {
        $userId = AuthMiddleware::getUserId();
        $params = Validation::getQueryParams();

        $asOfDate = $params['as_of_date'] ?? date('Y-m-d');

        [$where, $queryParams] = self::getBusinessCondition($params, $userId);
        $conditions = [$where];
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = $asOfDate;

        $finalWhere = implode(' AND ', $conditions);
        $db = Database::getInstance();

        $totalIncome = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total FROM transactions t WHERE {$finalWhere} AND t.transaction_type = 'income'",
            $queryParams
        )['total'] ?? 0);

        $totalExpenses = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total FROM transactions t WHERE {$finalWhere} AND t.transaction_type = 'expense'",
            $queryParams
        )['total'] ?? 0);

        $totalInvestments = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total FROM transactions t WHERE {$finalWhere} AND t.transaction_type = 'investment'",
            $queryParams
        )['total'] ?? 0);

        $totalWithdrawals = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total FROM transactions t WHERE {$finalWhere} AND t.transaction_type = 'withdrawal'",
            $queryParams
        )['total'] ?? 0);

        $loanGiven = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total FROM transactions t WHERE {$finalWhere} AND t.transaction_type = 'loan_given'",
            $queryParams
        )['total'] ?? 0);

        $loanReceived = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total FROM transactions t WHERE {$finalWhere} AND t.transaction_type = 'loan_received'",
            $queryParams
        )['total'] ?? 0);

        $repayments = (float)($db->fetchOne(
            "SELECT COALESCE(SUM(t.amount), 0) as total FROM transactions t WHERE {$finalWhere} AND t.transaction_type = 'repayment'",
            $queryParams
        )['total'] ?? 0);

        $netProfit = $totalIncome - $totalExpenses;
        $cashPosition = $totalIncome - $totalExpenses + $totalInvestments - $totalWithdrawals;
        $receivables = $loanGiven - $repayments;
        $payables = $loanReceived;
        $totalAssets = $cashPosition + max(0, $receivables);
        $totalLiabilities = max(0, $payables);
        $equity = $totalInvestments + $netProfit;
        $totalEquity = $equity - $totalWithdrawals;

        Response::success([
            'as_of_date' => $asOfDate,
            'assets' => [
                'cash_and_equivalents' => round($cashPosition, 2),
                'receivables' => round(max(0, $receivables), 2),
                'total_assets' => round($totalAssets, 2),
            ],
            'liabilities' => [
                'payables' => round($payables, 2),
                'total_liabilities' => round($totalLiabilities, 2),
            ],
            'equity' => [
                'total_investments' => round($totalInvestments, 2),
                'retained_earnings' => round($netProfit, 2),
                'total_withdrawals' => round($totalWithdrawals, 2),
                'total_equity' => round($totalEquity, 2),
            ],
            'balance_check' => [
                'assets_minus_liabilities' => round($totalAssets - $totalLiabilities, 2),
                'is_balanced' => abs(($totalAssets - $totalLiabilities) - $totalEquity) < 0.01,
            ],
        ]);
    }

    public function export(): void {
        $userId = AuthMiddleware::getUserId();
        $input = Validation::getInput();

        $format = $input['format'] ?? 'csv';
        $reportType = $input['type'] ?? 'monthly';

        if (!in_array($format, ['csv', 'json'])) {
            Response::error('Supported formats: csv, json', 400);
            exit;
        }

        $params = $input['params'] ?? [];

        $_GET = array_merge($_GET, $params);

        switch ($reportType) {
            case 'monthly':
                $reportData = $this->getMonthlyData($params);
                break;
            case 'yearly':
                $reportData = $this->getYearlyData($params);
                break;
            case 'partner-wise':
                $reportData = $this->getPartnerWiseData($params);
                break;
            case 'business-wise':
                $reportData = $this->getBusinessWiseData($params);
                break;
            case 'cash-flow':
                $reportData = $this->getCashFlowData($params);
                break;
            case 'profit-loss':
                $reportData = $this->getProfitLossData($params);
                break;
            case 'balance-sheet':
                $reportData = $this->getBalanceSheetData($params);
                break;
            default:
                Response::error('Invalid report type', 400);
                exit;
        }

        if ($format === 'csv') {
            $this->exportCSV($reportData, $reportType);
        } else {
            Response::success($reportData, "Report exported as {$format}");
        }
    }

    private function getMonthlyData(array $params): array {
        $month = $params['month'] ?? date('Y-m');
        $monthStart = $month . '-01';
        $monthEnd = date('Y-m-t', strtotime($monthStart));
        $db = Database::getInstance();

        $conditions = ["t.status = 'completed'"];
        $queryParams = [];
        if (isset($params['business_id'])) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$params['business_id'];
        }
        $conditions[] = "t.transaction_date >= ?";
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = $monthStart;
        $queryParams[] = $monthEnd;
        $where = implode(' AND ', $conditions);

        return $db->fetchAll(
            "SELECT t.id, t.transaction_type, t.category, t.amount, t.description,
                    t.reference_number, t.payment_method, t.transaction_date,
                    p.name as partner_name
             FROM transactions t
             LEFT JOIN partners p ON t.partner_id = p.id
             WHERE {$where}
             ORDER BY t.transaction_date ASC",
            $queryParams
        );
    }

    private function getYearlyData(array $params): array {
        $year = $params['year'] ?? date('Y');
        $db = Database::getInstance();

        $conditions = ["t.status = 'completed'"];
        $queryParams = [];
        if (isset($params['business_id'])) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$params['business_id'];
        }
        $conditions[] = "t.transaction_date >= ?";
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = $year . '-01-01';
        $queryParams[] = $year . '-12-31';
        $where = implode(' AND ', $conditions);

        return $db->fetchAll(
            "SELECT t.id, t.transaction_type, t.category, t.amount, t.description,
                    t.transaction_date, p.name as partner_name
             FROM transactions t
             LEFT JOIN partners p ON t.partner_id = p.id
             WHERE {$where}
             ORDER BY t.transaction_date ASC",
            $queryParams
        );
    }

    private function getPartnerWiseData(array $params): array {
        $db = Database::getInstance();
        $conditions = ["t.status = 'completed'", "t.partner_id IS NOT NULL"];
        $queryParams = [];
        if (isset($params['business_id'])) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$params['business_id'];
        }
        $where = implode(' AND ', $conditions);

        return $db->fetchAll(
            "SELECT p.name as partner_name, t.transaction_type, SUM(t.amount) as total, COUNT(*) as count
             FROM transactions t
             LEFT JOIN partners p ON t.partner_id = p.id
             WHERE {$where}
             GROUP BY t.partner_id, p.name, t.transaction_type
             ORDER BY p.name, t.transaction_type",
            $queryParams
        );
    }

    private function getBusinessWiseData(array $params): array {
        $db = Database::getInstance();
        $conditions = ["t.status = 'completed'"];
        $queryParams = [];
        $where = implode(' AND ', $conditions);

        return $db->fetchAll(
            "SELECT b.name as business_name, t.transaction_type, SUM(t.amount) as total, COUNT(*) as count
             FROM transactions t
             LEFT JOIN businesses b ON t.business_id = b.id
             WHERE {$where}
             GROUP BY t.business_id, b.name, t.transaction_type
             ORDER BY b.name, t.transaction_type",
            $queryParams
        );
    }

    private function getCashFlowData(array $params): array {
        $dateFrom = $params['date_from'] ?? date('Y-m-d', strtotime('-12 months'));
        $dateTo = $params['date_to'] ?? date('Y-m-d');
        $db = Database::getInstance();

        $conditions = ["t.status = 'completed'"];
        $queryParams = [];
        if (isset($params['business_id'])) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$params['business_id'];
        }
        $conditions[] = "t.transaction_date >= ?";
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = $dateFrom;
        $queryParams[] = $dateTo;
        $where = implode(' AND ', $conditions);

        return $db->fetchAll(
            "SELECT DATE_FORMAT(t.transaction_date, '%Y-%m') as month,
                    t.transaction_type, SUM(t.amount) as total
             FROM transactions t
             WHERE {$where}
             GROUP BY DATE_FORMAT(t.transaction_date, '%Y-%m'), t.transaction_type
             ORDER BY month ASC, t.transaction_type",
            $queryParams
        );
    }

    private function getProfitLossData(array $params): array {
        $dateFrom = $params['date_from'] ?? date('Y-01-01');
        $dateTo = $params['date_to'] ?? date('Y-m-d');
        $db = Database::getInstance();

        $conditions = ["t.status = 'completed'"];
        $queryParams = [];
        if (isset($params['business_id'])) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$params['business_id'];
        }
        $conditions[] = "t.transaction_date >= ?";
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = $dateFrom;
        $queryParams[] = $dateTo;
        $where = implode(' AND ', $conditions);

        return $db->fetchAll(
            "SELECT t.transaction_type, t.category, SUM(t.amount) as total
             FROM transactions t
             WHERE {$where} AND t.transaction_type IN ('income', 'expense')
             GROUP BY t.transaction_type, t.category
             ORDER BY t.transaction_type, total DESC",
            $queryParams
        );
    }

    private function getBalanceSheetData(array $params): array {
        $asOfDate = $params['as_of_date'] ?? date('Y-m-d');
        $db = Database::getInstance();

        $conditions = ["t.status = 'completed'"];
        $queryParams = [];
        if (isset($params['business_id'])) {
            $conditions[] = "t.business_id = ?";
            $queryParams[] = (int)$params['business_id'];
        }
        $conditions[] = "t.transaction_date <= ?";
        $queryParams[] = $asOfDate;
        $where = implode(' AND ', $conditions);

        return $db->fetchAll(
            "SELECT t.transaction_type, SUM(t.amount) as total
             FROM transactions t
             WHERE {$where}
             GROUP BY t.transaction_type",
            $queryParams
        );
    }

    private function exportCSV(array $data, string $reportType): void {
        if (empty($data)) {
            Response::error('No data to export', 400);
            exit;
        }

        $filename = "{$reportType}_report_" . date('Y-m-d_His') . ".csv";

        header('Content-Type: text/csv; charset=UTF-8');
        header("Content-Disposition: attachment; filename=\"{$filename}\"");
        header('Pragma: no-cache');
        header('Expires: 0');

        $output = fopen('php://output', 'w');
        fprintf($output, chr(0xEF).chr(0xBB).chr(0xBF));

        fputcsv($output, array_keys($data[0]));

        foreach ($data as $row) {
            fputcsv($output, $row);
        }

        fclose($output);
        exit;
    }
}
