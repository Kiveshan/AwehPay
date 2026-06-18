# AwePay Firestore Database Structure

This document describes the full Firestore database schema for the AwePay platform, including top-level collections, their document fields, and business subcollections.

---

## Top-Level Collections

### 1. `users`

Stores business owner user profiles.

**Path:** `users/{uid}` (`{uid}` is the Firebase Auth UID)

#### Document Schema

| Field              | Type      | Description                          |
| ------------------ | --------- | ------------------------------------ |
| `uid`              | string    | Unique Firebase Auth user identifier |
| `fullName`         | string    | Full name of the user                |
| `email`            | string    | Email address                        |
| `phoneNumber`      | string    | Mobile number (e.g., `+27000000000`) |
| `role`             | string    | `business_owner`, `customer`, etc.   |
| `businessId`       | string    | Reference to owned business document |
| `profileImageUrl`  | string    | Profile image URL (nullable)         |
| `isActive`         | boolean   | Account active status                |
| `isEmailVerified`  | boolean   | Whether email is verified            |
| `isPhoneVerified`  | boolean   | Whether phone is verified            |
| `createdAt`        | timestamp | Account creation date/time           |
| `updatedAt`        | timestamp | Last update date/time                |
| `lastLoginAt`      | timestamp | Last login date/time                 |

#### Demo Document: `users/demo_user`

| Field              | Type      | Value                |
| ------------------ | --------- | -------------------- |
| `uid`              | string    | `demo_user`          |
| `fullName`         | string    | `Demo User`          |
| `email`            | string    | `demo@awepay.co.za`  |
| `phoneNumber`      | string    | `+27000000000`       |
| `role`             | string    | `business_owner`     |
| `businessId`       | string    | `demo_business`      |
| `isActive`         | boolean   | `true`               |
| `isEmailVerified`  | boolean   | `false`              |
| `isPhoneVerified`  | boolean   | `false`              |
| `createdAt`        | timestamp | current date/time    |
| `updatedAt`        | timestamp | current date/time    |

---

### 2. `adminUsers`

Stores system admin profiles.

**Path:** `adminUsers/{uid}` (`{uid}` is the Firebase Auth UID)

#### Document Schema

| Field          | Type      | Description                          |
| -------------- | --------- | ------------------------------------ |
| `adminUserId`  | string    | Admin-specific identifier            |
| `uid`          | string    | Unique Firebase Auth user identifier |
| `fullName`     | string    | Full name of the admin               |
| `email`        | string    | Admin email address                  |
| `role`         | string    | `admin`, `super_admin`               |
| `permissions`  | map       | Permissions map (see below)          |
| `isActive`     | boolean   | Account active status                |
| `createdAt`    | timestamp | Account creation date/time           |
| `updatedAt`    | timestamp | Last update date/time                |
| `lastLoginAt`  | timestamp | Last login date/time                 |

**`permissions` map:**

| Field                  | Type    |
| ---------------------- | ------- |
| `canManageBusinesses`  | boolean |
| `canManageUsers`       | boolean |
| `canViewReports`       | boolean |
| `canManageSettings`    | boolean |

#### Demo Document: `adminUsers/demo_admin`

| Field          | Type      | Value                 |
| -------------- | --------- | --------------------- |
| `adminUserId`  | string    | `demo_admin`          |
| `uid`          | string    | `demo_admin`          |
| `fullName`     | string    | `Demo Admin`          |
| `email`        | string    | `admin@awepay.co.za`  |
| `role`         | string    | `admin`               |
| `isActive`     | boolean   | `true`                |
| `createdAt`    | timestamp | current date/time     |
| `updatedAt`    | timestamp | current date/time     |

---

### 3. `businesses`

Stores business profiles. Each business document contains multiple subcollections for operations.

**Path:** `businesses/{businessId}`

#### Document Schema

| Field                | Type      | Description                                     |
| -------------------- | --------- | ----------------------------------------------- |
| `businessId`         | string    | Unique business identifier                      |
| `ownerId`            | string    | Reference to `users/{ownerId}`                  |
| `businessName`       | string    | Name of the business                            |
| `businessType`       | string    | e.g., `spaza`, `tuckshop`, `retail`             |
| `registrationNumber` | string    | CIPC / business registration number             |
| `sarsReferenceNumber`| string    | SARS tax reference number                       |
| `description`        | string    | Short description of the business               |
| `phoneNumber`        | string    | Business contact number                         |
| `email`              | string    | Business email address                          |
| `address`            | map       | Address fields (see below)                      |
| `status`             | string    | `pending_verification`, `verified`, `rejected`, `suspended`, `active` |
| `verification`       | map       | Verification status fields (see below)          |
| `paymentProfile`     | map       | Payment acceptance config (see below)           |
| `totals`             | map       | Aggregated totals (see below)                   |
| `subscriptionId`     | string    | Reference to `subscriptions/{subscriptionId}`     |
| `subscription`       | map       | Active subscription details (see below)         |
| `createdAt`          | timestamp | Business creation date/time                     |
| `updatedAt`          | timestamp | Last update date/time                           |

**`address` map:**

| Field         | Type   |
| ------------- | ------ |
| `line1`       | string |
| `line2`       | string |
| `suburb`      | string |
| `city`        | string |
| `province`    | string |
| `postalCode`  | string |
| `country`     | string |

