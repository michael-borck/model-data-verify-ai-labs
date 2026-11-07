# Lab 16: The verified data layer

Chapter: [The Verified Data Layer](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/16-the-verified-data-layer.qmd)

## Start

From the lab repository:

```bash
make capstone
```

The capstone resets the database and runs the whole suite in a safe order:

- schema, constraints, queries, joins, aggregation and CTEs
- the two-session transaction scenario
- the migration and rollback check
- the backfill rerun check
- the index plan check
- the dump and restore test
- access and RLS
- privacy and injection
- vectors and retrieval quality

It stops on the first failure.

## Produce the evidence pack

Record the result of each check. For the measured items, include:

- restore time and size
- the index plan before and after
- the denied query and the role that was denied
- the injection payload and the safe result
- recall at 2 or 3
- the known limits

## Write the release note

```text
Release: Model Data, Verify AI (Harbour Coffee case)
Commit:
Date:
Database:
Trim / version:

Checks:
- Schema / constraints: pass
- Queries / known answers: pass
- Joins / grain: pass
- Transactions: pass
- Migration / rollback: pass
- Backfill / rerun: pass
- Index / plan: pass
- Backup / restore: pass
- Access / RLS: pass
- Privacy / injection: pass
- Retrieval / recall: pass

Measured:
- Restore time:
- Index plan:
- Recall at 3:
- Known limits:

Signed off by:
```

## Break one check

Pick a check and break it on purpose:

- remove a foreign key,
- change a known answer,
- skip the migration,
- drop the index,
- truncate the dump,
- remove `WITH CHECK`,
- remove the `USING` clause,
- break the recall set.

Run the capstone again. It must fail at the broken step. Repair it and run from a
fresh reset.

## Add a feature

Take the next feature through the whole loop:

1. Model the change and its constraints.
2. Write the query and the known answer.
3. Add the transaction or migration.
4. Backfill in batches.
5. Add the index.
6. Restore a backup.
7. Set the role boundary.
8. Set the retention rule.
9. Add the retrieval query and the labelled set.

Then rerun `make capstone`.

## Reset

```bash
make reset
```

The capstone ends with `make down`. Use `make up` to inspect the final state.
