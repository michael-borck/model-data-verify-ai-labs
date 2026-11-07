\set ON_ERROR_STOP on
\echo 'Checking roles and row-level security...'

DROP TABLE IF EXISTS lab_tickets;

DO $$
BEGIN
  BEGIN
    EXECUTE 'DROP OWNED BY lab_agent, lab_ada, lab_grace, lab_stranger';
  EXCEPTION WHEN undefined_object THEN
    NULL;
  END;
END $$;

DROP ROLE IF EXISTS lab_ada;
DROP ROLE IF EXISTS lab_grace;
DROP ROLE IF EXISTS lab_stranger;
DROP ROLE IF EXISTS lab_agent;

CREATE ROLE lab_agent NOLOGIN;
CREATE ROLE lab_ada NOLOGIN;
CREATE ROLE lab_grace NOLOGIN;
CREATE ROLE lab_stranger NOLOGIN;

GRANT lab_agent TO lab_ada, lab_grace;

CREATE TABLE lab_tickets (
  ticket_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  assigned_to text NOT NULL,
  subject     text NOT NULL
);

INSERT INTO lab_tickets (assigned_to, subject) VALUES
  ('lab_ada',   'Ada one'),
  ('lab_ada',   'Ada two'),
  ('lab_grace', 'Grace one');

ALTER TABLE lab_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY lab_ticket_owner ON lab_tickets
  FOR ALL
  USING (assigned_to = current_user)
  WITH CHECK (assigned_to = current_user);

GRANT USAGE ON SCHEMA public TO lab_agent;
GRANT SELECT, INSERT, UPDATE, DELETE ON lab_tickets TO lab_agent;
GRANT USAGE, SELECT ON SEQUENCE lab_tickets_ticket_id_seq TO lab_agent;

-- Ada sees only her two rows.
SET ROLE lab_ada;
DO $$
DECLARE
  n bigint;
BEGIN
  SELECT count(*) INTO n FROM lab_tickets;
  IF n <> 2 THEN
    RAISE EXCEPTION 'Ada should see 2 tickets, saw %', n;
  END IF;

  SELECT count(*) INTO n FROM lab_tickets WHERE assigned_to = 'lab_grace';
  IF n <> 0 THEN
    RAISE EXCEPTION 'Ada can see Grace''s tickets';
  END IF;
END $$;
RESET ROLE;

-- Ada cannot insert a ticket for Grace.
SET ROLE lab_ada;
DO $$
BEGIN
  BEGIN
    INSERT INTO lab_tickets (assigned_to, subject)
    VALUES ('lab_grace', 'Not mine');
    RAISE EXCEPTION 'insert for another assignee was accepted';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END $$;
RESET ROLE;

-- Ada can insert her own ticket.
SET ROLE lab_ada;
INSERT INTO lab_tickets (assigned_to, subject)
VALUES ('lab_ada', 'Ada three');
DO $$
DECLARE
  n bigint;
BEGIN
  SELECT count(*) INTO n FROM lab_tickets;
  IF n <> 3 THEN
    RAISE EXCEPTION 'Ada should see 3 tickets after her insert, saw %', n;
  END IF;
END $$;
RESET ROLE;

-- A role with no grant is denied.
SET ROLE lab_stranger;
DO $$
BEGIN
  BEGIN
    PERFORM count(*) FROM lab_tickets;
    RAISE EXCEPTION 'ungranted role could read the table';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END $$;
RESET ROLE;

-- The owner sees everything.
DO $$
DECLARE
  n bigint;
BEGIN
  SELECT count(*) INTO n FROM lab_tickets;
  IF n <> 4 THEN
    RAISE EXCEPTION 'owner should see 4 tickets, saw %', n;
  END IF;
END $$;

DROP TABLE lab_tickets;

DO $$
BEGIN
  BEGIN
    EXECUTE 'DROP OWNED BY lab_agent, lab_ada, lab_grace, lab_stranger';
  EXCEPTION WHEN undefined_object THEN
    NULL;
  END;
END $$;

DROP ROLE IF EXISTS lab_ada;
DROP ROLE IF EXISTS lab_grace;
DROP ROLE IF EXISTS lab_stranger;
DROP ROLE IF EXISTS lab_agent;

\echo '10-access checks passed'
