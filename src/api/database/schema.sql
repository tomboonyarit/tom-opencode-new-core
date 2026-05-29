-- ============================================================================
-- POS ระบบร้านค้าปลีก-ค่าส่ง (Retail & Wholesale POS System)
-- Database Schema for PostgreSQL
-- ============================================================================

-- ============================================================================
-- 1. ระบบพนักงาน (Employee System)
-- ============================================================================

CREATE TABLE roles (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(50) NOT NULL UNIQUE,  -- admin, manager, cashier, warehouse
    description     TEXT,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE employees (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(20) NOT NULL UNIQUE,   -- รหัสพนักงาน
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    phone           VARCHAR(20),
    email           VARCHAR(100) UNIQUE,
    address         TEXT,
    role_id         INTEGER REFERENCES roles(id),
    username        VARCHAR(50) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 2. ระบบสมาชิก (Membership System)
-- ============================================================================

CREATE TABLE member_types (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(50) NOT NULL UNIQUE,  -- retail, wholesale, vip
    description     TEXT,
    discount_rate   DECIMAL(5,2) DEFAULT 0,       -- % ส่วนลด
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE members (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(20) NOT NULL UNIQUE,   -- รหัสสมาชิก
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100),
    phone           VARCHAR(20) NOT NULL,
    email           VARCHAR(100),
    address         TEXT,
    member_type_id  INTEGER REFERENCES member_types(id),
    credit_limit    DECIMAL(12,2) DEFAULT 0,       -- วงเงินเชื่อ
    current_balance DECIMAL(12,2) DEFAULT 0,       -- ยอดลูกหนี้ปัจจุบัน
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_members_phone ON members(phone);

-- ============================================================================
-- 3. ระบบสินค้า (Product System)
-- ============================================================================

CREATE TABLE categories (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    parent_id       INTEGER REFERENCES categories(id),
    description     TEXT,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE brands (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE units (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(50) NOT NULL UNIQUE,   -- ชิ้น, กล่อง, โหล, กิโล, ลิตร
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE TABLE products (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(50) NOT NULL UNIQUE,   -- barcode / รหัสสินค้า
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    category_id     INTEGER REFERENCES categories(id),
    brand_id        INTEGER REFERENCES brands(id),
    unit_id         INTEGER REFERENCES units(id),
    cost_price      DECIMAL(12,2) NOT NULL DEFAULT 0,     -- ต้นทุน
    retail_price    DECIMAL(12,2) NOT NULL DEFAULT 0,     -- ราคาปลีก
    wholesale_price DECIMAL(12,2) NOT NULL DEFAULT 0,     -- ราคาส่ง
    stock_quantity  DECIMAL(12,2) NOT NULL DEFAULT 0,     -- สต๊อกปัจจุบัน
    min_stock       DECIMAL(12,2) DEFAULT 0,              -- สต๊อกขั้นต่ำ
    max_stock       DECIMAL(12,2) DEFAULT 0,              -- สต๊อกสูงสุด
    is_active       BOOLEAN DEFAULT TRUE,
    image_url       TEXT,
    barcode         VARCHAR(100),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_products_code ON products(code);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category ON products(category_id);

-- ============================================================================
-- 4. ระบบการขาย (Sales System)
-- ============================================================================

CREATE TABLE payment_methods (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(50) NOT NULL UNIQUE,  -- cash, credit_card, bank_transfer, credit
    is_active       BOOLEAN DEFAULT TRUE
);

CREATE TABLE sales (
    id              SERIAL PRIMARY KEY,
    sale_code       VARCHAR(20) NOT NULL UNIQUE,   -- เลขที่บิล (PS20260529001)
    sale_date       TIMESTAMP NOT NULL DEFAULT NOW(),
    member_id       INTEGER REFERENCES members(id),
    employee_id     INTEGER REFERENCES employees(id),
    subtotal        DECIMAL(12,2) NOT NULL DEFAULT 0,    -- ยอดรวมก่อนส่วนลด
    discount        DECIMAL(12,2) DEFAULT 0,              -- ส่วนลด
    tax_amount      DECIMAL(12,2) DEFAULT 0,              -- ภาษี
    net_amount      DECIMAL(12,2) NOT NULL DEFAULT 0,     -- ยอดสุทธิ
    payment_method_id INTEGER REFERENCES payment_methods(id),
    payment_status  VARCHAR(20) DEFAULT 'paid',           -- paid, credit, partial
    notes           TEXT,
    is_void         BOOLEAN DEFAULT FALSE,                -- ยกเลิกบิล
    void_reason     TEXT,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_member ON sales(member_id);
CREATE INDEX idx_sales_employee ON sales(employee_id);

CREATE TABLE sale_items (
    id              SERIAL PRIMARY KEY,
    sale_id         INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_id      INTEGER NOT NULL REFERENCES products(id),
    quantity        DECIMAL(12,2) NOT NULL DEFAULT 1,
    unit_price      DECIMAL(12,2) NOT NULL,               -- ราคาที่ขายจริง
    cost_price      DECIMAL(12,2) DEFAULT 0,               -- ต้นทุนตอนขาย
    discount        DECIMAL(12,2) DEFAULT 0,
    total_price     DECIMAL(12,2) NOT NULL,               -- (unit_price * quantity) - discount
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);

-- ============================================================================
-- 5. ระบบลูกหนี้ (Accounts Receivable)
-- ============================================================================

CREATE TABLE credit_sales (
    id              SERIAL PRIMARY KEY,
    sale_id         INTEGER NOT NULL REFERENCES sales(id),
    member_id       INTEGER NOT NULL REFERENCES members(id),
    due_date        DATE,                                   -- กำหนดชำระ
    total_amount    DECIMAL(12,2) NOT NULL,                 -- ยอดรวม
    paid_amount     DECIMAL(12,2) DEFAULT 0,                -- ยอดที่ชำระแล้ว
    remaining_amount DECIMAL(12,2) NOT NULL,                -- ยอดคงค้าง
    status          VARCHAR(20) DEFAULT 'pending',           -- pending, partial, paid, overdue
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_credit_sales_member ON credit_sales(member_id);
CREATE INDEX idx_credit_sales_status ON credit_sales(status);

CREATE TABLE credit_payments (
    id              SERIAL PRIMARY KEY,
    credit_sale_id  INTEGER NOT NULL REFERENCES credit_sales(id) ON DELETE CASCADE,
    payment_date    TIMESTAMP NOT NULL DEFAULT NOW(),
    amount          DECIMAL(12,2) NOT NULL,                 -- จำนวนเงินที่ชำระ
    payment_method_id INTEGER REFERENCES payment_methods(id),
    notes           TEXT,
    employee_id     INTEGER REFERENCES employees(id),
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_credit_payments_credit ON credit_payments(credit_sale_id);

-- ============================================================================
-- 6. ระบบสต๊อก (Inventory System)
-- ============================================================================

CREATE TABLE suppliers (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(20) NOT NULL UNIQUE,
    company_name    VARCHAR(200) NOT NULL,
    contact_person  VARCHAR(100),
    phone           VARCHAR(20) NOT NULL,
    email           VARCHAR(100),
    address         TEXT,
    tax_id          VARCHAR(20),                            -- เลขที่ผู้เสียภาษี
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ใบสั่งซื้อสินค้า
CREATE TABLE purchase_orders (
    id              SERIAL PRIMARY KEY,
    po_code         VARCHAR(20) NOT NULL UNIQUE,             -- เลขที่ใบสั่งซื้อ (PO20260529001)
    supplier_id     INTEGER NOT NULL REFERENCES suppliers(id),
    employee_id     INTEGER NOT NULL REFERENCES employees(id), -- ผู้สั่ง
    order_date      DATE NOT NULL,
    expected_date   DATE,                                    -- วันที่คาดว่าจะได้รับ
    received_date   DATE,                                    -- วันที่รับจริง
    subtotal        DECIMAL(12,2) DEFAULT 0,
    discount        DECIMAL(12,2) DEFAULT 0,
    net_amount      DECIMAL(12,2) DEFAULT 0,
    status          VARCHAR(20) DEFAULT 'pending',            -- pending, partial, received, cancelled
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_po_supplier ON purchase_orders(supplier_id);

CREATE TABLE purchase_order_items (
    id              SERIAL PRIMARY KEY,
    purchase_order_id INTEGER NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id      INTEGER NOT NULL REFERENCES products(id),
    quantity_ordered DECIMAL(12,2) NOT NULL,
    quantity_received DECIMAL(12,2) DEFAULT 0,
    unit_cost       DECIMAL(12,2) NOT NULL,                  -- ราคาต่อหน่วยตอนสั่ง
    total_cost      DECIMAL(12,2) NOT NULL,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- การเคลื่อนไหวสต๊อก (Stock Transactions)
CREATE TABLE stock_transactions (
    id              SERIAL PRIMARY KEY,
    product_id      INTEGER NOT NULL REFERENCES products(id),
    transaction_type VARCHAR(20) NOT NULL,                   -- in, out, adjustment
    reference_type  VARCHAR(30) NOT NULL,                    -- purchase, sale, adjustment, api_import
    reference_id    INTEGER,                                 -- polymorphic ref
    quantity        DECIMAL(12,2) NOT NULL,                  -- + = เข้า, - = ออก
    unit_cost       DECIMAL(12,2) DEFAULT 0,
    total_cost      DECIMAL(12,2) DEFAULT 0,
    balance_before  DECIMAL(12,2) DEFAULT 0,                -- ยอดก่อน
    balance_after   DECIMAL(12,2) DEFAULT 0,                -- ยอดหลัง
    notes           TEXT,
    employee_id     INTEGER REFERENCES employees(id),
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_stock_product ON stock_transactions(product_id);
CREATE INDEX idx_stock_date ON stock_transactions(created_at);
CREATE INDEX idx_stock_reference ON stock_transactions(reference_type, reference_id);

-- การปรับสต๊อก (Stock Adjustments)
CREATE TABLE stock_adjustments (
    id              SERIAL PRIMARY KEY,
    product_id      INTEGER NOT NULL REFERENCES products(id),
    adjustment_type VARCHAR(20) NOT NULL,                    -- increase, decrease
    quantity        DECIMAL(12,2) NOT NULL,
    reason          VARCHAR(50) NOT NULL,                    -- damage, loss, found, correction
    notes           TEXT,
    employee_id     INTEGER REFERENCES employees(id),
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- 7. ระบบพิมพ์บิล (Print Bill)
-- ============================================================================

CREATE TABLE print_logs (
    id              SERIAL PRIMARY KEY,
    reference_type  VARCHAR(30) NOT NULL,                    -- sale, credit, purchase
    reference_id    INTEGER NOT NULL,
    printed_at      TIMESTAMP DEFAULT NOW(),
    employee_id     INTEGER REFERENCES employees(id),
    print_count     INTEGER DEFAULT 1
);

-- ============================================================================
-- 8. ระบบตั้งค่าระบบ (System Settings)
-- ============================================================================

CREATE TABLE system_settings (
    id              SERIAL PRIMARY KEY,
    setting_key     VARCHAR(100) NOT NULL UNIQUE,
    setting_value   TEXT NOT NULL,
    description     TEXT,
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- ข้อมูลเริ่มต้น
INSERT INTO roles (name, description) VALUES
    ('admin', 'ผู้ดูแลระบบ'),
    ('manager', 'ผู้จัดการ'),
    ('cashier', 'พนักงานขาย'),
    ('warehouse', 'พนักงานคลัง');

INSERT INTO member_types (name, description, discount_rate) VALUES
    ('retail', 'ลูกค้าปลีก', 0),
    ('wholesale', 'ลูกค้าส่ง', 5.00),
    ('vip', 'ลูกค้า VIP', 10.00);

INSERT INTO payment_methods (name) VALUES
    ('cash'),
    ('credit_card'),
    ('bank_transfer'),
    ('credit');

INSERT INTO units (name) VALUES
    ('ชิ้น'),
    ('กล่อง'),
    ('โหล'),
    ('กิโลกรัม'),
    ('ลิตร'),
    ('เมตร');

INSERT INTO system_settings (setting_key, setting_value, description) VALUES
    ('store_name', 'ร้านค้าของฉัน', 'ชื่อร้าน'),
    ('store_address', '', 'ที่อยู่ร้าน'),
    ('store_phone', '', 'เบอร์โทรร้าน'),
    ('tax_rate', '7', 'อัตราภาษี (%)'),
    ('receipt_prefix', 'PS', 'คำนำหน้าเลขที่บิล'),
    ('credit_due_days', '30', 'จำนวนวันที่ให้เครดิต');
