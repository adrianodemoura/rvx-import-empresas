WITH inseridos AS (
    INSERT INTO $DB_SCHEMA.pj_naturezas_juridicas( codigo, descricao )
    SELECT 
        codigo, 
        descricao 
        FROM $DB_SCHEMA_TMP.naturezas n
        WHERE n.id > $LAST_ID
        ORDER BY n.id 
        LIMIT $LIMIT
        RETURNING id
)
SELECT MAX(id) AS last_id FROM inseridos;