-- pj_empresas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'unique_pj_empresas_cnpj'
          AND conrelid = '{schema}.pj_empresas'::regclass
    ) THEN
        ALTER TABLE {schema}.pj_empresas
        ADD CONSTRAINT unique_pj_empresas_cnpj UNIQUE (cnpj);
    END IF;
END $$;

-- pj_empresas_emails
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'unique_pj_empresas_emails_cnpj'
          AND conrelid = '{schema}.pj_empresas_emails'::regclass
    ) THEN
        ALTER TABLE {schema}.pj_empresas_emails
        ADD CONSTRAINT unique_pj_empresas_emails_cnpj UNIQUE (cnpj);
    END IF;
END $$;

-- pj_empresas_cnaes
-- DO $$
-- BEGIN
--     IF NOT EXISTS (
--         SELECT 1
--         FROM pg_constraint
--         WHERE conname = 'unique_pj_empresas_cnaes_cnpj_cnae'
--           AND conrelid = '{schema}.pj_empresas_emails'::regclass
--     ) THEN
--         ALTER TABLE IF EXISTS {schema}.pj_empresas_cnaes
--         ADD CONSTRAINT unique_pj_empresas_cnaes_cnpj_cnae UNIQUE (cnpj, cnae);
--     END IF;
-- END $$;
