CREATE INDEX IF NOT EXISTS municipios_codigo_idx ON {schema}.municipios USING btree (codigo);
CREATE INDEX IF NOT EXISTS municipios_descricao_idx ON {schema}.municipios USING btree (descricao);

CREATE INDEX IF NOT EXISTS paises_codigo_idx ON {schema}.paises USING btree (codigo);
CREATE INDEX IF NOT EXISTS paises_descricao_idx ON {schema}.paises USING btree (descricao);

CREATE INDEX IF NOT EXISTS motivos_codigo_idx ON {schema}.motivos USING btree (codigo);
CREATE INDEX IF NOT EXISTS motivos_descricao_idx ON {schema}.motivos USING btree (descricao);

CREATE INDEX IF NOT EXISTS qualificacoes_codigo_idx ON {schema}.qualificacoes USING btree (codigo);
CREATE INDEX IF NOT EXISTS qualificacoes_descricao_idx ON {schema}.qualificacoes USING btree (descricao);

CREATE INDEX IF NOT EXISTS naturezas_codigo_idx ON {schema}.naturezas USING btree (codigo);
CREATE INDEX IF NOT EXISTS naturezas_descricao_idx ON {schema}.naturezas USING btree (descricao);

CREATE INDEX IF NOT EXISTS cnaes_codigo_idx ON {schema}.cnaes USING btree (codigo);
CREATE INDEX IF NOT EXISTS cnaes_descricao_idx ON {schema}.cnaes USING btree (descricao);

CREATE INDEX IF NOT EXISTS empresas_cnpj_basico_idx ON {schema}.empresas USING btree (cnpj_basico);

CREATE INDEX IF NOT EXISTS estabelecimentos_cnpj_basico_idx ON {schema}.estabelecimentos USING btree (cnpj_basico);
CREATE INDEX IF NOT EXISTS estabelecimentos_correio_eletronico_idx ON {schema}.estabelecimentos USING btree (correio_eletronico);

CREATE INDEX IF NOT EXISTS simples_cnpj_basico_idx ON {schema}.simples USING btree (cnpj_basico);

CREATE INDEX IF NOT EXISTS socios_cnpj_basico_idx ON {schema}.socios USING btree (cnpj_basico);
CREATE INDEX IF NOT EXISTS socios_cpf_idx ON {schema}.socios USING btree (cpf);
