-- SEQUENCE: {schema}.simples_id_seq
CREATE SEQUENCE IF NOT EXISTS {schema}.simples_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- Table:{schema}.simples
CREATE UNLOGGED TABLE IF NOT EXISTS {schema}.simples
(
    id bigint NOT NULL DEFAULT nextval('{schema}.simples_id_seq'::regclass),
    cnpj_basico text COLLATE pg_catalog."default",
    opcao_simples text COLLATE pg_catalog."default",
    data_opcao_simples text COLLATE pg_catalog."default",
    data_exclusao_simples text COLLATE pg_catalog."default",
    opcao_mei text COLLATE pg_catalog."default",
    data_opcao_mei text COLLATE pg_catalog."default",
    data_exclusao_mei text COLLATE pg_catalog."default",
    CONSTRAINT simples_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.simples OWNER to postgres;
ALTER SEQUENCE {schema}.simples_id_seq OWNED BY {schema}.simples.id;
ALTER SEQUENCE {schema}.simples_id_seq OWNER TO postgres;