**`verification` map:**

| Field             | Type       |
| ----------------- | ---------- |
| `isVerified`      | boolean    |
| `verifiedAt`      | timestamp  |
| `verifiedBy`      | string     |
| `rejectionReason` | string     |

**`paymentProfile` map:**

| Field               | Type    |
| ------------------- | ------- |
| `acceptsCash`       | boolean |
| `acceptsQr`         | boolean |
| `acceptsDigital`    | boolean |
| `defaultCurrency`   | string  |

**`totals` map:**

| Field                  | Type   |
| ---------------------- | ------ |
| `balance`              | number |
| `totalSales`           | number |
| `totalCashSales`       | number |
| `totalDigitalSales`    | number |
| `totalExpenses`        | number |
| `totalProducts`        | number |
| `totalServices`        | number |

**`subscription` map:**

| Field               | Type       | Description                           |
| ------------------- | ---------- | ------------------------------------- |
| `tierId`            | string     | Reference to `subscriptionTiers/{tierId}` |
| `tierName`          | string     | Display name of the tier              |
| `status`            | string     | `active`, `pending_payment`, `expired`, `cancelled` |
| `startedAt`         | timestamp  | Subscription start date/time          |
| `expiresAt`         | timestamp  | Subscription expiry (nullable)        |
| `nextBillingDate`   | timestamp  | Next billing date (nullable)          |
| `price`             | number     | Subscribed price                      |
| `currency`          | string     | e.g., `ZAR`                           |
| `billingPeriod`     | string     | `free`, `monthly`, `yearly`           |

#### Demo Document: `businesses/demo_business`

| Field                | Type      | Value                        |
| -------------------- | --------- | ---------------------------- |
| `businessId`         | string    | `demo_business`              |
| `ownerId`            | string    | `demo_user`                  |
| `businessName`       | string    | `Demo Spaza Shop`            |
| `businessType`       | string    | `spaza`                      |
| `registrationNumber` | string    | *(empty)*                    |
| `description`        | string    | `Demo business for testing`  |
| `phoneNumber`        | string    | `+27000000000`               |
| `email`              | string    | `demo@awepay.co.za`          |
| `status`             | string    | `active`                     |
| `subscriptionId`     | string    | `demo_subscription`          |
| `subscription`       | map       | `tierId: "basic"`, `tierName: "Basic"`, `status: "active"`, `price: 0`, `currency: "ZAR"`, `billingPeriod: "free"` |
| `createdAt`          | timestamp | current date/time            |
| `updatedAt`          | timestamp | current date/time            |

---

### 4. `auditLogs`

Tracks platform actions and changes for compliance and security.

**Path:** `auditLogs/{logId}`

| Field        | Type      | Description                              |
| ------------ | --------- | ---------------------------------------- |
| `auditLogId` | string    | Unique log identifier                    |
| `actorId`    | string    | User/admin who performed the action      |
| `actorRole`  | string    | Role of the actor (`admin`, `owner`)     |
| `action`     | string    | Action performed (e.g., `user_created`)  |
| `targetType` | string    | What was affected (`user`, `business`)   |
| `targetId`   | string    | ID of the affected resource              |
| `createdAt`  | timestamp | When the action occurred                 |

**Example Document:** `auditLogs/demo_log`

---

### 5. `platformSettings`

Global configuration for the AwePay platform.

**Path:** `platformSettings/{settingId}`

Recommended document IDs: `general`, `payment`, `fees`, `security`

#### `platformSettings/general`

| Field                 | Type      |
| --------------------- | --------- |
| `appName`             | string    |
| `supportEmail`        | string    |
| `supportPhoneNumber`  | string    |
| `maintenanceMode`     | boolean   |
| `minimumAppVersion`   | string    |
| `createdAt`           | timestamp |
| `updatedAt`           | timestamp |

#### `platformSettings/payment`

| Field                      | Type      |
| -------------------------- | --------- |
| `defaultCurrency`          | string    |
| `enabledPaymentMethods`    | map       |
| `createdAt`                | timestamp |
| `updatedAt`                | timestamp |

**`enabledPaymentMethods` map:** `cash`, `qr`, `card`, `eft`, `digital` (all booleans)

#### `platformSettings/fees`

| Field                      | Type      |
| -------------------------- | --------- |
| `platformFeePercentage`    | number    |
| `fixedTransactionFee`      | number    |
| `createdAt`                | timestamp |
| `updatedAt`                | timestamp |

#### `platformSettings/security`

| Field                        | Type      |
| ---------------------------- | --------- |
| `requireEmailVerification`   | boolean   |
| `requireBusinessVerification`| boolean   |
| `appCheckRequired`           | boolean   |
| `createdAt`                  | timestamp |
| `updatedAt`                  | timestamp |

#### Demo Document: `platformSettings/payment_config`

| Field             | Type      | Value             |
| ----------------- | --------- | ----------------- |
| `defaultCurrency` | string    | `ZAR`             |
| `updatedAt`       | timestamp | current date/time |

### 6. `subscriptionTiers`

Stores platform subscription plan definitions. Each tier controls feature access and usage limits.

**Path:** `subscriptionTiers/{tierId}`

#### Document Schema

