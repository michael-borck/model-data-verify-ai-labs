\set ON_ERROR_STOP on

-- 1. Add the column, nullable.
BEGIN;
SET LOCAL lock_timeout = '3s';
ALTER TABLE orders ADD COLUMN channel text;
COMMIT;

-- 2. Backfill. One statement is fine for the pilot data.
BEGIN;
SET LOCAL lock_timeout = '3s';
UPDATE orders SET channel = 'web' WHERE channel IS NULL;
COMMIT;

-- 3. Add the value check without scanning the table yet.
BEGIN;
SET LOCAL lock_timeout = '3s';
ALTER TABLE orders
  ADD CONSTRAINT orders_channel_check
  CHECK (channel IN ('web', 'wholesale', 'phone'))
  NOT VALID;
COMMIT;

-- 4. Validate the value check.
BEGIN;
SET LOCAL lock_timeout = '3s';
ALTER TABLE orders VALIDATE CONSTRAINT orders_channel_check;
COMMIT;

-- 5. Prove there are no nulls, then require the column.
BEGIN;
SET LOCAL lock_timeout = '3s';
ALTER TABLE orders
  ADD CONSTRAINT orders_channel_not_null
  CHECK (channel IS NOT NULL)
  NOT VALID;
COMMIT;

BEGIN;
SET LOCAL lock_timeout = '3s';
ALTER TABLE orders VALIDATE CONSTRAINT orders_channel_not_null;
COMMIT;

BEGIN;
SET LOCAL lock_timeout = '3s';
ALTER TABLE orders ALTER COLUMN channel SET NOT NULL;
ALTER TABLE orders DROP CONSTRAINT orders_channel_not_null;
COMMIT;
