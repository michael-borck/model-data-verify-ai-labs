# Lab 10: Access, roles and row-level security

Chapter: [Access, Roles and Row-Level Security](https://github.com/michael-borck/model-data-verify-ai/blob/main/chapters/10-access-roles-and-row-level-security.qmd)

## Start

```bash
make up
make psql
```

## Run the check

```bash
make check LAB=10
```

The check creates two support agents, a ticket table, a row-level security policy
and a role with no grant. It verifies what each role can see and change, then
cleans up.

## Do it by hand

1. Create the roles:

   ```sql
   CREATE ROLE support_agent NOLOGIN;
   CREATE ROLE ada NOLOGIN;
   CREATE ROLE grace NOLOGIN;
   GRANT support_agent TO ada, grace;
   ```

2. Create a ticket table and seed it:

   ```sql
   CREATE TABLE support_tickets (
     ticket_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
     assigned_to text NOT NULL,
     subject text NOT NULL
   );
   INSERT INTO support_tickets (assigned_to, subject) VALUES
     ('ada', 'Ada one'), ('ada', 'Ada two'), ('grace', 'Grace one');
   ```

3. Enable RLS and add the policy:

   ```sql
   ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
   CREATE POLICY ticket_owner ON support_tickets
     FOR ALL
     USING (assigned_to = current_user)
     WITH CHECK (assigned_to = current_user);
   ```

4. Grant the table and sequence:

   ```sql
   GRANT USAGE ON SCHEMA public TO support_agent;
   GRANT SELECT, INSERT, UPDATE, DELETE ON support_tickets TO support_agent;
   GRANT USAGE, SELECT ON SEQUENCE support_tickets_ticket_id_seq TO support_agent;
   ```

5. Test as Ada:

   ```sql
   SET ROLE ada;
   SELECT count(*) FROM support_tickets;
   SELECT count(*) FROM support_tickets WHERE assigned_to = 'grace';
   INSERT INTO support_tickets (assigned_to, subject) VALUES ('grace', 'Not mine');
   RESET ROLE;
   ```

6. Remove `WITH CHECK` from the policy and test the insert again. What changes?

7. Change the application role to the table owner and test again. Does RLS apply?

## Inspect

```sql
SELECT schemaname, tablename, policyname, cmd, qual, with_check
FROM pg_policies
ORDER BY schemaname, tablename, policyname;

SELECT table_schema, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'support_agent'
ORDER BY table_name, privilege_type;
```

## Reset

```bash
make reset
```

The check drops its own roles and table. Reset if you created objects you want to
remove.