| Field             | Type      | Description                           |
| ----------------- | --------- | ------------------------------------- |
| `tierId`          | string    | Unique tier identifier                |
| `name`            | string    | Display name (`Basic`, `Plus`, etc.)  |
| `code`            | string    | Short code (`basic`, `plus`, `premium`) |
| `price`           | number    | Monthly / period price                |
| `currency`        | string    | e.g., `ZAR`                           |
| `billingPeriod`   | string    | `free`, `monthly`, `yearly`           |
| `setupFee`        | number    | One-time setup fee                    |
| `description`     | string    | Tier description                      |
| `displayOrder`    | number    | Sort order for UI                     |
| `isActive`        | boolean   | Whether tier is available             |
| `isRecommended`   | boolean   | Whether tier is flagged as recommended |
| `features`        | array     | List of feature strings               |
| `limits`          | map       | Usage limits (see below)              |
| `createdBy`       | string    | Admin UID who created the tier        |
| `updatedBy`       | string    | Admin UID who last updated the tier   |
| `createdAt`       | timestamp | Tier creation date/time               |
| `updatedAt`       | timestamp | Last update date/time                 |

**`limits` map:**

| Field                      | Type    | Description                              |
| -------------------------- | ------- | ---------------------------------------- |
| `maxProducts`              | number  | Max products allowed (`null` = unlimited) |
| `maxServices`              | number  | Max services allowed (`null` = unlimited) |
| `maxCardPaymentsPerDay`    | number  | Daily card payment cap (`null` = unlimited) |
| `barcodeScannerEnabled`    | boolean | Whether barcode scanning is enabled      |
| `lowStockAlertsEnabled`    | boolean | Whether low-stock alerts are enabled     |
| `analyticsEnabled`         | boolean | Whether analytics / insights are enabled |
| `cashSalesEnabled`         | boolean | Whether cash sales are allowed           |
| `cardPaymentsEnabled`      | boolean | Whether card / digital payments are allowed |
| `expenseTrackingEnabled`   | boolean | Whether expense tracking is enabled      |

#### Demo Document: `subscriptionTiers/basic`

| Field             | Type      | Value                                    |
| ----------------- | --------- | ---------------------------------------- |
| `tierId`          | string    | `basic`                                  |
| `name`            | string    | `Basic`                                  |
| `code`            | string    | `basic`                                  |
| `price`           | number    | `0`                                      |
| `currency`        | string    | `ZAR`                                    |
| `billingPeriod`   | string    | `free`                                   |
| `setupFee`        | number    | `0`                                      |
| `description`     | string    | `Free starter plan for small traders.`   |
| `displayOrder`    | number    | `1`                                      |
| `isActive`        | boolean   | `true`                                   |
| `isRecommended`   | boolean   | `false`                                  |
| `features`        | array     | `Manual Input (No Barcode Scanner)`, `Cash Sales Only`, `10/20 Card Payments Daily`, `Total Sales Today`, `Best-Selling Item Only`, `Up to 50 Products`, `5 Services` |
| `createdBy`       | string    | `demo_admin`                             |
| `updatedBy`       | string    | `demo_admin`                             |
| `createdAt`       | timestamp | current date/time                        |
| `updatedAt`       | timestamp | current date/time                        |

**`limits` map:**

| Field                      | Type    | Value   |
| -------------------------- | ------- | ------- |
| `maxProducts`              | number  | `50`    |
| `maxServices`              | number  | `5`     |
| `maxCardPaymentsPerDay`    | number  | `20`    |
| `barcodeScannerEnabled`    | boolean | `false` |
| `lowStockAlertsEnabled`    | boolean | `false` |
| `analyticsEnabled`         | boolean | `false` |
| `cashSalesEnabled`         | boolean | `true`  |
| `cardPaymentsEnabled`      | boolean | `true`  |
| `expenseTrackingEnabled`   | boolean | `false` |

#### Demo Document: `subscriptionTiers/plus`

| Field             | Type      | Value                                                        |
| ----------------- | --------- | ------------------------------------------------------------ |
| `tierId`          | string    | `plus`                                                       |
| `name`            | string    | `Plus`                                                       |
| `code`            | string    | `plus`                                                       |
| `price`           | number    | `500`                                                        |
| `currency`        | string    | `ZAR`                                                        |
| `billingPeriod`   | string    | `monthly`                                                    |
| `setupFee`        | number    | `0`                                                          |
| `description`     | string    | `Growth plan for traders who need more sales and inventory tools.` |
| `displayOrder`    | number    | `2`                                                          |
| `isActive`        | boolean   | `true`                                                       |
| `isRecommended`   | boolean   | `true`                                                       |
| `features`        | array     | `Barcode Scanner Access`, `Low-stock Alerts`, `Cash Sales`, `150 Card Payments Daily`, `Net Profit + Analytics`, `Up to 100 Products`, `15 Services` |
| `createdBy`       | string    | `demo_admin`                                                 |
| `updatedBy`       | string    | `demo_admin`                                                 |
| `createdAt`       | timestamp | current date/time                                            |
| `updatedAt`       | timestamp | current date/time                                            |

**`limits` map:**

