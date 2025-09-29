WITH inseridos AS (
    INSERT INTO $DB_SCHEMA.pj_empresas_emails( 
        id,
        data_origem,
        origem,
        cnpj,
        email
    )
    SELECT 
        s.id,
        '$DATA_ORIGEM' as data_origem,
        '$ORIGEM' as origem,
        s.cnpj_basico||s.cnpj_ordem||s.cnpj_dv as cnpj,
        s.correio_eletronico
    FROM $DB_SCHEMA_TMP.estabelecimentos s
    WHERE s.id > $LAST_ID
        AND s.correio_eletronico IS NOT NULL
        AND s.correio_eletronico <> ''
    ORDER BY s.id 
    LIMIT $LIMIT
    RETURNING id
)
SELECT MAX(id) AS last_id FROM inseridos;
