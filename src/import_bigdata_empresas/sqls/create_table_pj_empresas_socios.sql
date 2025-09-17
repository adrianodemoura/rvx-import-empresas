-- Sequence: {schema}.pj_empresas_socios_id_seq
CREATE SEQUENCE IF NOT EXISTS {schema}.pj_empresas_socios_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- Table: {schema}.pj_empresas_socios
CREATE TABLE IF NOT EXISTS {schema}.pj_empresas_socios
(
    id bigint NOT NULL DEFAULT nextval('{schema}.pj_empresas_socios_id_seq'::regclass),
    cpf character varying(14) COLLATE pg_catalog."default",
    cnpj character varying(21) COLLATE pg_catalog."default",
    identificador character varying(255) COLLATE pg_catalog."default",
    qualificacao character varying(255) COLLATE pg_catalog."default",
    data_entrada date,
    pais character varying(255) COLLATE pg_catalog."default",
    cpf_representante character varying(255) COLLATE pg_catalog."default",
    nome_representante character varying(255) COLLATE pg_catalog."default",
    qualificacao_representante character varying(255) COLLATE pg_catalog."default",
    faixa_etaria character varying(255) COLLATE pg_catalog."default",
    participacao character varying(255) COLLATE pg_catalog."default",
    origem character varying(255) COLLATE pg_catalog."default",
    data_origem date,
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT pj_empresas_socios_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.pj_empresas_socios OWNER to postgres;
