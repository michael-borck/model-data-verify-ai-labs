# Lab 12: Vectors and semantic search

Chapter: [Vectors and Semantic Search](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/12-vectors-and-semantic-search.qmd)

## Start

```bash
make up
make psql
```

The lab image includes the `pgvector` extension.

## Run the check

```bash
make check LAB=12
```

The check creates a small table of toy three-dimensional vectors, verifies the
cosine ranking by hand, creates an HNSW index and confirms it exists.

## Do it by hand

1. Create the extension and table:

   ```sql
   CREATE EXTENSION IF NOT EXISTS vector;
   CREATE TABLE lab_documents (
     doc_id integer PRIMARY KEY,
     title text NOT NULL,
     embedding vector(3) NOT NULL
   );
   ```

2. Insert the toy vectors from the check.

3. Query the nearest rows:

   ```sql
   SELECT doc_id, title, embedding <=> '[1,0,0]'::vector AS distance
   FROM lab_documents
   ORDER BY distance
   LIMIT 3;
   ```

4. Compute the distances by hand. Which document is second? Why?

5. Create the HNSW index:

   ```sql
   CREATE INDEX lab_documents_embedding_idx
   ON lab_documents
   USING hnsw (embedding vector_cosine_ops);
   ```

6. Run `EXPLAIN` on the query. On five rows, does the planner use the index? What
   does that tell you about small-table demos?

## Then break it

1. Change the query to `ORDER BY embedding <-> '[1,0,0]'::vector` (L2 instead of
   cosine). Which order do you get? Which operator matches your model?
2. Add a `tenant_id` filter and test a selective and a broad value.
3. Add a sixth document with a vector from a different "model" and mix it in.
   What does the ranking do?
4. Label five queries and compute recall at 2. Change one chunk and recompute.

## Reset

```bash
make reset
```

The check drops its own table.
