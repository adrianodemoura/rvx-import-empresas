DO $$
BEGIN
    -- pf_siape_bancos
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pf_siape_bancos') THEN
        CREATE INDEX IF NOT EXISTS idx_pf_siape_bancos_updated_at ON {schema}.pf_siape_bancos USING btree (updated_at);
        CREATE INDEX IF NOT EXISTS idx_pf_siape_bancos_cpf ON {schema}.pf_siape_bancos USING btree (cpf);
    END IF;

    --
END $$;
