-- Sequence: {schema}.pj_enderecos_id_seq
CREATE SEQUENCE IF NOT EXISTS {schema}.pj_enderecos_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- Table: {schema}.pj_empresas_enderecos
CREATE TABLE IF NOT EXISTS {schema}.pj_empresas_enderecos
(
    id bigint NOT NULL DEFAULT nextval('{schema}.pj_enderecos_id_seq'::regclass),
    cnpj character varying(14) COLLATE pg_catalog."default" NOT NULL,
    tipo character varying(255) COLLATE pg_catalog."default",
    titulo character varying(255) COLLATE pg_catalog."default",
    logradouro character varying(255) COLLATE pg_catalog."default",
    numero character varying(40) COLLATE pg_catalog."default",
    complemento character varying(255) COLLATE pg_catalog."default",
    bairro character varying(255) COLLATE pg_catalog."default",
    cidade character varying(255) COLLATE pg_catalog."default",
    uf character varying(3) COLLATE pg_catalog."default",
    cep character varying(12) COLLATE pg_catalog."default",
    area_risco character varying(11) COLLATE pg_catalog."default",
    origem character varying(50) COLLATE pg_catalog."default",
    data_origem date,
    latitude character varying(255) COLLATE pg_catalog."default",
    longitude character varying(255) COLLATE pg_catalog."default",
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT pj_empresas_enderecos_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.pj_empresas_enderecos OWNER to postgres;