| Field                      | Type    | Value   |
| -------------------------- | ------- | ------- |
| `maxProducts`              | number  | `100`   |
| `maxServices`              | number  | `15`    |
| `maxCardPaymentsPerDay`    | number  | `150`   |
| `barcodeScannerEnabled`    | boolean | `true`  |
| `lowStockAlertsEnabled`    | boolean | `true`  |
| `analyticsEnabled`         | boolean | `true`  |
| `cashSalesEnabled`         | boolean | `true`  |
| `cardPaymentsEnabled`      | boolean | `true`  |
| `expenseTrackingEnabled`   | boolean | `false` |

#### Demo Document: `subscriptionTiers/premium`

| Field             | Type      | Value                                                            |
| ----------------- | --------- | ---------------------------------------------------------------- |
| `tierId`          | string    | `premium`                                                        |
| `name`            | string    | `Premium`                                                        |
| `code`            | string    | `premium`                                                        |
| `price`           | number    | `1000`                                                           |
| `currency`        | string    | `ZAR`                                                            |
| `billingPeriod`   | string    | `monthly`                                                        |
| `setupFee`        | number    | `0`                                                              |
| `description`     | string    | `Full access plan for businesses that need unlimited tools.`     |
| `displayOrder`    | number    | `3`                                                              |
| `isActive`        | boolean   | `true`                                                           |
| `isRecommended`   | boolean   | `false`                                                          |
| `features`        | array     | `Barcode Scanner Access`, `Unlimited Card Payments`, `Daily Breakdown of Products Sold`, `Full Insights`, `Unlimited Fixed Expenses`, `Unlimited Products and Services` |
| `createdBy`       | string    | `demo_admin`                                                     |
| `updatedBy`       | string    | `demo_admin`                                                     |
| `createdAt`       | timestamp | current date/time                                                |
| `updatedAt`       | timestamp | current date/time                                                |

**`limits` map:**

| Field                      | Type    | Value   |
| -------------------------- | ------- | ------- |
| `maxProducts`              | null    | `null`  |
| `maxServices`              | null    | `null`  |
| `maxCardPaymentsPerDay`    | null    | `null`  |
| `barcodeScannerEnabled`    | boolean | `true`  |
| `lowStockAlertsEnabled`    | boolean | `true`  |
| `analyticsEnabled`         | boolean | `true`  |
| `cashSalesEnabled`         | boolean | `true`  |
| `cardPaymentsEnabled`      | boolean | `true`  |
| `expenseTrackingEnabled`   | boolean | `true`  |

---

### 7. `subscriptions`

Stores active business subscriptions, linking each business to a subscription tier.

**Path:** `subscriptions/{subscriptionId}`

#### Document Schema

| Field               | Type       | Description                           |
| ------------------- | ---------- | ------------------------------------- |
| `subscriptionId`    | string     | Unique subscription identifier        |
| `businessId`        | string     | Reference to `businesses/{businessId}` |
| `tierId`            | string     | Reference to `subscriptionTiers/{tierId}` |
| `tierName`          | string     | Denormalized tier name                |
| `status`            | string     | `active`, `pending_payment`, `expired`, `cancelled` |
| `startedAt`         | timestamp  | Subscription start date/time          |
| `expiresAt`         | timestamp  | Subscription expiry (nullable)        |
| `nextBillingDate`   | timestamp  | Next billing date (nullable)          |
| `price`             | number     | Subscribed price                      |
| `currency`          | string     | e.g., `ZAR`                           |
| `billingPeriod`     | string     | `free`, `monthly`, `yearly`           |
| `createdAt`         | timestamp  | Subscription creation date/time       |
| `updatedAt`         | timestamp  | Last update date/time                 |

#### Demo Document: `subscriptions/demo_subscription`

| Field               | Type      | Value                  |
| ------------------- | --------- | ---------------------- |
| `subscriptionId`    | string    | `demo_subscription`    |
| `businessId`        | string    | `demo_business`        |
| `tierId`            | string    | `basic`                |
| `tierName`          | string    | `Basic`                |
| `status`            | string    | `active`               |
| `startedAt`         | timestamp | current date/time      |
| `expiresAt`         | null      | `null`                 |
| `nextBillingDate`   | null      | `null`                 |
| `price`             | number    | `0`                    |
| `currency`          | string    | `ZAR`                  |
| `billingPeriod`     | string    | `free`                 |
| `createdAt`         | timestamp | current date/time      |
| `updatedAt`         | timestamp | current date/time      |

---

## Business Subcollections

Subcollections live **inside** a `businesses/{businessId}` document. Firestore does not allow empty collections, so each subcollection needs at least one mock document for testing.

---

### `businesses/{businessId}/products`

Inventory items sold by the business.

#### Document Schema

| Field              | Type      | Description                           |
| ------------------ | --------- | ------------------------------------- |
| `productId`        | string    | Unique product identifier             |
| `businessId`       | string    | Parent business ID                    |
| `name`             | string    | Product name                          |
| `description`      | string    | Product description                   |
| `category`         | string    | Product category                      |
| `sku`              | string    | Stock keeping unit                    |
| `barcode`          | string    | Product barcode                       |
| `imageUrl`         | string    | Product image URL                     |
| `sellingPrice`     | number    | Selling price                         |
| `costPrice`        | number    | Cost price                            |
| `stockQuantity`    | number    | Current stock quantity                |
| `lowStockThreshold`| number    | Low stock alert threshold             |
| `unit`             | string    | Unit of measure (e.g., `item`)        |
| `isActive`         | boolean   | Whether product is active             |
| `isDeleted`        | boolean   | Soft-delete flag                      |
| `createdAt`        | timestamp | When product was added                |
| `updatedAt`        | timestamp | Last update date/time                 |

