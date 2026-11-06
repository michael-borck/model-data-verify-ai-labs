# Model Data, Verify AI: Labs

A small Docker lab for *Model Data, Verify AI*. One PostgreSQL container, one
seeded case, and one check per chapter. No database install, no cloud account.

The companion book is at [michael-borck/model-data-verify-ai](https://github.com/michael-borck/model-data-verify-ai).

## What you need

- Docker Desktop, Docker Engine, or Podman with Compose.
- A terminal.
- About two minutes for the first pull.

If Docker is not available, use GitHub Codespaces on the repository and run the
same commands in the browser terminal.

## Quick start

```bash
./start.sh
```

That starts PostgreSQL, waits for it to be ready, and opens `psql`.

If you prefer `make`:

```bash
make up
make psql
```

The database listens on `127.0.0.1:5433`, not 5432, so it does not collide with a
local PostgreSQL server. The container is reachable only from your machine.

## The chapters

| Lab | Chapter | Check |
|---|---|---|
| 01 | Model before query | `make check LAB=01` |
| 02 | Questions into SQL | `make check LAB=02` |
| 03 | Change without damage | `make check LAB=03` |

Each lab guide is in `exercises/`. Read the chapter, do the tasks, then run the
check. The check is the point: it fails loudly when the answer is wrong.

## Commands

```bash
make up                 # start the database
make psql               # open psql
make check LAB=01       # run the chapter check
make run FILE=path.sql  # run a SQL file
make reset              # destroy the volume and rebuild from seed
make logs               # follow the database log
make down               # stop the container
```

`make reset` is the one to remember. The schema and seed are loaded only when the
database volume is first created. If you change the seed or break the schema, reset.

## What is in the container

- PostgreSQL 16.
- The Harbour Coffee schema from `db/schema.sql`.
- The seed data from `db/seed.sql`.
- A named volume for the data, so a restart keeps your work.
- No host bind mount for the database files. This avoids the portability problems
  that external drives and mixed filesystems cause.

The init scripts are mounted read-only from `db/`. They run in order on the
first start.

## The checks

Each file in `checks/` is a SQL script that asserts the expected result. A failed
assertion stops with an exception. A successful run ends with a line like:

```text
02-query checks passed
```

The checks are not a grading system. They are the same known-answer discipline the
book teaches, written down so you can run it.

## The migration lab

Lab 03 starts from the base schema without `orders.channel`.

```bash
make reset
make psql
```

Write your migration, then run:

```bash
make check LAB=03
```

A solution is in `solutions/03-migration.sql`. Read it after your own attempt.
The order of the steps is the lesson, not the exact text.

## Security

This is a local teaching database. The default password is a convenience, not a
secret. The port is bound to `127.0.0.1`, so it is not reachable from your network.

- Do not reuse the password for anything real.
- Do not put real customer data in the lab.
- Do not expose the port to `0.0.0.0`.

If you want your own local credentials, copy `.env.example` to `.env` and change
them before the first start.

## Podman

`./start.sh` detects Docker Compose first, then Podman Compose. If you use the
Makefile, set the compose command explicitly:

```bash
make COMPOSE="podman compose" up
make COMPOSE="podman compose" psql
```

## Codespaces

Open the repository in a Codespace, then:

```bash
./start.sh
```

Docker is available in the default Codespaces image. If it is not, install the
Docker feature or use the repository's dev container.

## File map

```text
.
├── compose.yaml
├── Makefile
├── start.sh
├── .env.example
├── db/
│   ├── schema.sql
│   ├── seed.sql
│   └── known-answers.md
├── checks/
│   ├── 01-model.sql
│   ├── 02-queries.sql
│   └── 03-migration.sql
├── exercises/
│   ├── 01-model.md
│   ├── 02-queries.md
│   └── 03-migration.md
└── solutions/
    └── 03-migration.sql
```

## Troubleshooting

**Port 5433 is already in use.** Change `POSTGRES_PORT` in `.env` or in your
environment, then `make reset`.

**The schema looks stale.** The init scripts do not rerun on an existing volume.
Run `make reset`.

**`psql: error: connection refused`.** The container is not ready. Run
`make up` and wait for the health check, or check `make logs`.

**AppleDouble `._*` files on an external drive.** The lab uses no host database
mounts, so the database files are not affected. If a local Docker build fails,
that is a host filesystem issue, not the lab data.
