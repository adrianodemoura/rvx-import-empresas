-- Sequence: {schema}.pf_pessoas_id_seq
CREATE SEQUENCE IF NOT EXISTS {schema}.pf_emails_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 10000000000000
    CACHE 1;

-- Table: {schema}.pf_emails
CREATE TABLE IF NOT EXISTS {schema}.pf_emails
(
    id bigint NOT NULL DEFAULT nextval('{schema}.pf_emails_id_seq'::regclass),
    cpf character varying(12) COLLATE pg_catalog."default",
    email character varying(255) COLLATE pg_catalog."default",
    origem character varying(50) COLLATE pg_catalog."default",
    data_origem date,

    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now()
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.pf_emails OWNER to postgres;
