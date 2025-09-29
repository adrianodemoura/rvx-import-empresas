CREATE SEQUENCE IF NOT EXISTS {schema}.pj_empresas_emails_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

CREATE TABLE IF NOT EXISTS {schema}.pj_empresas_emails
(
    id bigint NOT NULL DEFAULT nextval('{schema}.pj_empresas_emails_id_seq'::regclass),
    cnpj character varying(22) COLLATE pg_catalog."default",
    email character varying(255) COLLATE pg_catalog."default",
    origem character varying(255) COLLATE pg_catalog."default",
    data_origem date,
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT pj_empresas_emails_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.pj_empresas_emails OWNER to postgres;
