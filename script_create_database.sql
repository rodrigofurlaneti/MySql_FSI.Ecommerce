-- ==========================================================
-- DATABASE & BASIC CONFIG
-- ==========================================================
CREATE DATABASE IF NOT EXISTS fsiecommercedb
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE fsiecommercedb;

-- ==========================================================
-- TABLE: roles (OWNER, ADMIN, BUYER, VIEWER)
-- ==========================================================
DROP TABLE IF EXISTS roles;

CREATE TABLE roles (
    id              TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    code            VARCHAR(50) NOT NULL UNIQUE, -- 'OWNER', 'ADMIN', 'BUYER', 'VIEWER'
    name            VARCHAR(100) NOT NULL,
    description     VARCHAR(255) NULL,
    PRIMARY KEY (id)
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: users (global identity for login)
-- ==========================================================
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: accounts (PF / PJ)
-- ==========================================================
DROP TABLE IF EXISTS accounts;

CREATE TABLE accounts (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    account_type    ENUM('INDIVIDUAL', 'BUSINESS') NOT NULL,
    display_name    VARCHAR(150) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    phone_number    VARCHAR(50)  NULL,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY ux_accounts_email (email)
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: individual_profiles (1:1 with accounts when INDIVIDUAL)
-- ==========================================================
DROP TABLE IF EXISTS individual_profiles;

CREATE TABLE individual_profiles (
    account_id      BIGINT UNSIGNED NOT NULL,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    national_id     VARCHAR(50)  NOT NULL,  -- CPF, SSN etc.
    PRIMARY KEY (account_id),
    CONSTRAINT fk_individual_profiles_account
        FOREIGN KEY (account_id) REFERENCES accounts(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: business_profiles (1:1 with accounts when BUSINESS)
-- ==========================================================
DROP TABLE IF EXISTS business_profiles;

CREATE TABLE business_profiles (
    account_id          BIGINT UNSIGNED NOT NULL,
    company_name        VARCHAR(200) NOT NULL,
    trade_name          VARCHAR(200) NULL,
    tax_id              VARCHAR(50)  NOT NULL, -- CNPJ, VAT etc.
    state_registration  VARCHAR(50)  NULL,
    PRIMARY KEY (account_id),
    CONSTRAINT fk_business_profiles_account
        FOREIGN KEY (account_id) REFERENCES accounts(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: account_users (multi-user per account + role)
-- ==========================================================
DROP TABLE IF EXISTS account_users;

CREATE TABLE account_users (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    account_id          BIGINT UNSIGNED NOT NULL,
    user_id             BIGINT UNSIGNED NOT NULL,
    role_id             TINYINT UNSIGNED NOT NULL,
    is_default_account  TINYINT(1) NOT NULL DEFAULT 0,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY ux_account_users_account_user (account_id, user_id),
    CONSTRAINT fk_account_users_account
        FOREIGN KEY (account_id) REFERENCES accounts(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_account_users_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_account_users_role
        FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: account_addresses
-- ==========================================================
DROP TABLE IF EXISTS account_addresses;

CREATE TABLE account_addresses (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    account_id          BIGINT UNSIGNED NOT NULL,
    label               VARCHAR(100) NOT NULL, -- 'Home', 'Headquarters', 'Billing'
    line1               VARCHAR(255) NOT NULL,
    line2               VARCHAR(255) NULL,
    city                VARCHAR(150) NOT NULL,
    state               VARCHAR(150) NOT NULL,
    postal_code         VARCHAR(20)  NOT NULL,
    country_code        CHAR(2)      NOT NULL, -- ISO 3166-1 alpha-2
    is_default_shipping TINYINT(1)   NOT NULL DEFAULT 0,
    is_default_billing  TINYINT(1)   NOT NULL DEFAULT 0,
    created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_account_addresses_account
        FOREIGN KEY (account_id) REFERENCES accounts(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: product_categories
-- ==========================================================
DROP TABLE IF EXISTS product_categories;

CREATE TABLE product_categories (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name            VARCHAR(150) NOT NULL,
    slug            VARCHAR(150) NOT NULL UNIQUE,
    parent_id       BIGINT UNSIGNED NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_product_categories_parent
        FOREIGN KEY (parent_id) REFERENCES product_categories(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: products
-- ==========================================================
DROP TABLE IF EXISTS products;

CREATE TABLE products (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_id     BIGINT UNSIGNED NULL,
    sku             VARCHAR(64) NOT NULL UNIQUE,
    name            VARCHAR(255) NOT NULL,
    description     TEXT NULL,
    price           DECIMAL(10,2) NOT NULL,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    stock_quantity  INT NOT NULL DEFAULT 0,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES product_categories(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: carts (for registered and guest users)
-- ==========================================================
DROP TABLE IF EXISTS carts;

CREATE TABLE carts (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    account_id      BIGINT UNSIGNED NULL,
    guest_token     VARCHAR(64) NULL UNIQUE,  -- identify guest cart via cookie/token
    status          ENUM('OPEN', 'CONVERTED', 'ABANDONED') NOT NULL DEFAULT 'OPEN',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_carts_account
        FOREIGN KEY (account_id) REFERENCES accounts(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
    -- Business rule (conceitual):
    -- Either account_id IS NOT NULL OR guest_token IS NOT NULL.
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: cart_items
-- ==========================================================
DROP TABLE IF EXISTS cart_items;

CREATE TABLE cart_items (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    cart_id         BIGINT UNSIGNED NOT NULL,
    product_id      BIGINT UNSIGNED NOT NULL,
    quantity        INT NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL, -- price at the moment (can change later in catalog)
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY ux_cart_items_cart_product (cart_id, product_id),
    CONSTRAINT fk_cart_items_cart
        FOREIGN KEY (cart_id) REFERENCES carts(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_cart_items_product
        FOREIGN KEY (product_id) REFERENCES products(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: orders (snapshot of addresses to evitar join pesado)
-- ==========================================================
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_number            VARCHAR(50) NOT NULL UNIQUE, -- ex: ORD-2025-000001
    account_id              BIGINT UNSIGNED NOT NULL,
    placed_by_user_id       BIGINT UNSIGNED NULL,
    cart_id                 BIGINT UNSIGNED NULL,

    status                  ENUM('PENDING', 'PAID', 'SHIPPED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    total_amount            DECIMAL(10,2) NOT NULL,
    currency                CHAR(3) NOT NULL DEFAULT 'USD',

    -- Shipping address snapshot
    shipping_name           VARCHAR(200) NOT NULL,
    shipping_line1          VARCHAR(255) NOT NULL,
    shipping_line2          VARCHAR(255) NULL,
    shipping_city           VARCHAR(150) NOT NULL,
    shipping_state          VARCHAR(150) NOT NULL,
    shipping_postal_code    VARCHAR(20)  NOT NULL,
    shipping_country_code   CHAR(2)      NOT NULL,

    -- Billing address snapshot
    billing_name            VARCHAR(200) NOT NULL,
    billing_line1           VARCHAR(255) NOT NULL,
    billing_line2           VARCHAR(255) NULL,
    billing_city            VARCHAR(150) NOT NULL,
    billing_state           VARCHAR(150) NOT NULL,
    billing_postal_code     VARCHAR(20)  NOT NULL,
    billing_country_code    CHAR(2)      NOT NULL,

    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    CONSTRAINT fk_orders_account
        FOREIGN KEY (account_id) REFERENCES accounts(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_orders_placed_by_user
        FOREIGN KEY (placed_by_user_id) REFERENCES users(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_orders_cart
        FOREIGN KEY (cart_id) REFERENCES carts(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: order_items (snapshot of product and price)
-- ==========================================================
DROP TABLE IF EXISTS order_items;

CREATE TABLE order_items (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_id        BIGINT UNSIGNED NOT NULL,
    product_id      BIGINT UNSIGNED NOT NULL,
    product_name    VARCHAR(255) NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    quantity        INT NOT NULL,
    line_total      DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES products(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ==========================================================
-- TABLE: payment_transactions
-- ==========================================================
DROP TABLE IF EXISTS payment_transactions;

CREATE TABLE payment_transactions (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_id                BIGINT UNSIGNED NOT NULL,
    method                  ENUM('CREDIT_CARD', 'PIX', 'BOLETO', 'PAYPAL', 'OTHER') NOT NULL,
    status                  ENUM('PENDING', 'AUTHORIZED', 'CAPTURED', 'FAILED', 'CANCELLED', 'REFUNDED')
                            NOT NULL DEFAULT 'PENDING',
    amount                  DECIMAL(10,2) NOT NULL,
    currency                CHAR(3) NOT NULL DEFAULT 'USD',
    provider_transaction_id VARCHAR(100) NULL,
    created_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_payment_transactions_order
        FOREIGN KEY (order_id) REFERENCES orders(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- ==========================================================
-- SEED DATA (roles, users, accounts, etc.)
-- ==========================================================

-- ROLES
INSERT INTO roles (id, code, name, description) VALUES
    (1, 'OWNER',  'Owner',  'Full access to manage the account'),
    (2, 'ADMIN',  'Admin',  'Manage settings and orders'),
    (3, 'BUYER',  'Buyer',  'Can place orders'),
    (4, 'VIEWER', 'Viewer', 'Can only view products and orders');

-- USERS
INSERT INTO users (id, email, password_hash, is_active) VALUES
    (1, 'john.doe@example.com',   'HASHED_PASSWORD_1', 1),
    (2, 'maria.buyer@example.com','HASHED_PASSWORD_2', 1),
    (3, 'employee@acme.com',      'HASHED_PASSWORD_3', 1);

-- ACCOUNTS (1 individual, 1 business)
INSERT INTO accounts (id, account_type, display_name, email, phone_number) VALUES
    (1, 'INDIVIDUAL', 'John Doe', 'john.doe@example.com', '+1-555-0001'),
    (2, 'BUSINESS',   'ACME Inc.', 'contact@acme.com', '+1-555-1000');

-- INDIVIDUAL PROFILE
INSERT INTO individual_profiles (account_id, first_name, last_name, national_id) VALUES
    (1, 'John', 'Doe', '123-45-6789');

-- BUSINESS PROFILE
INSERT INTO business_profiles (account_id, company_name, trade_name, tax_id, state_registration) VALUES
    (2, 'ACME Incorporated', 'ACME', '12.345.678/0001-99', 'ISENTO');

-- ACCOUNT_USERS
-- John Doe -> owner of his individual account
INSERT INTO account_users (id, account_id, user_id, role_id, is_default_account) VALUES
    (1, 1, 1, 1, 1);  -- OWNER

-- Maria (buyer) associada à conta da ACME
INSERT INTO account_users (id, account_id, user_id, role_id, is_default_account) VALUES
    (2, 2, 2, 3, 1);  -- BUYER

-- Employee da ACME como ADMIN
INSERT INTO account_users (id, account_id, user_id, role_id, is_default_account) VALUES
    (3, 2, 3, 2, 1);  -- ADMIN

-- ACCOUNT_ADDRESSES
INSERT INTO account_addresses
(id, account_id, label, line1, line2, city, state, postal_code, country_code,
 is_default_shipping, is_default_billing)
VALUES
    (1, 1, 'Home', '123 Main St', NULL, 'New York', 'NY', '10001', 'US', 1, 1),
    (2, 2, 'Headquarters', '999 Industrial Ave', 'Suite 500', 'Los Angeles', 'CA', '90001', 'US', 1, 1);

-- PRODUCT_CATEGORIES
INSERT INTO product_categories (id, name, slug, parent_id) VALUES
    (1, 'Electronics', 'electronics', NULL),
    (2, 'Books',       'books',       NULL);

-- PRODUCTS
INSERT INTO products (id, category_id, sku, name, description, price, currency, stock_quantity, is_active) VALUES
    (1, 1, 'ELEC-001', 'Smartphone X', 'High-end smartphone with OLED display', 799.90, 'USD', 100, 1),
    (2, 1, 'ELEC-002', 'Wireless Headphones', 'Noise cancelling headphones',     199.90, 'USD', 200, 1),
    (3, 2, 'BOOK-001', 'Clean Architecture', 'Book by Robert C. Martin',         49.90,  'USD',  50, 1);

-- CARTS
-- Cart for registered user (John Doe, Account 1)
INSERT INTO carts (id, account_id, guest_token, status) VALUES
    (1, 1, NULL, 'OPEN');

-- Cart for a guest user (no account, identified by guest token)
INSERT INTO carts (id, account_id, guest_token, status) VALUES
    (2, NULL, 'GUEST-ABC123', 'OPEN');

-- CART_ITEMS
-- John Doe cart: Smartphone + Book
INSERT INTO cart_items (id, cart_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 1, 799.90),  -- Smartphone X
    (2, 1, 3, 2,  49.90);  -- 2x Clean Architecture

-- Guest cart: 1x Headphones
INSERT INTO cart_items (id, cart_id, product_id, quantity, unit_price) VALUES
    (3, 2, 2, 1, 199.90); -- Wireless Headphones

-- Vamos supor que o carrinho do John foi convertido em pedido
-- Primeiro, alteramos o status do cart para CONVERTED (se quiser simular)
UPDATE carts SET status = 'CONVERTED' WHERE id = 1;

-- ORDERS
-- Order from John's account, placed by John (user_id = 1) using cart_id = 1
INSERT INTO orders (
    id, order_number, account_id, placed_by_user_id, cart_id,
    status, total_amount, currency,
    shipping_name, shipping_line1, shipping_line2, shipping_city,
    shipping_state, shipping_postal_code, shipping_country_code,
    billing_name, billing_line1, billing_line2, billing_city,
    billing_state, billing_postal_code, billing_country_code
)
VALUES (
    1, 'ORD-2025-000001', 1, 1, 1,
    'PAID', 899.70, 'USD',
    'John Doe', '123 Main St', NULL, 'New York',
    'NY', '10001', 'US',
    'John Doe', '123 Main St', NULL, 'New York',
    'NY', '10001', 'US'
);

-- ORDER_ITEMS (snapshot)
-- 1x Smartphone X (799.90) + 2x Clean Architecture (2 * 49.90 = 99.80)
INSERT INTO order_items (id, order_id, product_id, product_name, unit_price, quantity, line_total) VALUES
    (1, 1, 1, 'Smartphone X',     799.90, 1, 799.90),
    (2, 1, 3, 'Clean Architecture', 49.90, 2,  99.80);

-- PAYMENT_TRANSACTIONS
INSERT INTO payment_transactions
(id, order_id, method, status, amount, currency, provider_transaction_id)
VALUES
    (1, 1, 'CREDIT_CARD', 'CAPTURED', 899.70, 'USD', 'PAYPROV-TRX-0001');
