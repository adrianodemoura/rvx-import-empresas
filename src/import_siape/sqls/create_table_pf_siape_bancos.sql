-- Sequence: {schema}.pf_pessoas_id_seq
CREATE SEQUENCE IF NOT EXISTS {schema}.pf_siape_bancos_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 10000000000000
    CACHE 1;

-- Table: {schema}.pf_siape_bancos
CREATE TABLE IF NOT EXISTS {schema}.pf_siape_bancos
(
    id bigint NOT NULL DEFAULT nextval('{schema}.pf_siape_bancos_id_seq'::regclass),
    cpf character varying(11) COLLATE pg_catalog."default",
    bco_pgato character varying(50) COLLATE pg_catalog."default",
    ag character varying(50) COLLATE pg_catalog."default",
    banco character varying(50) COLLATE pg_catalog."default",

    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now()
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.pf_siape_bancos OWNER to postgres;