#### Demo Document: `businesses/demo_business/products/demo_product_bread`

| Field              | Type      | Value                 |
| ------------------ | --------- | --------------------- |
| `productId`        | string    | `demo_product_bread`  |
| `businessId`       | string    | `demo_business`       |
| `name`             | string    | `Bread`               |
| `description`      | string    | `White sliced bread`  |
| `category`         | string    | `Groceries`           |
| `sku`              | string    | `BRD-001`             |
| `barcode`          | string    | *(empty)*             |
| `imageUrl`         | string    | *(empty)*             |
| `sellingPrice`     | number    | `18`                  |
| `costPrice`        | number    | `14`                  |
| `stockQuantity`    | number    | `25`                  |
| `lowStockThreshold`| number    | `5`                   |
| `unit`             | string    | `item`                |
| `isActive`         | boolean   | `true`                |
| `isDeleted`        | boolean   | `false`               |
| `createdAt`        | timestamp | current date/time     |
| `updatedAt`        | timestamp | current date/time     |

---

### `businesses/{businessId}/services`

Services offered by the business (e.g., airtime, data).

#### Document Schema

| Field         | Type      | Description                           |
| ------------- | --------- | ------------------------------------- |
| `serviceId`   | string    | Unique service identifier             |
| `businessId`  | string    | Parent business ID                    |
| `name`        | string    | Service name                          |
| `description` | string    | Service description                   |
| `category`    | string    | Service category                      |
| `price`       | number    | Service price / fee                   |
| `costPrice`   | number    | Cost to provide service               |
| `imageUrl`    | string    | Service image URL                     |
| `isActive`    | boolean   | Whether service is enabled            |
| `isDeleted`   | boolean   | Soft-delete flag                      |
| `createdAt`   | timestamp | When service was added                |
| `updatedAt`   | timestamp | Last update date/time                 |

#### Demo Document: `businesses/demo_business/services/demo_service_airtime`

| Field         | Type      | Value                    |
| ------------- | --------- | ------------------------ |
| `serviceId`   | string    | `demo_service_airtime`   |
| `businessId`  | string    | `demo_business`          |
| `name`        | string    | `Airtime Sale`           |
| `description` | string    | `Mobile airtime service` |
| `category`    | string    | `Digital Services`       |
| `price`       | number    | `10`                     |
| `costPrice`   | number    | `9`                      |
| `imageUrl`    | string    | *(empty)*                |
| `isActive`    | boolean   | `true`                   |
| `isDeleted`   | boolean   | `false`                  |
| `createdAt`   | timestamp | current date/time        |
| `updatedAt`   | timestamp | current date/time        |

---

### `businesses/{businessId}/transactions`

Financial transactions (sales, refunds, etc.) for the business.

#### Document Schema

| Field             | Type      | Description                                     |
| ----------------- | --------- | ----------------------------------------------- |
| `transactionId`   | string    | Unique transaction identifier                   |
| `businessId`      | string    | Parent business ID                              |
| `customerId`      | string    | Customer reference (nullable)                   |
| `customerName`    | string    | Customer name                                   |
| `customerPhoneNumber` | string| Customer phone                                  |
| `customerEmail`   | string    | Customer email                                  |
| `type`            | string    | `sale`, `refund`, `expense`                     |
| `status`          | string    | `pending`, `completed`, `failed`, `cancelled`, `refunded` |
| `paymentMethod`   | string    | `cash`, `qr`, `card`, `eft`, `digital`          |
| `currency`        | string    | e.g., `ZAR`                                     |
| `subtotal`        | number    | Subtotal before tax/discount                    |
| `taxAmount`       | number    | Tax amount                                      |
| `discountAmount`  | number    | Discount amount                                 |
| `totalAmount`     | number    | Final total amount                              |
| `items`           | array     | Array of line-item maps (see below)             |
| `reference`       | string    | External or internal reference                  |
| `notes`           | string    | Transaction notes                               |
| `createdBy`       | string    | User ID who created the transaction             |
| `createdAt`       | timestamp | Transaction creation date/time                  |
| `updatedAt`       | timestamp | Last update date/time                           |
| `completedAt`     | timestamp | Completion date/time (nullable)                 |

**`items` array element map:**

| Field         | Type   |
| ------------- | ------ |
| `itemId`      | string |
| `itemType`    | string |
| `name`        | string |
| `quantity`    | number |
| `unitPrice`   | number |
| `totalPrice`  | number |

#### Demo Document: `businesses/demo_business/transactions/demo_transaction_001`

