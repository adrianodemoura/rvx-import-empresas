WITH inseridos AS (
    INSERT INTO $DB_SCHEMA.pj_cnaes_list( codigo, name )
    SELECT 
        codigo, 
        descricao 
        FROM $DB_SCHEMA_TMP.cnaes c
        WHERE c.id > $LAST_ID
        ORDER BY c.id 
        LIMIT $LIMIT
        RETURNING id
)
SELECT MAX(id) AS last_id FROM inseridos;