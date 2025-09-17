-- trigger set_updated_at
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE p.proname = 'set_updated_at'
          AND n.nspname = '{schema}'
    ) THEN
        EXECUTE '
            CREATE FUNCTION {schema}.set_updated_at()
            RETURNS TRIGGER AS $func$
            BEGIN
                NEW.updated_at = now();
                RETURN NEW;
            END;
            $func$ LANGUAGE plpgsql;
        ';
    END IF;
END;
$$;

-- empresas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE t.tgname = 'trg_set_updated_at_pj_empresas'
          AND c.relname = 'pj_empresas'
          AND n.nspname = '{schema}'
    ) THEN
        EXECUTE '
            CREATE TRIGGER trg_set_updated_at_pj_empresas
            BEFORE UPDATE ON {schema}.pj_empresas
            FOR EACH ROW
            WHEN (OLD.* IS DISTINCT FROM NEW.*)
            EXECUTE FUNCTION {schema}.set_updated_at()
        ';
    END IF;
END;
$$;

-- pj_empresas_emails
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE t.tgname = 'trg_set_updated_at_pj_empresas_emails'
          AND c.relname = 'pj_empresas_emails'
          AND n.nspname = '{schema}'
    ) THEN
        EXECUTE '
            CREATE TRIGGER trg_set_updated_at_pj_empresas_emails
            BEFORE UPDATE ON {schema}.pj_empresas_emails
            FOR EACH ROW
            WHEN (OLD.* IS DISTINCT FROM NEW.*)
            EXECUTE FUNCTION {schema}.set_updated_at()
        ';
    END IF;
END;
$$;

-- empresas_enderecos
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE t.tgname = 'trg_set_updated_at_pj_enderecos'
          AND c.relname = 'pj_empresas_enderecos'
          AND n.nspname = '{schema}'
    ) THEN
        EXECUTE '
            CREATE TRIGGER trg_set_updated_at_pj_enderecos
            BEFORE UPDATE ON {schema}.pj_empresas_enderecos
            FOR EACH ROW
            WHEN (OLD.* IS DISTINCT FROM NEW.*)
            EXECUTE FUNCTION {schema}.set_updated_at()
        ';
    END IF;
END;
$$;

-- empresas_socios
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE t.tgname = 'trg_set_updated_at_pj_empresas_socios'
          AND c.relname = 'pj_empresas_socios'
          AND n.nspname = '{schema}'
    ) THEN
        EXECUTE '
            CREATE TRIGGER trg_set_updated_at_pj_empresas_socios
            BEFORE UPDATE ON {schema}.pj_empresas_socios
            FOR EACH ROW
            WHEN (OLD.* IS DISTINCT FROM NEW.*)
            EXECUTE FUNCTION {schema}.set_updated_at()
        ';
    END IF;
END;
$$;

-- empresas_telefones
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE t.tgname = 'trg_set_updated_at_pj_empresas_telefones'
          AND c.relname = 'pj_empresas_telefones'
          AND n.nspname = '{schema}'
    ) THEN
        EXECUTE '
            CREATE TRIGGER trg_set_updated_at_pj_empresas_telefones
            BEFORE UPDATE ON {schema}.pj_empresas_telefones
            FOR EACH ROW
            WHEN (OLD.* IS DISTINCT FROM NEW.*)
            EXECUTE FUNCTION {schema}.set_updated_at()
        ';
    END IF;
END;
$$;

-- pj_empresas_cnaes
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger t
        JOIN pg_class c ON c.oid = t.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE t.tgname = 'trg_set_updated_at_pj_empresas_cnaes'
          AND c.relname = 'pj_empresas_cnaes'
          AND n.nspname = '{schema}'
    ) THEN
        EXECUTE '
            CREATE TRIGGER trg_set_updated_at_pj_empresas_cnaes
            BEFORE UPDATE ON {schema}.pj_empresas_cnaes
            FOR EACH ROW
            WHEN (old.* IS DISTINCT FROM new.*)
            EXECUTE FUNCTION {schema}.set_updated_at();
        ';
    END IF;
END;
$$;

-- qualificacoes_socios
CREATE OR REPLACE TRIGGER trg_set_updated_at_pj_qualificacoes_socios
    BEFORE UPDATE 
    ON {schema}.pj_qualificacoes_socios
    FOR EACH ROW
    WHEN (old.* IS DISTINCT FROM new.*)
    EXECUTE FUNCTION {schema}.set_updated_at();

-- naturezas_juridicas
CREATE OR REPLACE TRIGGER trg_set_updated_at_pj_naturezas_juridicas
    BEFORE UPDATE 
    ON {schema}.pj_naturezas_juridicas
    FOR EACH ROW
    WHEN (old.* IS DISTINCT FROM new.*)
    EXECUTE FUNCTION {schema}.set_updated_at();

-- cnaes_list
CREATE OR REPLACE TRIGGER trg_set_updated_at_pj_cnaes_list
    BEFORE UPDATE 
    ON {schema}.pj_cnaes_list
    FOR EACH ROW
    WHEN (old.* IS DISTINCT FROM new.*)
    EXECUTE FUNCTION {schema}.set_updated_at();