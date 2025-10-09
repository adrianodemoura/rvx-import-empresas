CREATE SCHEMA bigdata_tmp;
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'bigdata_final'
  LOOP
    EXECUTE format('CREATE TABLE bigdata_tmp.%I (LIKE bigdata_final.%I INCLUDING ALL)', r.tablename, r.tablename);
  END LOOP;
END$$;

DO $$
DECLARE
  r RECORD;
  limite INTEGER := 10000;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'bigdata_final'
  LOOP
    EXECUTE format('INSERT INTO bigdata_tmp.%I SELECT * FROM bigdata_final.%I LIMIT %s', r.tablename, r.tablename, limite);
  END LOOP;
END$$;