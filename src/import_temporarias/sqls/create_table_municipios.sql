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
    codigo VARCHAR(4) COLLATE pg_catalog."default",
    descricao VARCHAR(150) COLLATE pg_catalog."default",
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT {table}_pkey PRIMARY KEY (id)
)
TABLESPACE pg_default;

-- Alterações de ownership
ALTER TABLE IF EXISTS {schema}.{table} OWNER TO postgres;
ALTER SEQUENCE {schema}.{table}_id_seq OWNED BY {schema}.{table}.id;
ALTER SEQUENCE {schema}.{table}_id_seq OWNER TO postgres;
