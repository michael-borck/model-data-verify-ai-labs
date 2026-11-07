\set ON_ERROR_STOP on
\echo 'Checking retrieval quality...'

CREATE EXTENSION IF NOT EXISTS vector;

DROP TABLE IF EXISTS lab_eval_relevance;
DROP TABLE IF EXISTS lab_eval_queries;
DROP TABLE IF EXISTS lab_eval_docs;

CREATE TABLE lab_eval_docs (
  doc_id    integer PRIMARY KEY,
  title     text NOT NULL,
  embedding vector(3) NOT NULL
);

CREATE TABLE lab_eval_queries (
  query_id    integer PRIMARY KEY,
  query_text  text NOT NULL,
  embedding   vector(3) NOT NULL
);

CREATE TABLE lab_eval_relevance (
  query_id integer NOT NULL REFERENCES lab_eval_queries(query_id),
  doc_id   integer NOT NULL REFERENCES lab_eval_docs(doc_id),
  PRIMARY KEY (query_id, doc_id)
);

INSERT INTO lab_eval_docs (doc_id, title, embedding) VALUES
  (1, 'Cancel an order',       '[1.0, 0.0, 0.0]'),
  (2, 'Stop a shipment',       '[0.9, 0.1, 0.0]'),
  (3, 'Refund policy',         '[0.0, 1.0, 0.0]'),
  (4, 'Contact support',       '[0.0, 0.0, 1.0]'),
  (5, 'Cancel a subscription', '[0.8, 0.2, 0.0]'),
  (6, 'Returns and refunds',   '[0.7, 0.7, 0.0]');

INSERT INTO lab_eval_queries (query_id, query_text, embedding) VALUES
  (1, 'cancel my order',      '[1.0, 0.0, 0.0]'),
  (2, 'how do refunds work',  '[0.1, 0.9, 0.0]'),
  (3, 'contact a person',     '[0.0, 0.0, 1.0]'),
  (4, 'where is my refund',   '[0.9, 0.1, 0.1]');

INSERT INTO lab_eval_relevance (query_id, doc_id) VALUES
  (1, 1), (1, 2),
  (2, 3), (2, 6),
  (3, 4),
  (4, 4);

DO $$
DECLARE
  q1 numeric;
  q2 numeric;
  q3 numeric;
  q4 numeric;
  overall numeric;
BEGIN
  WITH ranked AS (
    SELECT q.query_id,
           d.doc_id,
           row_number() OVER (
             PARTITION BY q.query_id
             ORDER BY d.embedding <=> q.embedding
           ) AS rank
    FROM lab_eval_queries q
    CROSS JOIN lab_eval_docs d
  ),
  scored AS (
    SELECT rel.query_id,
           count(*) AS relevant,
           count(*) FILTER (WHERE ranked.rank <= 2) AS hits
    FROM lab_eval_relevance rel
    LEFT JOIN ranked
      ON ranked.query_id = rel.query_id
     AND ranked.doc_id = rel.doc_id
    GROUP BY rel.query_id
  )
  SELECT
    max(CASE WHEN query_id = 1 THEN hits::numeric / relevant END),
    max(CASE WHEN query_id = 2 THEN hits::numeric / relevant END),
    max(CASE WHEN query_id = 3 THEN hits::numeric / relevant END),
    max(CASE WHEN query_id = 4 THEN hits::numeric / relevant END),
    sum(hits)::numeric / sum(relevant)
  INTO q1, q2, q3, q4, overall
  FROM scored;

  IF q1 <> 1.0 THEN
    RAISE EXCEPTION 'query 1 recall: expected 1.0, got %', q1;
  END IF;
  IF q2 <> 1.0 THEN
    RAISE EXCEPTION 'query 2 recall: expected 1.0, got %', q2;
  END IF;
  IF q3 <> 1.0 THEN
    RAISE EXCEPTION 'query 3 recall: expected 1.0, got %', q3;
  END IF;
  IF q4 <> 0.0 THEN
    RAISE EXCEPTION 'query 4 recall: expected 0.0, got %', q4;
  END IF;
  IF round(overall, 3) <> 0.833 THEN
    RAISE EXCEPTION 'overall recall: expected 0.833, got %', round(overall, 3);
  END IF;
END $$;

DROP TABLE lab_eval_relevance;
DROP TABLE lab_eval_queries;
DROP TABLE lab_eval_docs;

\echo '13-retrieval checks passed'
