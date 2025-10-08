DO $$
BEGIN
    -- pj_naturezas_juridicas
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_naturezas_juridicas') THEN
        CREATE INDEX IF NOT EXISTS idx_pj_naturezas_juridicas_updated_at ON {schema}.pj_naturezas_juridicas USING btree (updated_at);
    END IF;

    -- pj_cnaes_list
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_cnaes_list') THEN
        CREATE INDEX IF NOT EXISTS idx_pj_cnaes_list_updated_at ON {schema}.pj_cnaes_list USING btree (updated_at);
        CREATE INDEX IF NOT EXISTS idx_pj_cnaes_list_codigo ON {schema}.pj_cnaes_list USING btree (codigo);
    END IF;

    -- pj_empresas
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas') THEN
        CREATE INDEX IF NOT EXISTS idx_pj_empresas_cnpj ON {schema}.pj_empresas USING btree (cnpj);
        CREATE INDEX IF NOT EXISTS idx_pj_empresas_updated_at ON {schema}.pj_empresas USING btree (updated_at);
    END IF;

    -- pj_empresas_emails
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_emails') THEN
        CREATE INDEX IF NOT EXISTS idx_pj_empresas_emails_cnpj ON {schema}.pj_empresas_emails USING btree (cnpj);
        CREATE INDEX IF NOT EXISTS idx_pj_empresas_emails_updated_at ON {schema}.pj_empresas_emails USING btree (updated_at);
    END IF;

    -- pj_qualificacoes_socios
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_qualificacoes_socios') THEN
        CREATE INDEX IF NOT EXISTS idx_pj_qualificacoes_socios_updated_at ON {schema}.pj_qualificacoes_socios USING btree (updated_at);
        CREATE INDEX IF NOT EXISTS idx_pj_qualificacoes_socios_codigo ON {schema}.pj_qualificacoes_socios USING btree (codigo);
    END IF;

    -- pj_empresas_enderecos
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_enderecos') THEN
        CREATE INDEX IF NOT EXISTS idx_pj_enderecos_cnpj ON {schema}.pj_empresas_enderecos USING btree (cnpj);
        CREATE INDEX IF NOT EXISTS idx_pj_enderecos_updated_at ON {schema}.pj_empresas_enderecos USING btree (updated_at);
    END IF;

    -- pj_empresas_socios
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_socios') THEN
        CREATE INDEX IF NOT EXISTS idx_pj_empresas_socios_cnpj ON {schema}.pj_empresas_socios USING btree (cnpj);
        CREATE INDEX IF NOT EXISTS idx_pj_empresas_socios_cpf ON {schema}.pj_empresas_socios USING btree (cpf);
        -- CREATE UNIQUE INDEX IF NOT EXISTS pj_empresas_socios_cpf_cnpj ON {schema}.pj_empresas_socios USING btree (cpf, cnpj);
    END IF;

    -- pj_empresas_telefones
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_telefones') THEN
        CREATE INDEX IF NOT EXISTS idx_pj_empresas_telefones_cnpj ON {schema}.pj_empresas_telefones USING btree (cnpj);
        CREATE INDEX IF NOT EXISTS idx_pj_empresas_telefones_updated_at ON {schema}.pj_empresas_telefones USING btree (updated_at);
    END IF;

    -- pj_empresas_cnaes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pj_empresas_cnaes') THEN
        CREATE INDEX IF NOT EXISTS idx_pj_empresas_cnaes_cnae ON {schema}.pj_empresas_cnaes USING btree (cnae);
        CREATE INDEX IF NOT EXISTS idx_pj_empresas_cnaes_cnpj ON {schema}.pj_empresas_cnaes USING btree (cnpj);
        CREATE INDEX IF NOT EXISTS idx_pj_empresas_cnaes_updated_at ON {schema}.pj_empresas_cnaes USING btree (updated_at);
    END IF;

    -- pf_pessoas
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pf_pessoas') THEN
        CREATE INDEX IF NOT EXISTS idx_pf_pessoas_cpf ON {schema}.pf_pessoas USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_pessoas_nome ON {schema}.pf_pessoas USING btree (nome);
        CREATE INDEX IF NOT EXISTS idx_pf_pessoas_cpf_basico ON {schema}.pf_pessoas USING btree (cpf_basico);
        CREATE INDEX IF NOT EXISTS idx_pf_pessoas_updated_at ON {schema}.pf_pessoas USING btree (updated_at);

        CREATE INDEX IF NOT EXISTS idx_pf_cbo_cpf ON {schema}.pf_cbo USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_governos_cpf ON {schema}.pf_governos USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_banco_gov_cpf ON {schema}.pf_banco_gov USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_enderecos_cpf ON {schema}.pf_enderecos USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_bolsa_familia_cpf ON {schema}.pf_bolsa_familia USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_classe_social_cpf ON {schema}.pf_classe_social USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_escolaridade_cpf ON {schema}.pf_escolaridade USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_carteira_trabalho_cpf ON {schema}.pf_carteira_trabalho USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_score_cpf ON {schema}.pf_score USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_capacidade_pagamento_cpf ON {schema}.pf_capacidade_pagamento USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_fgts_cpf ON {schema}.pf_fgts USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_imoveis_ibge_cpf ON {schema}.pf_imoveis_ibge USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_modelo_analitico_credito_cpf ON {schema}.pf_modelo_analitico_credito USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_nacionalidade_cpf ON {schema}.pf_nacionalidade USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_obitos_cpf ON {schema}.pf_obitos USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_persona_demografica_cpf ON {schema}.pf_persona_demografica USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_propensao_pagamento_cpf ON {schema}.pf_propensao_pagamento USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_renda_cpf ON {schema}.pf_renda USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_pis_cpf ON {schema}.pf_pis USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_poder_aquisitivo_cpf ON {schema}.pf_poder_aquisitivo USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_politicamente_exposta_cpf ON {schema}.pf_politicamente_exposta USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_score_digital_cpf ON {schema}.pf_score_digital USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_situacao_receita_cpf ON {schema}.pf_situacao_receita USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_titulo_eleitor_cpf ON {schema}.pf_titulo_eleitor USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_triagem_risco_cpf ON {schema}.pf_triagem_risco USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_veiculos_cpf ON {schema}.pf_veiculos USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_vinculo_empregaticio_cpf ON {schema}.pf_vinculo_empregaticio USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_vinculos_familiares_cpf ON {schema}.pf_vinculos_familiares USING btree (cpf);
    END IF;

    -- pf_telefones
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pf_telefones') THEN
        CREATE INDEX IF NOT EXISTS idx_pf_telefones_cpf ON {schema}.pf_telefones USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_telefones_status ON {schema}.pf_telefones USING btree (status);
    END IF;

    -- pf_emails
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='{schema}' AND table_name='pf_emails') THEN
        CREATE INDEX IF NOT EXISTS idx_pf_emails_cpf ON {schema}.pf_emails USING btree (cpf);
        CREATE INDEX IF NOT EXISTS idx_pf_emails_email ON {schema}.pf_emails USING btree (email);
    END IF;

END $$;