| Field             | Type      | Value                   |
| ----------------- | --------- | ----------------------- |
| `transactionId`   | string    | `demo_transaction_001`  |
| `businessId`      | string    | `demo_business`         |
| `type`            | string    | `sale`                  |
| `status`          | string    | `completed`             |
| `paymentMethod`   | string    | `cash`                  |
| `subtotal`        | number    | `30`                    |
| `taxAmount`       | number    | `0`                     |
| `discountAmount`  | number    | `0`                     |
| `totalAmount`     | number    | `30`                    |
| `currency`        | string    | `ZAR`                   |
| `createdBy`       | string    | `demo_user`             |
| `saleDate`        | timestamp | current date/time       |
| `createdAt`       | timestamp | current date/time       |
| `updatedAt`       | timestamp | current date/time       |

---

### `businesses/{businessId}/paymentRequests`

Payment links or QR payment requests generated for customers.

#### Document Schema

| Field                 | Type      | Description                           |
| --------------------- | --------- | ------------------------------------- |
| `paymentRequestId`    | string    | Unique payment request identifier     |
| `businessId`          | string    | Parent business ID                    |
| `transactionId`         | string    | Linked transaction ID (nullable)      |
| `customerName`          | string    | Customer name                         |
| `customerPhoneNumber`   | string    | Customer phone                        |
| `customerEmail`         | string    | Customer email                        |
| `amount`                | number    | Requested amount                      |
| `currency`              | string    | e.g., `ZAR`                           |
| `description`           | string    | Reason for the request                |
| `reference`             | string    | Reference code                        |
| `status`                | string    | `pending`, `paid`, `expired`, `cancelled` |
| `paymentUrl`            | string    | Payment link URL                      |
| `qrCodeUrl`             | string    | QR code image URL                     |
| `expiresAt`             | timestamp | Expiry date/time (nullable)           |
| `paidAt`                | timestamp | Payment date/time (nullable)          |
| `createdBy`             | string    | User ID who created the request       |
| `createdAt`             | timestamp | Request creation date/time            |
| `updatedAt`             | timestamp | Last update date/time                 |

#### Demo Document: `businesses/demo_business/paymentRequests/demo_payment_request_001`

| Field                 | Type      | Value                                      |
| --------------------- | --------- | ------------------------------------------ |
| `paymentRequestId`    | string    | `demo_payment_request_001`                 |
| `businessId`          | string    | `demo_business`                            |
| `amount`              | number    | `50`                                       |
| `currency`            | string    | `ZAR`                                      |
| `status`              | string    | `pending`                                  |
| `qrCodeData`          | string    | `awepay://pay?requestId=demo_payment_request_001` |
| `qrCodeImageUrl`      | string    | *(empty)*                                  |
| `customerId`          | string    | *(empty)*                                  |
| `customerPhoneNumber` | string    | *(empty)*                                  |
| `transactionId`       | string    | *(empty)*                                  |
| `createdBy`           | string    | `demo_user`                                |
| `createdAt`           | timestamp | current date/time                          |
| `updatedAt`           | timestamp | current date/time                          |

---

### `businesses/{businessId}/stockMovements`

Tracks inventory changes (restocking, sales, adjustments).

#### Document Schema

| Field              | Type      | Description                           |
| ------------------ | --------- | ------------------------------------- |
| `movementId`       | string    | Unique movement identifier            |
| `businessId`       | string    | Parent business ID                    |
| `productId`        | string    | Reference to product                  |
| `productName`      | string    | Product name                          |
| `type`             | string    | `stock_in`, `stock_out`, `sale`, `return`, `adjustment`, `damaged` |
| `quantity`         | number    | Amount changed                        |
| `previousQuantity` | number    | Quantity before movement              |
| `newQuantity`      | number    | Quantity after movement               |
| `reason`           | string    | Reason for movement                   |
| `referenceType`    | string    | `manual`, `transaction`, `purchase`, `adjustment` |
| `referenceId`      | string    | Linked reference ID (nullable)      |
| `createdBy`        | string    | User ID who created the movement      |
| `createdAt`        | timestamp | Movement date/time                    |

#### Demo Document: `businesses/demo_business/stockMovements/demo_stock_movement_001`

| Field              | Type      | Value                        |
| ------------------ | --------- | ---------------------------- |
| `movementId`       | string    | `demo_stock_movement_001`    |
| `businessId`       | string    | `demo_business`              |
| `productId`        | string    | `demo_product_bread`         |
| `productName`      | string    | `Bread`                      |
| `type`             | string    | `initial_stock`              |
| `quantity`         | number    | `25`                         |
| `previousQuantity` | number    | `0`                          |
| `newQuantity`      | number    | `25`                         |
| `reason`           | string    | `Initial demo stock`         |
| `transactionId`    | string    | *(empty)*                    |
| `createdBy`        | string    | `demo_user`                  |
| `createdAt`        | timestamp | current date/time            |

---

### `businesses/{businessId}/expenses`

Business operating expenses.

#### Document Schema

| Field           | Type      | Description                           |
| --------------- | --------- | ------------------------------------- |
| `expenseId`     | string    | Unique expense identifier             |
| `businessId`    | string    | Parent business ID                    |
| `name`          | string    | Expense name / title                  |
| `description`   | string    | Expense description                   |
| `category`      | string    | e.g., `rent`, `utilities`, `stock`    |
| `amount`        | number    | Expense amount                        |
| `currency`      | string    | e.g., `ZAR`                           |
| `type`          | string    | `fixed`, `variable`                   |
| `frequency`     | string    | `daily`, `weekly`, `monthly`, `yearly` |
| `isRecurring`   | boolean   | Whether the expense repeats           |
| `paymentMethod` | string    | `cash`, `card`, `eft`, `digital`      |
| `receiptUrl`    | string    | Receipt image URL                     |
| `createdBy`     | string    | User ID who created the expense       |
| `expenseDate`   | timestamp | Expense date                          |
| `createdAt`     | timestamp | Record creation date/time             |
| `updatedAt`     | timestamp | Last update date/time                 |

