DO $$
BEGIN
    -- pj_empresas
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas') THEN
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

    -- pj_empresas_cnaes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_cnaes') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pj_empresas_cnaes_pkey' AND conrelid = '{schema}.pj_empresas_cnaes'::regclass) THEN
            ALTER TABLE IF EXISTS {schema}.pj_empresas_cnaes ADD CONSTRAINT pj_empresas_cnaes_pkey PRIMARY KEY (id);
        END IF;
    END IF;

    -- pj_cnaes_list
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_cnaes_list') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'pj_cnaes_list_pkey' AND conrelid = '{schema}.pj_cnaes_list'::regclass) THEN
            ALTER TABLE IF EXISTS {schema}.pj_cnaes_list ADD CONSTRAINT pj_cnaes_list_pkey PRIMARY KEY (id);
        END IF;
    END IF;
END $$;