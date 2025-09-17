-- SEQUENCE: {schema}.{table}_id_seq
CREATE SEQUENCE IF NOT EXISTS {schema}.{table}_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- Table:{schema}.{table}
CREATE UNLOGGED TABLE IF NOT EXISTS {schema}.{table}
(
    id bigint NOT NULL DEFAULT nextval('{schema}.{table}_id_seq'::regclass),
    cnpj_basico VARCHAR(8) COLLATE pg_catalog."default",
    razao_social text COLLATE pg_catalog."default",
    natureza_juridica text COLLATE pg_catalog."default",
    qualificacao_responsavel text COLLATE pg_catalog."default",
    capital_social_str text COLLATE pg_catalog."default",
    porte_empresa VARCHAR(2) COLLATE pg_catalog."default",
    ente_federativo_responsavel text COLLATE pg_catalog."default",
    CONSTRAINT {table}_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.{table} OWNER to postgres;
ALTER SEQUENCE {schema}.{table}_id_seq OWNED BY {schema}.{table}.id;
ALTER SEQUENCE {schema}.{table}_id_seq OWNER TO postgres;