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

-- checando todas as tabelas
DO $$
BEGIN
    -- pj_empresas
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas') THEN
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
    END IF;

    -- pj_empresas_emails
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_emails') THEN
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
    END IF;

    -- pj_empresas_enderecos
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_enderecos') THEN
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
    END IF;

    -- pj_empresas_socios
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_socios') THEN
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
    END IF;

    -- pj_empresas_telefones
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_telefones') THEN
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
    END IF;

    -- pj_empresas_cnaes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_cnaes') THEN
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
                EXECUTE FUNCTION {schema}.set_updated_at();';
        END IF;
    END IF;

    -- pj_cnaes_list
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_cnaes_list') THEN
        IF NOT EXISTS (
            SELECT 1
            FROM pg_trigger t
            JOIN pg_class c ON c.oid = t.tgrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE t.tgname = 'trg_set_updated_at_pj_cnaes_list'
            AND c.relname = 'pj_cnaes_list'
            AND n.nspname = '{schema}'
        ) THEN
            EXECUTE '
                CREATE TRIGGER trg_set_updated_at_pj_cnaes_list
                BEFORE UPDATE ON {schema}.pj_cnaes_list
                FOR EACH ROW
                WHEN (old.* IS DISTINCT FROM new.*)
                EXECUTE FUNCTION {schema}.set_updated_at();
            ';
        END IF;
    END IF;

    -- pj_qualificacoes_socios
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_qualificacoes_socios') THEN
        IF NOT EXISTS (
            SELECT 1
            FROM pg_trigger t
            JOIN pg_class c ON c.oid = t.tgrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE t.tgname = 'trg_set_updated_at_pj_qualificacoes_socios'
            AND c.relname = 'pj_qualificacoes_socios'
            AND n.nspname = '{schema}'
        ) THEN
            EXECUTE '
                CREATE TRIGGER trg_set_updated_at_pj_qualificacoes_socios
                BEFORE UPDATE ON {schema}.pj_qualificacoes_socios
                FOR EACH ROW
                WHEN (old.* IS DISTINCT FROM new.*)
                EXECUTE FUNCTION {schema}.set_updated_at();
            ';
        END IF;
    END IF;

    -- pj_naturezas_juridicas
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_naturezas_juridicas') THEN
        IF NOT EXISTS (
            SELECT 1
            FROM pg_trigger t
            JOIN pg_class c ON c.oid = t.tgrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE t.tgname = 'trg_set_updated_at_pj_naturezas_juridicas'
            AND c.relname = 'pj_naturezas_juridicas'
            AND n.nspname = '{schema}'
        ) THEN
            EXECUTE '
                CREATE TRIGGER trg_set_updated_at_pj_naturezas_juridicas
                BEFORE UPDATE ON {schema}.pj_naturezas_juridicas
                FOR EACH ROW
                WHEN (old.* IS DISTINCT FROM new.*)
                EXECUTE FUNCTION {schema}.set_updated_at();
            ';
        END IF;
    END IF;
END;
$$;
