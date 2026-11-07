# Lab 13: Retrieval quality

Chapter: [Retrieval Quality and the AI Data Layer](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/13-retrieval-quality-and-the-ai-data-layer.qmd)

## Start

```bash
make up
make psql
```

## Run the check

```bash
make check LAB=13
```

The check builds a small labelled set with four queries. It computes recall at 2
per query and overall. Three queries pass and one fails, which is the point: the
evaluation has to show the miss, not hide it in an average.

## Do it by hand

1. Create the docs, queries and relevance tables from the check.
2. Run the ranking query:

   ```sql
   SELECT q.query_id, d.doc_id,
          row_number() OVER (
            PARTITION BY q.query_id
            ORDER BY d.embedding <=> q.embedding
          ) AS rank,
          d.embedding <=> q.embedding AS distance
   FROM lab_eval_queries q
   CROSS JOIN lab_eval_docs d
   ORDER BY q.query_id, rank;
   ```

3. Compare the top two with `lab_eval_relevance`. Which query misses, and why?
4. Add a no-answer query. What should the pipeline return? How would you label it?
5. Add a fifth relevant document to query 4. Recompute recall.
6. Add a tenant filter and test a restricted query.

## Then break it

1. Change the chunk or vector for one document. Does recall improve or get worse?
2. Add a document from a second embedding model. What happens to the ranking?
3. Delete a source document but leave its vector. Is the old answer still
   retrievable?
4. Write a CI threshold: `recall at 2 must be at least 0.8`. Does the set pass?

## Reset

```bash
make reset
```

The check drops its own tables.
