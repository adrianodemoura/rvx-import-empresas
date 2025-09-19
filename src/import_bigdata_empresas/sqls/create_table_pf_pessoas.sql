-- Sequence: {schema}.pf_pessoas_id_seq
CREATE SEQUENCE IF NOT EXISTS {schema}.pf_pessoas_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- Table: {schema}.pf_pessoas
CREATE TABLE IF NOT EXISTS {schema}.pf_pessoas
(
    id bigint NOT NULL DEFAULT nextval('{schema}.pf_pessoas_id_seq'::regclass),
    cpf character varying(14) COLLATE pg_catalog."default",
    nome character varying(255) COLLATE pg_catalog."default",
    cpf_basico character varying(6) COLLATE pg_catalog."default",
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now()
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.pf_pessoas OWNER to postgres;
