-- SEQUENCE: {schema}.pj_empresas_id_seq
CREATE SEQUENCE IF NOT EXISTS {schema}.pj_empresas_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- Table: {schema}.pj_empresas
CREATE TABLE IF NOT EXISTS {schema}.pj_empresas
(
    id bigint NOT NULL DEFAULT nextval('{schema}.pj_empresas_id_seq'::regclass),
    cnpj VARCHAR(14) COLLATE pg_catalog."default",
    razao_social character varying COLLATE pg_catalog."default",
    nome_fantasia character varying COLLATE pg_catalog."default",
    situacao character varying COLLATE pg_catalog."default",
    situacao_descricao character varying COLLATE pg_catalog."default",
    situacao_data character varying COLLATE pg_catalog."default",
    situacao_motivo character varying COLLATE pg_catalog."default",
    situacao_motivo_descricao character varying COLLATE pg_catalog."default",
    tipo character varying COLLATE pg_catalog."default",
    tipo_descricao character varying COLLATE pg_catalog."default",
    abertura character varying COLLATE pg_catalog."default",
    cod_natureza character varying COLLATE pg_catalog."default",
    natureza_juridica_descricao character varying COLLATE pg_catalog."default",
    capital character varying COLLATE pg_catalog."default",
    porte character varying COLLATE pg_catalog."default",
    porte_descricao character varying COLLATE pg_catalog."default",
    origem character varying COLLATE pg_catalog."default",
    qualificacao_responsavel character varying COLLATE pg_catalog."default",
    optante_simples boolean,
    data_opcao_simples date,
    data_exclusao_simples date,
    data_opcao_mei date,
    data_exclusao_mei date,
    cnpj_basico VARCHAR(8) COLLATE pg_catalog."default",
    data_origem date,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.pj_empresas OWNER to postgres;

