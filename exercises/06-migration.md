# Lab 06: Change without damage

Chapter: [Change Without Damage](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/06-change-without-damage.qmd)

## Start

```bash
make reset
make psql
```

The reset gives you the base schema without `orders.channel`.

## Tasks

1. Write the migration in stages:
   - Add `orders.channel` as nullable.
   - Backfill every existing order.
   - Add a check for `web`, `wholesale` and `phone`.
   - Prove there are no nulls.
   - Make the column `NOT NULL`.
2. Write the rollback.
3. Run the migration on a copy first. For this lab, `make reset` is the copy.
4. Try to insert an order with an invalid channel. It must fail.
5. Try to insert an order with no channel. It must fail.

## Run a solution

```bash
make run FILE=solutions/06-migration.sql
make check LAB=06
```

Read the solution only after you have written your own. The point is the order of
the steps and the lock budget, not the exact file.

## Check

```bash
make check LAB=06
```

The check confirms the column exists, is `NOT NULL`, has no nulls, has only the
allowed values, and rejects an invalid channel.

## Then break it

Run the migration a second time. What fails? Is the failure safe? What does that
tell you about idempotence in a migration you might rerun after a partial deploy?
