\set ON_ERROR_STOP on
\echo 'Checking vectors and semantic search...'

CREATE EXTENSION IF NOT EXISTS vector;

DROP TABLE IF EXISTS lab_documents;
CREATE TABLE lab_documents (
  doc_id    integer PRIMARY KEY,
  title     text NOT NULL,
  embedding vector(3) NOT NULL
);

INSERT INTO lab_documents (doc_id, title, embedding) VALUES
  (1, 'Cancel an order',        '[1.0, 0.0, 0.0]'),
  (2, 'Stop a shipment',        '[0.9, 0.1, 0.0]'),
  (3, 'Refund policy',          '[0.0, 1.0, 0.0]'),
  (4, 'Contact support',        '[0.0, 0.0, 1.0]'),
  (5, 'Cancel a subscription',  '[0.8, 0.2, 0.0]');

DO $$
DECLARE
  first_id integer;
  second_id integer;
BEGIN
  SELECT doc_id INTO first_id
  FROM lab_documents
  ORDER BY embedding <=> '[1.0, 0.0, 0.0]'::vector
  LIMIT 1;

  SELECT doc_id INTO second_id
  FROM lab_documents
  ORDER BY embedding <=> '[1.0, 0.0, 0.0]'::vector
  OFFSET 1 LIMIT 1;

  IF first_id <> 1 THEN
    RAISE EXCEPTION 'nearest document: expected 1, got %', first_id;
  END IF;
  IF second_id <> 2 THEN
    RAISE EXCEPTION 'second document: expected 2, got %', second_id;
  END IF;
END $$;

CREATE INDEX lab_documents_embedding_idx
ON lab_documents
USING hnsw (embedding vector_cosine_ops);

DO $$
DECLARE
  n bigint;
BEGIN
  SELECT count(*) INTO n
  FROM pg_indexes
  WHERE schemaname = 'public'
    AND indexname = 'lab_documents_embedding_idx';

  IF n <> 1 THEN
    RAISE EXCEPTION 'HNSW index was not created';
  END IF;
END $$;

DROP TABLE lab_documents;
\echo '12-vector checks passed'
