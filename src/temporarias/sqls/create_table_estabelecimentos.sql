-- SEQUENCE: {schema}.estabelecimentos_id_seq
CREATE SEQUENCE IF NOT EXISTS {schema}.estabelecimentos_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

-- Table:{schema}.estabelecimentos
CREATE UNLOGGED TABLE IF NOT EXISTS {schema}.estabelecimentos
(
    id bigint NOT NULL DEFAULT nextval('{schema}.estabelecimentos_id_seq'::regclass),
    cnpj_basico text COLLATE pg_catalog."default",
    cnpj_ordem text COLLATE pg_catalog."default",
    cnpj_dv text COLLATE pg_catalog."default",
    matriz_filial text COLLATE pg_catalog."default",
    nome_fantasia text COLLATE pg_catalog."default",
    situacao_cadastral text COLLATE pg_catalog."default",
    data_situacao_cadastral text COLLATE pg_catalog."default",
    motivo_situacao_cadastral text COLLATE pg_catalog."default",
    nome_cidade_exterior text COLLATE pg_catalog."default",
    pais text COLLATE pg_catalog."default",
    data_inicio_atividades text COLLATE pg_catalog."default",
    cnae_fiscal text COLLATE pg_catalog."default",
    cnae_fiscal_secundaria text COLLATE pg_catalog."default",
    tipo_logradouro text COLLATE pg_catalog."default",
    logradouro text COLLATE pg_catalog."default",
    numero text COLLATE pg_catalog."default",
    complemento text COLLATE pg_catalog."default",
    bairro text COLLATE pg_catalog."default",
    cep text COLLATE pg_catalog."default",
    uf text COLLATE pg_catalog."default",
    municipio text COLLATE pg_catalog."default",
    ddd1 text COLLATE pg_catalog."default",
    telefone1 text COLLATE pg_catalog."default",
    ddd2 text COLLATE pg_catalog."default",
    telefone2 text COLLATE pg_catalog."default",
    ddd_fax text COLLATE pg_catalog."default",
    fax text COLLATE pg_catalog."default",
    correio_eletronico text COLLATE pg_catalog."default",
    situacao_especial text COLLATE pg_catalog."default",
    data_situacao_especial text COLLATE pg_catalog."default",
    CONSTRAINT estabelecimento_pkey PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.estabelecimentos OWNER to postgres;
ALTER SEQUENCE {schema}.estabelecimentos_id_seq OWNED BY {schema}.estabelecimentos.id;
ALTER SEQUENCE {schema}.estabelecimentos_id_seq OWNER TO postgres;
