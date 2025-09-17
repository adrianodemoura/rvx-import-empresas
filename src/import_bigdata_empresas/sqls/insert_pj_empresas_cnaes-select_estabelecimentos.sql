-- sem remover as duplicidades
WITH estabelecimentos_filtrados AS (
    SELECT 
        s.id,
        s.cnpj_basico||s.cnpj_ordem||s.cnpj_dv AS cnpj,
        s.cnae_fiscal,
        s.cnae_fiscal_secundaria
    FROM 
        $DB_SCHEMA_TMP.estabelecimentos s
    WHERE s.id > $LAST_ID ORDER BY s.id LIMIT $LIMIT
),
expand_cnaes AS (
     SELECT 
        ef.id,
        ef.cnpj,
        trim(cnae_valor) AS cnae,
        CASE WHEN bool_or(cnae_valor = ef.cnae_fiscal) THEN 'principal' ELSE 'secundário' END AS tipo
    FROM 
        estabelecimentos_filtrados ef,
        unnest(string_to_array(ef.cnae_fiscal_secundaria, ',') || ARRAY[ef.cnae_fiscal]) AS cnae_valor
    GROUP BY ef.id, ef.cnpj, trim(cnae_valor)
),
ins AS (
    INSERT INTO $DB_SCHEMA.pj_empresas_cnaes 
        (data_origem, origem, tipo, cnpj, cnae)
    SELECT 
        '$DATA_ORIGEM' AS data_origem,
        '$ORIGEM' AS origem,
        ec.tipo,
        ec.cnpj,
        ec.cnae
    FROM expand_cnaes ec
    RETURNING 1
)
SELECT MAX(id) AS last_id FROM estabelecimentos_filtrados;
