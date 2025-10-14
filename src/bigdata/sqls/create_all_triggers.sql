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
        EXECUTE '
            CREATE FUNCTION {schema}.set_updated_at() 
            RETURNS TRIGGER AS $body$ 
            DECLARE 
                arquivo text; 
                json_data json; 
            BEGIN 
                NEW.updated_at = now(); 
                arquivo := ''/var/lib/postgresql/data/export/'' || TG_TABLE_NAME || ''.'' || NEW.id || ''.json''; 
                json_data = row_to_json(NEW); 
                BEGIN 
                    EXECUTE format(''COPY (SELECT %L::json) TO %L'', json_data, arquivo); 
                EXCEPTION 
                    WHEN OTHERS THEN 
                        RAISE WARNING ''Erro ao criar arquivo JSON: %'', SQLERRM; 
                END; 
                RETURN NEW; 
            END; 
            $body$ LANGUAGE plpgsql;';
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
        'pf_pessoas', 'pf_telefones', 'pf_emails', 'pf_enderecos', 'pf_banco_gov', 'pf_bolsa_familia', 
        'pf_capacidade_pagamento', 'pf_carteira_trabalho', 'pf_cbo', 'pf_classe_social', 'pf_escolaridade', 
        'pf_fgts', 'pf_governos', 'pf_imoveis_ibge', 'pf_modelo_analitico_credito', 'pf_nacionalidade', 
        'pf_obitos', 'pf_persona_demografica', 'pf_pis', 'pf_poder_aquisitivo', 'pf_politicamente_exposta', 
        'pf_propensao_pagamento', 'pf_renda', 'pf_score', 'pf_score_digital', 'pf_situacao_receita', 
        'pf_titulo_eleitor', 'pf_triagem_risco', 'pf_veiculos', 'pf_vinculo_empregaticio', 'pf_vinculos_familiares'
    ];
    t text;
BEGIN
    FOREACH t IN ARRAY tbls
    LOOP
        PERFORM {schema}.create_updated_at_trigger('{schema}', t);
    END LOOP;
END;
$do$;
