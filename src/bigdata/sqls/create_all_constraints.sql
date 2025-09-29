DO $$
BEGIN
    -- pj_empresas
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pkey_pj_empresas' AND conrelid = '{schema}.pj_empresas'::regclass) THEN
            ALTER TABLE IF EXISTS {schema}.pj_empresas ADD CONSTRAINT pkey_pj_empresas PRIMARY KEY (id);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_pj_empresas_cnpj' AND conrelid = '{schema}.pj_empresas'::regclass) THEN
            ALTER TABLE {schema}.pj_empresas ADD CONSTRAINT unique_pj_empresas_cnpj UNIQUE (cnpj);
        END IF;
    END IF;

    -- pj_empresas_emails
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_emails') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_pj_empresas_emails_cnpj' AND conrelid = '{schema}.pj_empresas_emails'::regclass) THEN
            ALTER TABLE {schema}.pj_empresas_emails ADD CONSTRAINT unique_pj_empresas_emails_cnpj UNIQUE (cnpj);
        END IF;
    END IF;

    -- pj_empresas_enderecos
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_enderecos') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_pj_empresas_enderecos_cnpj' AND conrelid = '{schema}.pj_empresas_enderecos'::regclass) THEN
            ALTER TABLE {schema}.pj_empresas_enderecos ADD CONSTRAINT unique_pj_empresas_enderecos_cnpj UNIQUE (cnpj);
        END IF;
    END IF;

    -- pj_empresas_socios
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_socios') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pkey_pj_empresas_socios' AND conrelid = '{schema}.pj_empresas_socios'::regclass) THEN
            ALTER TABLE IF EXISTS {schema}.pj_empresas_socios ADD CONSTRAINT pkey_pj_empresas_socios PRIMARY KEY (id);
        END IF;
    END IF;

    -- pj_empresas_cnaes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_cnaes') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pkey_pj_empresas_cnaes' AND conrelid = '{schema}.pj_empresas_cnaes'::regclass) THEN
            ALTER TABLE IF EXISTS {schema}.pj_empresas_cnaes ADD CONSTRAINT pkey_pj_empresas_cnaes PRIMARY KEY (id);
        END IF;
    END IF;

    -- pj_cnaes_list
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_cnaes_list') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pkey_pj_cnaes_list' AND conrelid = '{schema}.pj_cnaes_list'::regclass) THEN
            ALTER TABLE IF EXISTS {schema}.pj_cnaes_list ADD CONSTRAINT pkey_pj_cnaes_list PRIMARY KEY (id);
        END IF;
    END IF;

    -- pf_pessoas
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pf_pessoas') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pkey_pf_pessoas' AND conrelid = '{schema}.pf_pessoas'::regclass) THEN
            ALTER TABLE IF EXISTS {schema}.pf_pessoas ADD CONSTRAINT pkey_pf_pessoas PRIMARY KEY (id);
        END IF;
    END IF;

    -- pf_telefones
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pf_telefones') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pkey_pf_telefones' AND conrelid = '{schema}.pf_telefones'::regclass) THEN
            ALTER TABLE IF EXISTS {schema}.pf_telefones ADD CONSTRAINT pkey_pf_telefones PRIMARY KEY (id);
        END IF;
    END IF;

    -- pf_emails
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pf_emails') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pkey_pf_emails' AND conrelid = '{schema}.pf_emails'::regclass) THEN
            ALTER TABLE IF EXISTS {schema}.pf_emails ADD CONSTRAINT pkey_pf_emails PRIMARY KEY (id);
        END IF;
    END IF;
END $$;