CREATE SEQUENCE IF NOT EXISTS {schema}.pj_naturezas_juridicas_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- Table: {schema}.pj_naturezas_juridicas
CREATE TABLE IF NOT EXISTS {schema}.pj_naturezas_juridicas
(
    id bigint NOT NULL DEFAULT nextval('{schema}.pj_naturezas_juridicas_id_seq'::regclass),
    codigo character(4) COLLATE pg_catalog."default" NOT NULL,
    descricao text COLLATE pg_catalog."default",
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now()
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.pj_naturezas_juridicas OWNER to postgres;
