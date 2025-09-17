CREATE SEQUENCE IF NOT EXISTS {schema}.pj_empresas_cnaes_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- Table: {schema}.pj_empresas_cnaes
CREATE TABLE IF NOT EXISTS {schema}.pj_empresas_cnaes
(
    id bigint NOT NULL DEFAULT nextval('{schema}.pj_empresas_cnaes_id_seq'::regclass),
    cnpj character varying(14) COLLATE pg_catalog."default",
    cnae character varying(255) COLLATE pg_catalog."default",
    tipo character varying(20) COLLATE pg_catalog."default",
    origem character varying(20) COLLATE pg_catalog."default",
    data_origem date,
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT pj_empresas_cnaes_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.pj_empresas_cnaes OWNER to postgres;
