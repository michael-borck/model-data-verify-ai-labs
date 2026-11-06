-- Model Data, Verify AI: seed data for the Harbour Coffee case.
-- Run after schema.sql.

INSERT INTO customers (customer_id, name, email, phone, created_at) OVERRIDING SYSTEM VALUE VALUES
  (1, 'Ada Lovelace',      'ada@example.com',       '+61 400 000 001', '2025-11-02 09:00+08'),
  (2, 'Grace Hopper',      'grace@example.com',     '+61 400 000 002', '2025-12-11 10:30+08'),
  (3, 'Alan Turing',       'alan@example.com',      '+61 400 000 003', '2026-01-08 14:15+08'),
  (4, 'Katherine Johnson', 'katherine@example.com', '+61 400 000 004', '2026-02-19 08:45+08'),
  (5, 'Edsger Dijkstra',   'edsger@example.com',    '+61 400 000 005', '2026-03-03 16:20+08'),
  (6, 'Barbara Liskov',    'barbara@example.com',   '+61 400 000 006', '2026-04-02 11:10+08');

INSERT INTO products (product_id, sku, name, price_cents, active) OVERRIDING SYSTEM VALUE VALUES
  (1, 'HB-ESP-1', 'Harbour Espresso Blend 1kg', 3200, true),
  (2, 'HB-FIL-1', 'Harbour Filter Blend 1kg',   3000, true),
  (3, 'HB-DEC-1', 'Harbour Decaf 1kg',          3400, true),
  (4, 'HB-MUG-1', 'Harbour Ceramic Mug',        1800, true),
  (5, 'HB-SUB-1', 'Monthly Subscription',       4500, true),
  (6, 'HB-GFT-1', 'Harbour Gift Box',           5500, true);

INSERT INTO orders (order_id, customer_id, ordered_at, status, shipping_address) OVERRIDING SYSTEM VALUE VALUES
  (1,  1, '2026-01-05 09:15+08', 'shipped',   '12 St Georges Tce, Perth WA'),
  (2,  2, '2026-01-12 14:40+08', 'shipped',   '4/88 Stirling Hwy, Nedlands WA'),
  (3,  1, '2026-02-02 11:05+08', 'cancelled', '12 St Georges Tce, Perth WA'),
  (4,  3, '2026-02-14 16:20+08', 'shipped',   '31 Oxford St, Leederville WA'),
  (5,  4, '2026-03-01 08:55+08', 'pending',   '7 Beach Rd, Fremantle WA'),
  (6,  2, '2026-03-15 10:10+08', 'shipped',   '4/88 Stirling Hwy, Nedlands WA'),
  (7,  5, '2026-03-20 13:30+08', 'shipped',   '19 William St, Northbridge WA'),
  (8,  1, '2026-04-01 09:45+08', 'shipped',   '12 St Georges Tce, Perth WA'),
  (9,  3, '2026-04-10 15:05+08', 'pending',   '31 Oxford St, Leederville WA'),
  (10, 4, '2026-04-15 12:25+08', 'shipped',   '7 Beach Rd, Fremantle WA');

INSERT INTO order_items (order_id, product_id, quantity, unit_price_cents) VALUES
  (1, 1, 2, 3200),
  (1, 4, 1, 1800),
  (2, 2, 1, 3000),
  (2, 6, 1, 5500),
  (3, 1, 1, 3200),
  (4, 3, 2, 3400),
  (5, 5, 1, 4500),
  (6, 1, 1, 3200),
  (6, 2, 1, 3000),
  (7, 4, 2, 1800),
  (7, 6, 1, 5500),
  (8, 1, 3, 3200),
  (9, 2, 2, 3000),
  (10, 3, 1, 3400),
  (10, 4, 1, 1800);

INSERT INTO invoices (invoice_id, order_id, issued_at, due_at, paid_at, total_cents) OVERRIDING SYSTEM VALUE VALUES
  (1, 1,  '2026-01-05 09:30+08', '2026-01-19 23:59+08', '2026-01-10 10:00+08', 8200),
  (2, 2,  '2026-01-12 15:00+08', '2026-01-26 23:59+08', '2026-01-20 09:30+08', 8500),
  (3, 4,  '2026-02-14 16:45+08', '2026-02-28 23:59+08', '2026-02-20 11:15+08', 6800),
  (4, 6,  '2026-03-15 10:30+08', '2026-03-29 23:59+08', NULL,                   6200),
  (5, 7,  '2026-03-20 14:00+08', '2026-04-03 23:59+08', '2026-03-25 08:45+08', 9100),
  (6, 8,  '2026-04-01 10:00+08', '2026-04-15 23:59+08', NULL,                   9600),
  (7, 10, '2026-04-15 12:40+08', '2026-04-29 23:59+08', '2026-04-20 16:30+08', 5200);

INSERT INTO payments (payment_id, invoice_id, paid_at, amount_cents, method) OVERRIDING SYSTEM VALUE VALUES
  (1, 1, '2026-01-10 10:00+08', 8200, 'card'),
  (2, 2, '2026-01-20 09:30+08', 8500, 'bank'),
  (3, 3, '2026-02-20 11:15+08', 6800, 'card'),
  (4, 5, '2026-03-25 08:45+08', 9100, 'bank'),
  (5, 7, '2026-04-20 16:30+08', 5200, 'card');

SELECT setval(pg_get_serial_sequence('customers', 'customer_id'), (SELECT MAX(customer_id) FROM customers));
SELECT setval(pg_get_serial_sequence('products', 'product_id'), (SELECT MAX(product_id) FROM products));
SELECT setval(pg_get_serial_sequence('orders', 'order_id'), (SELECT MAX(order_id) FROM orders));
SELECT setval(pg_get_serial_sequence('invoices', 'invoice_id'), (SELECT MAX(invoice_id) FROM invoices));
SELECT setval(pg_get_serial_sequence('payments', 'payment_id'), (SELECT MAX(payment_id) FROM payments));