#### Demo Document: `businesses/demo_business/expenses/demo_expense_rent`

| Field           | Type      | Value                     |
| --------------- | --------- | ------------------------- |
| `expenseId`     | string    | `demo_expense_rent`       |
| `businessId`    | string    | `demo_business`           |
| `name`          | string    | `Rent`                    |
| `description`   | string    | `Monthly shop rental`     |
| `category`      | string    | `rent`                    |
| `amount`        | number    | `2500`                    |
| `currency`      | string    | `ZAR`                     |
| `type`          | string    | `fixed`                   |
| `frequency`     | string    | `monthly`                 |
| `isRecurring`   | boolean   | `true`                    |
| `createdBy`     | string    | `demo_user`               |
| `expenseDate`   | timestamp | current date/time         |
| `createdAt`     | timestamp | current date/time         |
| `updatedAt`     | timestamp | current date/time         |

---

### `businesses/{businessId}/salesSummaries`

Aggregated daily/weekly/monthly/yearly sales data.

#### Document Schema

| Field                | Type      | Description                           |
| -------------------- | --------- | ------------------------------------- |
| `summaryId`          | string    | Unique summary identifier             |
| `businessId`         | string    | Parent business ID                    |
| `periodType`         | string    | `daily`, `weekly`, `monthly`, `yearly`|
| `date`               | string    | ISO date string (e.g., `2026-06-07`)  |
| `year`               | number    | Summary year                          |
| `month`              | number    | Summary month (1-12)                  |
| `day`                | number    | Summary day (1-31)                    |
| `periodStart`        | timestamp | Summary period start                  |
| `periodEnd`          | timestamp | Summary period end                    |
| `totalSales`         | number    | Total sales amount                    |
| `totalTransactions`  | number    | Total transaction count               |
| `totalCashSales`     | number    | Total cash sales amount               |
| `totalDigitalSales`  | number    | Total digital sales amount            |
| `totalRefunds`       | number    | Total refunds amount                  |
| `totalExpenses`      | number    | Total expenses amount                 |
| `netRevenue`         | number    | Net revenue                           |
| `totals`             | map       | Quick totals map (see below)          |
| `topProducts`        | array     | Array of top-selling product maps     |
| `topServices`        | array     | Array of top-selling service maps     |
| `createdAt`          | timestamp | Summary creation date/time            |
| `updatedAt`          | timestamp | Last update date/time                 |

**`totals` map:**

| Field                        | Type   |
| ---------------------------- | ------ |
| `grossSales`                 | number |
| `netSales`                   | number |
| `cashSales`                  | number |
| `digitalSales`               | number |
| `refunds`                    | number |
| `expenses`                   | number |
| `netProfit`                  | number |
| `transactionCount`           | number |
| `cashTransactionCount`       | number |
| `digitalTransactionCount`    | number |
| `productsSoldCount`          | number |
| `servicesSoldCount`          | number |

**`topProducts` / `topServices` array element map:**

| Field          | Type   |
| -------------- | ------ |
| `productId`    | string |
| `serviceId`    | string |
| `name`         | string |
| `quantitySold` | number |
| `totalAmount`  | number |

#### Demo Document: `businesses/demo_business/salesSummaries/daily_2026_06_07`

| Field           | Type      | Value                 |
| --------------- | --------- | --------------------- |
| `summaryId`     | string    | `daily_2026_06_07`    |
| `businessId`    | string    | `demo_business`       |
| `periodType`    | string    | `daily`               |
| `date`          | string    | `2026-06-07`          |
| `year`          | number    | `2026`                |
| `month`         | number    | `6`                   |
| `day`           | number    | `7`                   |
| `updatedAt`     | timestamp | current date/time     |

---

### `businesses/{businessId}/bankAccounts`

Linked bank accounts for payouts and settlements.

#### Document Schema

| Field                    | Type      | Description                           |
| ------------------------ | --------- | ------------------------------------- |
| `bankAccountId`          | string    | Unique bank account identifier        |
| `businessId`             | string    | Parent business ID                    |
| `accountHolderName`      | string    | Name on the account                   |
| `bankName`               | string    | Name of the bank                      |
| `accountNumberLast4`     | string    | Last 4 digits of account number       |
| `accountNumberEncrypted` | string    | Encrypted full account number         |
| `branchName`             | string    | Branch name                           |
| `branchCode`             | string    | Bank branch code                      |
| `accountType`            | string    | `current`, `savings`, `business_cheque` |
| `verificationStatus`     | string    | `pending`, `verified`, `rejected`     |
| `isPrimary`              | boolean   | Whether this is the default account   |
| `status`                 | string    | `active`, `pending`, `removed`        |
| `createdAt`              | timestamp | Linking date/time                     |
| `updatedAt`              | timestamp | Last update date/time                 |
| `verifiedAt`             | timestamp | Verification date/time (nullable)     |
| `verifiedBy`             | string    | Admin who verified (nullable)         |

