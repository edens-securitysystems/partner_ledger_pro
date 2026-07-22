# Partner Ledger Pro - API Documentation

## Base URL
```
http://localhost:8000/api/v1
```

## Authentication

All protected endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer <token>
```

## Response Format

### Success
```json
{
    "success": true,
    "message": "Success",
    "data": { ... }
}
```

### Error
```json
{
    "success": false,
    "message": "Error message",
    "errors": { ... }
}
```

### Paginated
```json
{
    "success": true,
    "message": "Success",
    "data": [ ... ],
    "pagination": {
        "total": 100,
        "page": 1,
        "per_page": 20,
        "total_pages": 5,
        "has_next": true,
        "has_prev": false
    }
}
```

---

## Authentication Endpoints

### POST /auth/register
Register a new user account.

**Request:**
```json
{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "phone": "+1234567890"
}
```

**Response (201):**
```json
{
    "success": true,
    "message": "Registration successful",
    "data": {
        "user": { "id": 1, "email": "john@example.com", "name": "John Doe", "role": "viewer" },
        "token": "eyJ...",
        "refresh_token": "eyJ..."
    }
}
```

### POST /auth/login
Login with email and password.

**Request:**
```json
{
    "email": "john@example.com",
    "password": "password123"
}
```

**Response (200):**
```json
{
    "success": true,
    "message": "Login successful",
    "data": {
        "user": { "id": 1, "email": "john@example.com", "name": "John Doe", "role": "viewer" },
        "token": "eyJ...",
        "refresh_token": "eyJ..."
    }
}
```

### POST /auth/refresh-token
Refresh an expired access token.

**Request:**
```json
{
    "refresh_token": "eyJ..."
}
```

### POST /auth/logout
Logout current user. **Auth required.**

### GET /auth/profile
Get current user profile. **Auth required.**

### POST /auth/forgot-password
Request a password reset link.

**Request:**
```json
{
    "email": "john@example.com"
}
```

### POST /auth/reset-password
Reset password with token.

**Request:**
```json
{
    "token": "reset-token-here",
    "password": "newpassword123"
}
```

### POST /auth/change-password
Change current password. **Auth required.**

**Request:**
```json
{
    "current_password": "oldpassword",
    "new_password": "newpassword123"
}
```

### POST /auth/update-profile
Update current user profile. **Auth required.**

**Request:**
```json
{
    "name": "John Updated",
    "email": "john.updated@example.com",
    "phone": "+1234567891"
}
```

---

## Partners Endpoints

### GET /partners
List all partners with pagination and filters. **Auth required.**

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | int | Page number (default: 1) |
| per_page | int | Items per page (default: 20, max: 100) |
| business_id | int | Filter by business |
| partner_type | string | Filter by type (equity, silent, operating, managing) |
| search | string | Search by name, email, or phone |

### POST /partners
Create a new partner. **Auth required.**

**Request:**
```json
{
    "business_id": 1,
    "name": "Jane Smith",
    "email": "jane@example.com",
    "phone": "+1234567890",
    "partner_type": "equity",
    "profit_share_percentage": 25.00,
    "investment_amount": 50000.00,
    "credit_limit": 10000.00,
    "joined_at": "2024-01-15"
}
```

### GET /partners/search
Search partners. **Auth required.**

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| q | string | Search query (min 2 chars) |
| business_id | int | Filter by business |

### GET /partners/by-business
Get partners by business. **Auth required.**

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| business_id | int | Business ID (required) |

### PUT /partners
Update a partner. **Auth required.**

**Request:**
```json
{
    "id": 1,
    "name": "Jane Smith Updated",
    "profit_share_percentage": 30.00
}
```

### DELETE /partners
Delete a partner. **Auth required.**

**Request:**
```json
{
    "id": 1
}
```

---

## Transactions Endpoints

### GET /transactions
List transactions with filters. **Auth required.**

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | int | Page number |
| per_page | int | Items per page |
| business_id | int | Filter by business |
| partner_id | int | Filter by partner |
| transaction_type | string | Filter by type |
| category | string | Filter by category |
| status | string | Filter by status |
| date_from | date | Start date (Y-m-d) |
| date_to | date | End date (Y-m-d) |
| min_amount | float | Minimum amount |
| max_amount | float | Maximum amount |
| payment_method | string | Filter by payment method |
| search | string | Search description/reference |
| sort | string | Sort field (default: transaction_date) |
| order | string | Sort direction (ASC/DESC) |

### POST /transactions
Create a new transaction. **Auth required.**

**Request:**
```json
{
    "business_id": 1,
    "partner_id": 1,
    "transaction_type": "income",
    "category": "Sales",
    "amount": 5000.00,
    "description": "Monthly sales revenue",
    "reference_number": "INV-001",
    "payment_method": "bank_transfer",
    "transaction_date": "2024-01-15"
}
```

**Transaction Types:** income, expense, investment, withdrawal, transfer, loan_given, loan_received, repayment

### PUT /transactions
Update a transaction. **Auth required.**

**Request:**
```json
{
    "id": 1,
    "amount": 5500.00,
    "description": "Updated description"
}
```

### DELETE /transactions
Soft-delete (cancel) a transaction. **Auth required.**

**Request:**
```json
{
    "id": 1
}
```

---

## Dashboard Endpoint

### GET /dashboard
Get dashboard summary. **Auth required.**

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| business_id | int | Filter by business |

**Response (200):**
```json
{
    "success": true,
    "data": {
        "today": {
            "profit": 1250.00,
            "income": 5000.00,
            "expenses": 3750.00
        },
        "month": {
            "profit": 15000.00,
            "income": 50000.00,
            "expenses": 35000.00
        },
        "total": {
            "profit": 125000.00,
            "income": 500000.00,
            "expenses": 375000.00
        },
        "investments": 100000.00,
        "withdrawals": 25000.00,
        "outstanding": 15000.00,
        "cash_flow": 125000.00,
        "credit": 600000.00,
        "debit": 475000.00,
        "recent_activity": [ ... ],
        "monthly_trend": [ ... ]
    }
}
```

---

## Reports Endpoints

### GET /reports/monthly
Monthly report. **Auth required.**

**Query Parameters:** business_id, month (Y-m)

### GET /reports/yearly
Yearly report. **Auth required.**

**Query Parameters:** business_id, year (Y)

### GET /reports/partner-wise
Partner-wise breakdown. **Auth required.**

**Query Parameters:** business_id, date_from, date_to

### GET /reports/business-wise
Business-wise breakdown. **Auth required.**

**Query Parameters:** date_from, date_to

### GET /reports/cash-flow
Cash flow report. **Auth required.**

**Query Parameters:** business_id, date_from, date_to

### GET /reports/profit-loss
Profit & Loss statement. **Auth required.**

**Query Parameters:** business_id, date_from, date_to

### GET /reports/balance-sheet
Balance sheet. **Auth required.**

**Query Parameters:** business_id, as_of_date

### POST /reports/export
Export report data. **Auth required.**

**Request:**
```json
{
    "format": "csv",
    "type": "monthly",
    "params": {
        "business_id": 1,
        "month": "2024-01"
    }
}
```

---

## Profit Endpoints

### GET /profit/calculate
Calculate profit distribution. **Auth required.**

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| business_id | int | Business ID |
| date_from | date | Start date |
| date_to | date | End date |
| method | string | Distribution method (percentage, equal, manual, custom) |

### PUT /profit/distribute
Execute profit distribution. **Auth required.**

**Request:**
```json
{
    "business_id": 1,
    "period_from": "2024-01-01",
    "period_to": "2024-01-31",
    "method": "percentage"
}
```

### GET /profit/report
Get annual profit report. **Auth required.**

**Query Parameters:** business_id, year

---

## Notifications Endpoints

### GET /notifications
List notifications. **Auth required.**

**Query Parameters:** page, per_page, type, is_read

### POST /notifications/mark-read
Mark a notification as read. **Auth required.**

**Request:**
```json
{
    "id": 1
}
```

### POST /notifications/mark-all-read
Mark all notifications as read. **Auth required.**

### GET /notifications/unread-count
Get count of unread notifications. **Auth required.**

---

## Settings Endpoints

### GET /settings
Get user settings. **Auth required.**

**Response (200):**
```json
{
    "success": true,
    "data": {
        "theme": "light",
        "currency": "USD",
        "currency_symbol": "$",
        "language": "en",
        "date_format": "Y-m-d",
        "notifications_enabled": true,
        "items_per_page": 20
    }
}
```

### PUT /settings
Update user settings. **Auth required.**

**Request:**
```json
{
    "theme": "dark",
    "currency": "EUR",
    "notifications_enabled": false
}
```

**Available Settings:**
| Key | Type | Values |
|-----|------|--------|
| theme | string | light, dark, auto |
| currency | string | ISO 4217 code (USD, EUR, etc.) |
| language | string | en, es, fr, etc. |
| date_format | string | Y-m-d, d/m/Y, m/d/Y |
| time_format | string | 12h, 24h |
| notifications_enabled | boolean | true, false |
| email_notifications | boolean | true, false |
| push_notifications | boolean | true, false |
| transaction_notifications | boolean | true, false |
| profit_alert_threshold | float | >= 0 |
| items_per_page | integer | 5-100 |

---

## Upload Endpoints

### POST /upload/image
Upload an image file. **Auth required.**

**Request:** `multipart/form-data` with field `file`

**Allowed Types:** image/jpeg, image/png, image/gif, image/webp
**Max Size:** 5MB

### POST /upload/attachment
Upload an attachment. **Auth required.**

**Request:** `multipart/form-data` with field `file`

**Allowed Types:** All image types + PDF, DOC, DOCX, XLS, XLSX, CSV
**Max Size:** 10MB

---

## Ledger Endpoints

### GET /ledger
Get partner ledger entries. **Auth required.**

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| partner_id | int | Partner ID (required) |
| business_id | int | Business ID |
| page | int | Page number |
| per_page | int | Items per page |
| date_from | date | Start date |
| date_to | date | End date |

### POST /ledger/entries
Add a ledger entry. **Auth required.**

**Request:**
```json
{
    "partner_id": 1,
    "entry_type": "credit",
    "amount": 1000.00,
    "description": "Payment received",
    "entry_date": "2024-01-15",
    "reference": "PAY-001"
}
```

---

## Rate Limits

- **General endpoints:** 100 requests per 15 minutes
- **Auth endpoints:** 10 requests per 15 minutes

**Response Headers:**
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Remaining requests
- `X-RateLimit-Reset`: Reset timestamp

When rate limited (HTTP 429):
```json
{
    "success": false,
    "message": "Rate limit exceeded. Please try again later."
}
```

---

## HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 409 | Conflict |
| 422 | Validation Error |
| 429 | Too Many Requests |
| 500 | Internal Server Error |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| DB_HOST | localhost | MariaDB host |
| DB_NAME | partner_ledger_pro | Database name |
| DB_USER | root | Database user |
| DB_PASS | (empty) | Database password |
| DB_PORT | 3306 | Database port |
| JWT_SECRET | (default key) | JWT signing secret |
| JWT_EXPIRY | 3600 | Token expiry (seconds) |
| JWT_REFRESH_EXPIRY | 604800 | Refresh token expiry |
| APP_ENV | development | Environment |
