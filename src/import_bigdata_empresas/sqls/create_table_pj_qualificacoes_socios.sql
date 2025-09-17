CREATE SEQUENCE IF NOT EXISTS {schema}.pj_qualificacoes_socios_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- Table: {schema}.pj_qualificacoes_socios
CREATE TABLE IF NOT EXISTS {schema}.pj_qualificacoes_socios
(
    codigo character(2) COLLATE pg_catalog."default" NOT NULL,
    descricao text COLLATE pg_catalog."default",
    updated_at timestamp without time zone DEFAULT now(),
    created_at timestamp without time zone DEFAULT now(),
    id bigint NOT NULL DEFAULT nextval('{schema}.pj_qualificacoes_socios_id_seq'::regclass),
    CONSTRAINT qualificacoes_socios_codigo_key UNIQUE (codigo)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.pj_qualificacoes_socios OWNER to postgres;
