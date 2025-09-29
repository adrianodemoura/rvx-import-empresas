-- cria a função set_updated_at se não existir (usa {schema})
DO $do$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE p.proname = 'set_updated_at'
          AND n.nspname = '{schema}'
    ) THEN
        EXECUTE $fn$
            CREATE FUNCTION {schema}.set_updated_at()
            RETURNS TRIGGER AS $body$
            BEGIN
                NEW.updated_at = now();
                RETURN NEW;
            END;
            $body$ LANGUAGE plpgsql;
        $fn$;
    END IF;
END;
$do$;

-- cria a função auxiliar create_updated_at_trigger se não existir (no mesmo {schema})
DO $do$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE p.proname = 'create_updated_at_trigger'
          AND n.nspname = '{schema}'
    ) THEN
        EXECUTE $fn$
            CREATE FUNCTION {schema}.create_updated_at_trigger(p_schema text, p_table text)
            RETURNS void AS $body$
            DECLARE
                trigger_name text := format('trg_set_updated_at_%s', p_table);
                table_exists boolean;
                trigger_exists boolean;
            BEGIN
                SELECT EXISTS (
                    SELECT 1
                    FROM information_schema.tables
                    WHERE table_schema = p_schema
                      AND table_name = p_table
                ) INTO table_exists;

                IF NOT table_exists THEN
                    RAISE NOTICE 'Tabela %.% não existe, ignorando...', p_schema, p_table;
                    RETURN;
                END IF;

                SELECT EXISTS (
                    SELECT 1
                    FROM pg_trigger t
                    JOIN pg_class c ON c.oid = t.tgrelid
                    JOIN pg_namespace n ON n.oid = c.relnamespace
                    WHERE t.tgname = trigger_name
                      AND c.relname = p_table
                      AND n.nspname = p_schema
                ) INTO trigger_exists;

                IF NOT trigger_exists THEN
                    EXECUTE format(
                        'CREATE TRIGGER %I
                         BEFORE UPDATE ON %I.%I
                         FOR EACH ROW
                         WHEN (OLD.* IS DISTINCT FROM NEW.*)
                         EXECUTE FUNCTION %I.set_updated_at()',
                        trigger_name, p_schema, p_table, p_schema
                    );
                    RAISE NOTICE 'Trigger % criada em %.%', trigger_name, p_schema, p_table;
                ELSE
                    RAISE NOTICE 'Trigger % já existe em %.%', trigger_name, p_schema, p_table;
                END IF;
            END;
            $body$ LANGUAGE plpgsql;
        $fn$;
    END IF;
END;
$do$;

-- exemplo: cria triggers para várias tabelas (substitua {schema})
DO $do$
DECLARE
    tbls text[] := ARRAY[
        'pj_empresas', 'pj_empresas_emails', 'pj_empresas_enderecos',
        'pj_empresas_socios', 'pj_empresas_telefones', 'pj_empresas_cnaes',
        'pj_cnaes_list', 'pj_qualificacoes_socios', 'pj_naturezas_juridicas',
        'pf_pessoas', 'pf_emails', 'pf_telefones'
    ];
    t text;
BEGIN
    FOREACH t IN ARRAY tbls
    LOOP
        PERFORM {schema}.create_updated_at_trigger('{schema}', t);
    END LOOP;
END;
$do$;
