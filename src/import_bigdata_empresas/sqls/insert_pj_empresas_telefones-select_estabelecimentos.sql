WITH estabelecimentos_filtrados AS (
    SELECT s.id,
           s.cnpj_basico||s.cnpj_ordem||s.cnpj_dv AS cnpj,
           NULLIF(s.ddd1||s.telefone1, '') AS tel1,
           NULLIF(s.ddd2||s.telefone2, '') AS tel2,
           NULLIF(s.ddd_fax||s.fax, '')    AS fax
    FROM $DB_SCHEMA_TMP.estabelecimentos s
    WHERE s.id > $LAST_ID
    ORDER BY s.id
    LIMIT $LIMIT
)

INSERT INTO $DB_SCHEMA.pj_empresas_telefones (
    data_origem
    , origem
    , cnpj
    , telefone )
    SELECT
        '$DATA_ORIGEM' AS data_origem,
        '$ORIGEM' as origem,
        e.cnpj,
        v.telefone
        FROM estabelecimentos_filtrados e
            JOIN LATERAL ( VALUES (e.tel1), (e.tel2), (e.fax) ) AS v(telefone)
            ON v.telefone IS NOT NULL
            RETURNING id;
