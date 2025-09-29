-- SEQUENCE socios
CREATE SEQUENCE IF NOT EXISTS {schema}.socios_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- Table socios
CREATE TABLE IF NOT EXISTS {schema}.socios
(
    id bigint NOT NULL DEFAULT nextval('{schema}.socios_id_seq'::regclass),
    cnpj_basico text COLLATE pg_catalog."default",
    identificador_de_socio text COLLATE pg_catalog."default",
    nome_socio text COLLATE pg_catalog."default",
    cnpj_cpf_socio text COLLATE pg_catalog."default",
    cpf text COLLATE pg_catalog."default",
    qualificacao_socio text COLLATE pg_catalog."default",
    data_entrada_sociedade text COLLATE pg_catalog."default",
    pais text COLLATE pg_catalog."default",
    representante_legal text COLLATE pg_catalog."default",
    nome_representante text COLLATE pg_catalog."default",
    qualificacao_representante_legal text COLLATE pg_catalog."default",
    faixa_etaria text COLLATE pg_catalog."default",
    CONSTRAINT socios_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.socios OWNER to postgres;
ALTER SEQUENCE {schema}.socios_id_seq OWNED BY {schema}.socios.id;
ALTER SEQUENCE {schema}.socios_id_seq OWNER TO postgres;
