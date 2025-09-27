-- Sequence: {schema}.pf_pessoas_id_seq
CREATE SEQUENCE IF NOT EXISTS {schema}.pf_telefones_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 10000000000000
    CACHE 1;

-- Table: {schema}.pf_telefones
CREATE TABLE IF NOT EXISTS {schema}.pf_telefones
(
    id bigint NOT NULL DEFAULT nextval('{schema}.pf_telefones_id_seq'::regclass),
    cpf character varying(12) COLLATE pg_catalog."default",
    telefone character varying(11) COLLATE pg_catalog."default",
    tipo character varying(20) COLLATE pg_catalog."default",
    localization smallint,
    status boolean,
    origem character varying(50) COLLATE pg_catalog."default",
    data_origem date,

    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now()
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.pf_telefones OWNER to postgres;
