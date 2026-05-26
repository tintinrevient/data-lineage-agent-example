-- ============================================================================
-- Oracle Database Seed Script
-- Creates TESTUSER schema with sample data and stored procedures
-- ============================================================================

-- Connect as system user
CONN system/TestPassword123@FREE;

-- Create testuser (if not exists)
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM all_users WHERE username = 'TESTUSER';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER testuser IDENTIFIED BY TestPassword123';
    EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE TO testuser';
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO testuser';
    EXECUTE IMMEDIATE 'GRANT CREATE TABLE TO testuser';
    EXECUTE IMMEDIATE 'GRANT CREATE VIEW TO testuser';
    EXECUTE IMMEDIATE 'GRANT CREATE SEQUENCE TO testuser';
    EXECUTE IMMEDIATE 'GRANT CREATE PROCEDURE TO testuser';
    EXECUTE IMMEDIATE 'GRANT UNLIMITED TABLESPACE TO testuser';
    DBMS_OUTPUT.PUT_LINE('User TESTUSER created successfully');
  ELSE
    DBMS_OUTPUT.PUT_LINE('User TESTUSER already exists');
  END IF;
END;
/

-- Switch to testuser
CONN testuser/TestPassword123@FREE;

-- ============================================================================
-- CUSTOMERS table
-- ============================================================================
CREATE TABLE customers (
  customer_id   NUMBER PRIMARY KEY,
  first_name    VARCHAR2(100) NOT NULL,
  last_name     VARCHAR2(100) NOT NULL,
  email         VARCHAR2(255) UNIQUE NOT NULL,
  phone         VARCHAR2(20),
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PRODUCTS table
-- ============================================================================
CREATE TABLE products (
  product_id    NUMBER PRIMARY KEY,
  product_name  VARCHAR2(200) NOT NULL,
  category      VARCHAR2(100),
  price         NUMBER(10,2) NOT NULL,
  stock_qty     NUMBER DEFAULT 0,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- ORDERS table
-- ============================================================================
CREATE TABLE orders (
  order_id      NUMBER PRIMARY KEY,
  customer_id   NUMBER NOT NULL,
  order_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status        VARCHAR2(50) DEFAULT 'pending',
  total_amount  NUMBER(12,2),
  CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ============================================================================
-- ORDER_ITEMS table
-- ============================================================================
CREATE TABLE order_items (
  order_item_id NUMBER PRIMARY KEY,
  order_id      NUMBER NOT NULL,
  product_id    NUMBER NOT NULL,
  quantity      NUMBER NOT NULL,
  unit_price    NUMBER(10,2) NOT NULL,
  CONSTRAINT fk_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ============================================================================
-- Insert sample data
-- ============================================================================

-- Sample customers
INSERT INTO customers (customer_id, first_name, last_name, email, phone) VALUES
  (1, 'Alice', 'Smith', 'alice.smith@example.com', '555-0101');
INSERT INTO customers (customer_id, first_name, last_name, email, phone) VALUES
  (2, 'Bob', 'Johnson', 'bob.johnson@example.com', '555-0102');
INSERT INTO customers (customer_id, first_name, last_name, email, phone) VALUES
  (3, 'Carol', 'Williams', 'carol.williams@example.com', '555-0103');
INSERT INTO customers (customer_id, first_name, last_name, email, phone) VALUES
  (4, 'David', 'Brown', 'david.brown@example.com', '555-0104');
INSERT INTO customers (customer_id, first_name, last_name, email, phone) VALUES
  (5, 'Eve', 'Davis', 'eve.davis@example.com', '555-0105');

-- Sample products
INSERT INTO products (product_id, product_name, category, price, stock_qty) VALUES
  (1, 'Laptop Pro 15', 'Electronics', 1299.99, 25);
INSERT INTO products (product_id, product_name, category, price, stock_qty) VALUES
  (2, 'Wireless Mouse', 'Electronics', 29.99, 150);
INSERT INTO products (product_id, product_name, category, price, stock_qty) VALUES
  (3, 'USB-C Hub', 'Electronics', 49.99, 75);
INSERT INTO products (product_id, product_name, category, price, stock_qty) VALUES
  (4, 'Office Chair', 'Furniture', 299.99, 40);
INSERT INTO products (product_id, product_name, category, price, stock_qty) VALUES
  (5, 'Standing Desk', 'Furniture', 599.99, 20);
INSERT INTO products (product_id, product_name, category, price, stock_qty) VALUES
  (6, 'Notebook Set', 'Stationery', 12.99, 200);

-- Sample orders
INSERT INTO orders (order_id, customer_id, status, total_amount) VALUES
  (1, 1, 'completed', 1329.98);
INSERT INTO orders (order_id, customer_id, status, total_amount) VALUES
  (2, 2, 'shipped', 899.98);
INSERT INTO orders (order_id, customer_id, status, total_amount) VALUES
  (3, 1, 'pending', 49.99);
INSERT INTO orders (order_id, customer_id, status, total_amount) VALUES
  (4, 3, 'completed', 312.98);
INSERT INTO orders (order_id, customer_id, status, total_amount) VALUES
  (5, 4, 'pending', 1299.99);

-- Sample order items
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
  (1, 1, 1, 1, 1299.99);
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
  (2, 1, 2, 1, 29.99);
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
  (3, 2, 4, 1, 299.99);
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
  (4, 2, 5, 1, 599.99);
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
  (5, 3, 3, 1, 49.99);
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
  (6, 4, 6, 1, 12.99);
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
  (7, 4, 4, 1, 299.99);
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
  (8, 5, 1, 1, 1299.99);

COMMIT;

-- ============================================================================
-- Stored Procedure: UPDATE_ORDER_STATUS
-- ============================================================================
CREATE OR REPLACE PROCEDURE update_order_status (
  p_order_id IN NUMBER,
  p_new_status IN VARCHAR2
) AS
  v_count NUMBER;
BEGIN
  -- Check if order exists
  SELECT COUNT(*) INTO v_count FROM orders WHERE order_id = p_order_id;

  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Order ID ' || p_order_id || ' not found');
  END IF;

  -- Update the order status
  UPDATE orders
  SET status = p_new_status,
      updated_at = CURRENT_TIMESTAMP
  WHERE order_id = p_order_id;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Order ' || p_order_id || ' status updated to ' || p_new_status);
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/

-- ============================================================================
-- Stored Procedure: CALCULATE_ORDER_TOTAL
-- ============================================================================
CREATE OR REPLACE PROCEDURE calculate_order_total (
  p_order_id IN NUMBER,
  p_total OUT NUMBER
) AS
BEGIN
  SELECT NVL(SUM(quantity * unit_price), 0)
  INTO p_total
  FROM order_items
  WHERE order_id = p_order_id;

  -- Update the orders table with the calculated total
  UPDATE orders
  SET total_amount = p_total
  WHERE order_id = p_order_id;

  COMMIT;
END;
/

-- ============================================================================
-- Useful view
-- ============================================================================
CREATE OR REPLACE VIEW v_order_summary AS
SELECT
    o.order_id,
    o.order_date,
    o.status,
    o.total_amount,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    COUNT(oi.order_item_id) AS line_count
FROM orders       o
JOIN customers    c  ON c.customer_id = o.customer_id
JOIN order_items  oi ON oi.order_id   = o.order_id
GROUP BY
    o.order_id, o.order_date, o.status, o.total_amount,
    c.customer_id, c.first_name, c.last_name, c.email;

-- ============================================================================
-- Add updated_at column to orders table if missing
-- ============================================================================
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM user_tab_columns
  WHERE table_name = 'ORDERS' AND column_name = 'UPDATED_AT';

  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE orders ADD updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP';
  END IF;
END;
/

-- ============================================================================
-- Verify setup
-- ============================================================================
SELECT 'Database seeded successfully!' AS status FROM dual;
SELECT COUNT(*) AS customer_count FROM customers;
SELECT COUNT(*) AS product_count FROM products;
SELECT COUNT(*) AS order_count FROM orders;
SELECT COUNT(*) AS order_item_count FROM order_items;

-- Show tables
SELECT table_name FROM user_tables ORDER BY table_name;

EXIT;