#### Demo Document: `businesses/demo_business/bankAccounts/demo_bank_account`

| Field                    | Type      | Value                  |
| ------------------------ | --------- | ---------------------- |
| `bankAccountId`          | string    | `demo_bank_account`    |
| `businessId`             | string    | `demo_business`        |
| `accountHolderName`      | string    | `Demo Spaza Shop`      |
| `bankName`               | string    | `Capitec`              |
| `accountNumberLast4`     | string    | `1234`                 |
| `accountNumberEncrypted` | string    | *(empty)*              |
| `branchCode`             | string    | `470010`               |
| `accountType`            | string    | `business_cheque`      |
| `verificationStatus`     | string    | `pending`              |
| `isPrimary`              | boolean   | `true`                 |
| `createdAt`              | timestamp | current date/time      |
| `updatedAt`              | timestamp | current date/time      |

---

## Visual Overview

```
Firestore Database
├── users
│   └── demo_user
├── adminUsers
│   └── demo_admin
├── businesses
│   └── demo_business
│       ├── subscription
│       │   └── tierId: basic
│       ├── products
│       │   └── demo_product_bread
│       ├── services
│       │   └── demo_service_airtime
│       ├── transactions
│       │   └── demo_transaction_001
│       ├── paymentRequests
│       │   └── demo_payment_request_001
│       ├── stockMovements
│       │   └── demo_stock_movement_001
│       ├── expenses
│       │   └── demo_expense_rent
│       ├── salesSummaries
│       │   └── daily_2026_06_07
│       └── bankAccounts
│           └── demo_bank_account
├── auditLogs
│   └── demo_log
├── platformSettings
│   └── payment_config
├── subscriptionTiers
│   ├── basic
│   ├── plus
│   └── premium
└── subscriptions
    └── demo_subscription
```

---

## Demo Data Summary

| Collection / Document                                           | ID / Purpose                        |
| ---------------------------------------------------------------- | ----------------------------------- |
| `users/demo_user`                                               | Demo business owner account         |
| `adminUsers/demo_admin`                                         | Demo platform administrator         |
| `businesses/demo_business`                                      | Demo spaza shop profile             |
| `auditLogs/demo_log`                                            | Demo audit trail entry              |
| `platformSettings/payment_config`                               | Global payment configuration        |
| `businesses/demo_business/products/demo_product_bread`            | Demo product                        |
| `businesses/demo_business/services/demo_service_airtime`        | Demo service                        |
| `businesses/demo_business/transactions/demo_transaction_001`    | Demo sale transaction               |
| `businesses/demo_business/paymentRequests/demo_payment_request_001` | Demo payment request            |
| `businesses/demo_business/stockMovements/demo_stock_movement_001` | Demo stock movement               |
| `businesses/demo_business/expenses/demo_expense_rent`           | Demo expense                        |
| `businesses/demo_business/salesSummaries/daily_2026_06_07`    | Demo daily summary                  |
| `businesses/demo_business/bankAccounts/demo_bank_account`       | Demo bank account                   |
| `subscriptionTiers/basic`                                       | Basic subscription tier             |
| `subscriptionTiers/plus`                                      | Plus subscription tier              |
| `subscriptionTiers/premium`                                     | Premium subscription tier           |
| `subscriptions/demo_subscription`                             | Demo business subscription          |

---

## Seeding the Database

Use the Node.js seeder script (`seed_firestore.js`) to programmatically populate collections:

```bash
node seed_firestore.js
```

Ensure `firebase-admin` is installed and your service account key JSON is in place.

---

## Important Relationships

### Business Owner Relationship

```
Firebase Auth user
    ↓ uid
users/{uid}
    ↓ businessId
businesses/{businessId}
```

### Admin Relationship

```
Firebase Auth admin user
    ↓ uid
adminUsers/{uid}
```

### Business Inventory Relationship

```
businesses/{businessId}
    ├── products/{productId}
    └── services/{serviceId}
```

### Business Sales Relationship

```
businesses/{businessId}
    ├── transactions/{transactionId}
    ├── paymentRequests/{paymentRequestId}
    ├── stockMovements/{stockMovementId}
    ├── expenses/{expenseId}
    └── salesSummaries/{summaryId}
```

### Subscription Relationship

```
businesses/{businessId}
    ↓ subscriptionId
subscriptions/{subscriptionId}
    ↓ tierId
subscriptionTiers/{tierId}
```

---

## Notes

- **Top-level collections** (`users`, `adminUsers`, `businesses`, `auditLogs`, `platformSettings`, `subscriptionTiers`, `subscriptions`) must be created directly under the Firestore root.
- **Subcollections** (`products`, `services`, `transactions`, etc.) are created inside a `businesses/{businessId}` document.
- Firestore does **not** allow empty collections. When creating a subcollection manually, add at least one mock document.
- All `createdAt` and `updatedAt` fields should use Firestore `timestamp` types.
- Document IDs should be meaningful (e.g., `demo_user`) rather than auto-generated where human-readability is preferred.
- Use `demo_business` as the business document ID when creating subcollections, not a placeholder like `businessId`.
