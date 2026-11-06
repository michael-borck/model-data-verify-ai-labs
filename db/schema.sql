-- Model Data, Verify AI: starting schema for the Harbour Coffee case.
-- PostgreSQL 15 or later.

DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS invoices CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
  customer_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        text NOT NULL,
  email       text NOT NULL UNIQUE,
  phone       text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE products (
  product_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku         text NOT NULL UNIQUE,
  name        text NOT NULL,
  price_cents integer NOT NULL CHECK (price_cents >= 0),
  active      boolean NOT NULL DEFAULT true
);

CREATE TABLE orders (
  order_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id      integer NOT NULL REFERENCES customers(customer_id),
  ordered_at       timestamptz NOT NULL,
  status           text NOT NULL CHECK (status IN ('pending', 'shipped', 'cancelled')),
  shipping_address text NOT NULL
);

CREATE TABLE order_items (
  order_id         integer NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  product_id       integer NOT NULL REFERENCES products(product_id),
  quantity         integer NOT NULL CHECK (quantity > 0),
  unit_price_cents integer NOT NULL CHECK (unit_price_cents >= 0),
  PRIMARY KEY (order_id, product_id)
);

CREATE TABLE invoices (
  invoice_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_id    integer NOT NULL UNIQUE REFERENCES orders(order_id),
  issued_at   timestamptz NOT NULL,
  due_at      timestamptz NOT NULL,
  paid_at     timestamptz,
  total_cents integer NOT NULL CHECK (total_cents >= 0),
  CHECK (due_at >= issued_at),
  CHECK (paid_at IS NULL OR paid_at >= issued_at)
);

CREATE TABLE payments (
  payment_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  invoice_id   integer NOT NULL REFERENCES invoices(invoice_id),
  paid_at      timestamptz NOT NULL,
  amount_cents integer NOT NULL CHECK (amount_cents > 0),
  method       text NOT NULL CHECK (method IN ('card', 'bank', 'cash'))
);
