-- pj_empresas
CREATE INDEX IF NOT EXISTS idx_pj_empresas_id ON {schema}.pj_empresas USING btree (id);
CREATE INDEX IF NOT EXISTS idx_pj_empresas_cnpj ON {schema}.pj_empresas USING btree (cnpj);
CREATE INDEX IF NOT EXISTS idx_pj_empresas_updated_at ON {schema}.pj_empresas USING btree (updated_at);

-- pj_empresas_cnaes
CREATE INDEX IF NOT EXISTS idx_pj_empresas_cnaes_id ON {schema}.pj_empresas_cnaes USING btree (id);
CREATE INDEX IF NOT EXISTS idx_pj_empresas_cnaes_cnae ON {schema}.pj_empresas_cnaes USING btree (cnae);
CREATE INDEX IF NOT EXISTS idx_pj_empresas_cnaes_cnpj ON {schema}.pj_empresas_cnaes USING btree (cnpj);
CREATE INDEX IF NOT EXISTS idx_pj_empresas_cnaes_updated_at ON {schema}.pj_empresas_cnaes USING btree (updated_at);

-- empresas_emails
CREATE INDEX IF NOT EXISTS idx_pj_empresas_emails_id ON {schema}.pj_empresas_emails USING btree (id);
CREATE INDEX IF NOT EXISTS idx_pj_empresas_emails_cnpj ON {schema}.pj_empresas_emails USING btree (cnpj);
CREATE INDEX IF NOT EXISTS idx_pj_empresas_emails_updated_at ON {schema}.pj_empresas_emails USING btree (updated_at);

-- qualificacoes_socios
CREATE INDEX IF NOT EXISTS idx_pj_qualificacoes_socios_id ON {schema}.pj_qualificacoes_socios USING btree (id);
CREATE INDEX IF NOT EXISTS idx_pj_qualificacoes_socios_updated_at ON {schema}.pj_qualificacoes_socios USING btree (updated_at);
CREATE INDEX IF NOT EXISTS idx_pj_qualificacoes_socios_codigo ON {schema}.pj_qualificacoes_socios USING btree (codigo);

-- empresas_enderecos
CREATE INDEX IF NOT EXISTS idx_pj_enderecos_id ON {schema}.pj_empresas_enderecos USING btree (id);
CREATE INDEX IF NOT EXISTS idx_pj_enderecos_cnpj ON {schema}.pj_empresas_enderecos USING btree (cnpj);
CREATE INDEX IF NOT EXISTS idx_pj_enderecos_updated_at ON {schema}.pj_empresas_enderecos USING btree (updated_at);

-- empresas_socios
CREATE INDEX IF NOT EXISTS idx_pj_empresas_socios_id ON {schema}.pj_empresas_socios USING btree (id);
CREATE INDEX IF NOT EXISTS idx_pj_empresas_socios_cnpj ON {schema}.pj_empresas_socios USING btree (cnpj);
CREATE INDEX IF NOT EXISTS idx_pj_empresas_socios_cpf ON {schema}.pj_empresas_socios USING btree (cpf);
-- CREATE UNIQUE INDEX IF NOT EXISTS pj_empresas_socios_cpf_cnpj ON {schema}.pj_empresas_socios USING btree (cpf, cnpj);

-- empresas_telefones
CREATE INDEX IF NOT EXISTS idx_pj_empresas_telefones_id ON {schema}.pj_empresas_telefones USING btree (id);
CREATE INDEX IF NOT EXISTS idx_pj_empresas_telefones_cnpj ON {schema}.pj_empresas_telefones USING btree (cnpj);
CREATE INDEX IF NOT EXISTS idx_pj_empresas_telefones_updated_at ON {schema}.pj_empresas_telefones USING btree (updated_at);

-- naturezas_juridicas
CREATE INDEX IF NOT EXISTS idx_pj_naturezas_juridicas_id ON {schema}.pj_naturezas_juridicas USING btree (id);
CREATE INDEX IF NOT EXISTS idx_pj_naturezas_juridicas_updated_at ON {schema}.pj_naturezas_juridicas USING btree (updated_at);

-- pj_cnaes_list
CREATE INDEX IF NOT EXISTS idx_pj_cnaes_list_id ON {schema}.pj_cnaes_list USING btree (id);
CREATE INDEX IF NOT EXISTS idx_pj_cnaes_list_updated_at ON {schema}.pj_cnaes_list USING btree (updated_at);
CREATE INDEX IF NOT EXISTS idx_pj_cnaes_list_codigo ON {schema}.pj_cnaes_list USING btree (codigo);
